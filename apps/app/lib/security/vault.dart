// Tham số đặt tên công khai (sodium, store...) gán vào trường riêng: giữ API rõ ràng cho nơi gọi.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';

import '../data/key_storage.dart';
import '../data/record_store.dart';

/// Kết quả mở khóa bằng PIN.
sealed class PinResult {
  const PinResult();
}

final class PinOk extends PinResult {
  const PinOk();
}

/// Sai PIN. [remaining] = số lần còn được thử trước khi PIN bị vô hiệu.
final class PinWrong extends PinResult {
  const PinWrong(this.remaining, this.waitUntil);
  final int remaining;
  final DateTime? waitUntil;
}

/// Đang bị khóa tạm vì sai nhiều lần.
final class PinLockedOut extends PinResult {
  const PinLockedOut(this.until);
  final DateTime until;
}

/// PIN đã bị vô hiệu (sai quá nhiều) - phải dùng mật khẩu mã hóa.
final class PinDisabled extends PinResult {
  const PinDisabled();
}

/// Chính sách thử PIN: 5 lần đầu tự do, sau đó chờ 30 giây nhân đôi mỗi lần (tối đa 1 giờ);
/// sai tới lần thứ [maxFails] thì xóa bản bọc PIN/sinh trắc ⇒ chỉ còn mật khẩu.
abstract final class PinPolicy {
  static const freeTries = 5;
  static const maxFails = 10;
  static const minLength = 6;
  static const maxLength = 12;

  static Duration delayAfter(int fails) {
    if (fails < freeTries) return Duration.zero;
    final seconds = 30 * (1 << (fails - freeTries).clamp(0, 7));
    return Duration(seconds: seconds > 3600 ? 3600 : seconds);
  }

  static bool isValidPin(String pin) =>
      pin.length >= minLength && pin.length <= maxLength && RegExp(r'^\d+$').hasMatch(pin);
}

/// Tham số Argon2id cho tài khoản mới (cho phép test hạ xuống).
final class VaultConfig {
  const VaultConfig({this.kdfOps, this.kdfMem, this.pinOps = KdfParams.minOps, this.pinMem = KdfParams.minMem});
  final int? kdfOps;
  final int? kdfMem;
  final int pinOps;
  final int pinMem;
}

/// Giữ khóa đang mở trong bộ nhớ và thực hiện các thao tác khóa (ADR-0002, ADR-0007, ADR-0008).
///
/// Bố cục khóa trên thiết bị:
/// - `meta.bundle`: gói khóa tài khoản (khóa chủ bọc bằng mật khẩu Argon2id và bằng 24 từ).
/// - `meta.acctKey`: khóa dữ liệu cấp tài khoản (danh mục...) bọc bằng khóa chủ.
/// - `wallet_keys`: khóa từng ví bọc bằng khóa chủ.
/// - `meta.pinWrap`: khóa chủ bọc bằng BLAKE2b(khóa thiết bị, Argon2id(PIN)) - cần CẢ kho bí mật của máy lẫn PIN.
/// - `meta.bioWrap`: khóa chủ bọc bằng khóa thiết bị; chỉ mở sau khi `local_auth` xác thực thành công.
final class Vault {
  Vault({
    required SodiumSumo sodium,
    required RecordStore store,
    required KeyStorage keyStorage,
    this.config = const VaultConfig(),
    @visibleForTesting bool allowWeakKdf = false,
  }) : _sodium = sodium,
       _store = store,
       _keys = keyStorage,
       // ignore: invalid_use_of_visible_for_testing_member
       _kh = KeyHierarchy(sodium, allowWeakKdf: allowWeakKdf),
       _allowWeakKdf = allowWeakKdf;

  final SodiumSumo _sodium;
  final RecordStore _store;
  final KeyStorage _keys;
  final KeyHierarchy _kh;
  final bool _allowWeakKdf;
  final VaultConfig config;

  static const _mBundle = 'bundle';
  static const _mAcctKey = 'acctKey';
  static const _mNode = 'node';
  static const _mPinWrap = 'pinWrap';
  static const _mPinKdf = 'pinKdf';
  static const _mBioWrap = 'bioWrap';
  static const _kDeviceKey = 'qt.deviceKey';
  static const _kPinFails = 'qt.pinFails';
  static const _kPinUntil = 'qt.pinUntil';
  static const _acctKeyId = 'account';

  SecureKey? _master;
  SecureKey? _acctKey;
  final Map<String, SecureKey> _walletKeys = {};
  late final RecordCipher cipher = RecordCipher(_kh.envelope);

  bool get hasAccount => _store.getMeta(_mBundle) != null;
  bool get isUnlocked => _master != null;
  bool get quickUnlockSupported => _keys.supported;
  bool get pinEnabled => _keys.supported && _store.getMeta(_mPinWrap) != null;
  bool get biometricEnabled => _keys.supported && _store.getMeta(_mBioWrap) != null;

  /// Id nút HLC của thiết bị này (ngẫu nhiên, không chứa thông tin máy).
  String get nodeId {
    final raw = _store.getMeta(_mNode);
    if (raw != null) return utf8.decode(raw);
    final bytes = _sodium.randombytes.buf(8);
    final node = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _store.putMeta(_mNode, utf8.encode(node));
    return node;
  }

  AccountKeyBundle get _bundle =>
      AccountKeyBundle.fromJson((jsonDecode(utf8.decode(_store.getMeta(_mBundle)!)) as Map).cast<String, Object?>());

  SecureKey get _requireMaster => _master ?? (throw StateError('Kho khóa đang khóa'));

  // ------------------------------------------------------------------ Tạo / mở

  /// Tạo tài khoản cục bộ. Trả về 24 từ khôi phục - người gọi hiển thị một lần rồi bỏ.
  List<String> createAccount(String password) {
    if (hasAccount) throw StateError('Đã có tài khoản trên thiết bị này');
    final setup = _kh.createAccount(
      password,
      kdf: _kh.newKdfParams(opsLimit: config.kdfOps, memLimit: config.kdfMem),
    );
    final (acctKey, acctWrapped) = _kh.createWalletKey(setup.masterKey, _acctKeyId);
    _store.transaction(() {
      _store.putMeta(_mBundle, utf8.encode(jsonEncode(setup.bundle.toJson())));
      _store.putMeta(_mAcctKey, acctWrapped);
    });
    _master = setup.masterKey;
    _acctKey = acctKey;
    return setup.recoveryWords;
  }

  /// Sai mật khẩu ⇒ [EnvelopeException].
  Future<void> unlockWithPassword(String password) async {
    _open(_kh.unlockWithPassword(_bundle, password));
    await _resetPinFails();
  }

  /// Sai từ ⇒ [RecoveryPhraseException] hoặc [EnvelopeException].
  Future<void> unlockWithRecovery(List<String> words) async {
    _open(_kh.unlockWithRecovery(_bundle, words));
    await _resetPinFails();
  }

  void _open(SecureKey master) {
    lock();
    try {
      _acctKey = _kh.openWalletKey(master, _acctKeyId, _store.getMeta(_mAcctKey)!);
      _store.walletKeys().forEach((id, wrapped) => _walletKeys[id] = _kh.openWalletKey(master, id, wrapped));
    } on Object {
      master.dispose();
      lock();
      rethrow;
    }
    _master = master;
  }

  /// Xóa mọi khóa khỏi bộ nhớ.
  void lock() {
    _master?.dispose();
    _acctKey?.dispose();
    for (final k in _walletKeys.values) {
      k.dispose();
    }
    _master = null;
    _acctKey = null;
    _walletKeys.clear();
  }

  /// Đổi mật khẩu mã hóa (cần đang mở khóa và biết mật khẩu cũ).
  void changePassword(String oldPassword, String newPassword) {
    final check = _kh.unlockWithPassword(_bundle, oldPassword);
    check.dispose();
    final updated = _kh.changePassword(_bundle, _requireMaster, newPassword);
    _store.putMeta(_mBundle, utf8.encode(jsonEncode(updated.toJson())));
  }

  /// Cấp 24 từ mới (bộ cũ hết hiệu lực). Trả về từ mới để hiển thị một lần.
  List<String> rotateRecovery() {
    final (updated, words) = _kh.rotateRecovery(_bundle, _requireMaster);
    _store.putMeta(_mBundle, utf8.encode(jsonEncode(updated.toJson())));
    return words;
  }

  // ------------------------------------------------------------------ Khóa ví / bản ghi

  /// Tạo khóa cho ví mới và lưu bản bọc.
  void createWalletKey(String walletId) {
    final (key, wrapped) = _kh.createWalletKey(_requireMaster, walletId);
    _store.putWalletKey(walletId, wrapped);
    _walletKeys[walletId]?.dispose();
    _walletKeys[walletId] = key;
  }

  bool hasWalletKey(String walletId) => _walletKeys.containsKey(walletId);

  /// Khóa dùng để niêm phong bản ghi thuộc [walletId] (null = cấp tài khoản).
  SecureKey keyFor(String? walletId) {
    _requireMaster;
    if (walletId == null) return _acctKey!;
    return _walletKeys[walletId] ?? (throw StateError('Không có khóa cho ví này'));
  }

  // ------------------------------------------------------------------ Mở nhanh: PIN, sinh trắc

  Future<SecureKey> _deviceKey({bool create = false}) async {
    final existing = await _keys.read(_kDeviceKey);
    if (existing != null) return _sodium.secureCopy(base64.decode(existing));
    if (!create) throw StateError('Không có khóa thiết bị');
    final key = _sodium.randombytes.buf(KeyHierarchy.keyBytes);
    await _keys.write(_kDeviceKey, base64.encode(key));
    final secure = _sodium.secureCopy(key);
    key.fillRange(0, key.length, 0);
    return secure;
  }

  SecureKey _pinKek(String pin, KdfParams params, SecureKey deviceKey) {
    if (!_allowWeakKdf && (params.opsLimit < KdfParams.minOps || params.memLimit < KdfParams.minMem)) {
      throw const FormatException('Tham số KDF của PIN yếu hơn mức sàn');
    }
    final stretched = _sodium.crypto.pwhash.callRaw(
      outLen: KeyHierarchy.keyBytes,
      password: Int8List.fromList(utf8.encode(pin)),
      salt: params.salt,
      opsLimit: params.opsLimit,
      memLimit: params.memLimit,
      alg: CryptoPwhashAlgorithm.argon2id13,
    );
    final stretchedBytes = stretched.extractBytes();
    stretched.dispose();
    try {
      final kek = _sodium.crypto.genericHash(message: stretchedBytes, outLen: KeyHierarchy.keyBytes, key: deviceKey);
      final secure = _sodium.secureCopy(kek);
      kek.fillRange(0, kek.length, 0);
      return secure;
    } finally {
      stretchedBytes.fillRange(0, stretchedBytes.length, 0);
    }
  }

  Uint8List _sealMaster(SecureKey kek, String kind) {
    final bytes = _requireMaster.extractBytes();
    try {
      return _kh.envelope.seal(bytes, kek, EnvelopeContext.masterKey(kind));
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  SecureKey _openMaster(SecureKey kek, Uint8List wrapped, String kind) {
    final bytes = _kh.envelope.open(wrapped, kek, EnvelopeContext.masterKey(kind));
    try {
      return _sodium.secureCopy(bytes);
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  /// Đặt/đổi PIN (cần đang mở khóa).
  Future<void> setPin(String pin) async {
    if (!_keys.supported) throw UnsupportedError('Thiết bị không có kho bí mật');
    if (!PinPolicy.isValidPin(pin)) throw const FormatException('PIN phải gồm 6-12 chữ số');
    final params = _kh.newKdfParams(opsLimit: config.pinOps, memLimit: config.pinMem);
    final device = await _deviceKey(create: true);
    final kek = _pinKek(pin, params, device);
    device.dispose();
    try {
      _store.transaction(() {
        _store.putMeta(_mPinWrap, _sealMaster(kek, 'pin'));
        _store.putMeta(_mPinKdf, utf8.encode(jsonEncode(params.toJson())));
      });
    } finally {
      kek.dispose();
    }
    await _resetPinFails();
  }

  Future<void> disablePin() async {
    _store.deleteMeta(_mPinWrap);
    _store.deleteMeta(_mPinKdf);
    // Sinh trắc là lối tắt của PIN: tắt PIN thì tắt luôn.
    _store.deleteMeta(_mBioWrap);
  }

  /// Thời điểm được thử PIN tiếp (null = thử ngay được).
  Future<DateTime?> pinLockedUntil() async {
    final raw = await _keys.read(_kPinUntil);
    final until = raw == null ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
    return until != null && until.isAfter(DateTime.now()) ? until : null;
  }

  Future<PinResult> unlockWithPin(String pin) async {
    if (!pinEnabled) return const PinDisabled();
    final until = await pinLockedUntil();
    if (until != null) return PinLockedOut(until);
    // Tăng bộ đếm TRƯỚC khi thử: tắt app giữa chừng không né được lần đếm.
    final fails = int.tryParse(await _keys.read(_kPinFails) ?? '') ?? 0;
    await _keys.write(_kPinFails, '${fails + 1}');
    final params = KdfParams.fromJson((jsonDecode(utf8.decode(_store.getMeta(_mPinKdf)!)) as Map).cast());
    final device = await _deviceKey();
    final kek = _pinKek(pin, params, device);
    device.dispose();
    try {
      _open(_openMaster(kek, _store.getMeta(_mPinWrap)!, 'pin'));
    } on EnvelopeException {
      final now = fails + 1;
      if (now >= PinPolicy.maxFails) {
        await disablePin();
        await _resetPinFails();
        return const PinDisabled();
      }
      final delay = PinPolicy.delayAfter(now);
      DateTime? wait;
      if (delay > Duration.zero) {
        wait = DateTime.now().add(delay);
        await _keys.write(_kPinUntil, '${wait.millisecondsSinceEpoch}');
      }
      return PinWrong(PinPolicy.maxFails - now, wait);
    } finally {
      kek.dispose();
    }
    await _resetPinFails();
    return const PinOk();
  }

  Future<void> _resetPinFails() async {
    if (!_keys.supported) return;
    await _keys.delete(_kPinFails);
    await _keys.delete(_kPinUntil);
  }

  /// Bật mở khóa sinh trắc (cần đã có PIN). Gọi sau khi `local_auth` xác thực thành công.
  Future<void> enableBiometric() async {
    if (!pinEnabled) throw StateError('Cần đặt PIN trước');
    final device = await _deviceKey(create: true);
    try {
      _store.putMeta(_mBioWrap, _sealMaster(device, 'device'));
    } finally {
      device.dispose();
    }
  }

  void disableBiometric() => _store.deleteMeta(_mBioWrap);

  /// Chỉ gọi SAU khi `local_auth` trả về thành công.
  Future<void> unlockWithBiometric() async {
    final wrapped = _store.getMeta(_mBioWrap);
    if (wrapped == null) throw StateError('Chưa bật sinh trắc');
    final device = await _deviceKey();
    try {
      _open(_openMaster(device, wrapped, 'device'));
    } finally {
      device.dispose();
    }
    await _resetPinFails();
  }

  /// Xóa sạch dữ liệu và khóa thiết bị (đặt lại app).
  Future<void> wipe() async {
    lock();
    _store.wipe();
    if (_keys.supported) {
      await _keys.delete(_kDeviceKey);
      await _resetPinFails();
    }
  }
}
