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
  static const _mBundleDirty = 'bundleDirty';
  static const _mBundleRemote = 'bundleRemote';
  static const _kDeviceKey = 'qt.deviceKey';
  static const _kPinFails = 'qt.pinFails';
  static const _kPinUntil = 'qt.pinUntil';
  static const _acctKeyId = 'account';

  SecureKey? _master;
  SecureKey? _acctKey;
  final Map<String, SecureKey> _walletKeys = {};

  /// Ví chung (P9): khóa theo phiên bản + phiên bản hiện tại của từng ví.
  final Map<String, Map<int, SecureKey>> _sharedKeys = {};
  final Map<String, int> _sharedCurrent = {};
  late final RecordCipher cipher = RecordCipher(_kh.envelope);
  late final WalletSharing sharing = WalletSharing(_sodium);

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
    _open(_withRemoteFallback((b) => _kh.unlockWithPassword(b, password)));
    await _resetPinFails();
  }

  /// Sai từ ⇒ [RecoveryPhraseException] hoặc [EnvelopeException].
  Future<void> unlockWithRecovery(List<String> words) async {
    _open(_withRemoteFallback((b) => _kh.unlockWithRecovery(b, words)));
    await _resetPinFails();
  }

  /// Mở bằng gói khóa cục bộ; sai ⇒ thử gói khóa máy chủ đang chờ nhận (mật khẩu/24 từ đã đổi ở thiết bị khác).
  /// Gói máy chủ chỉ được nhận khi nó mở ra ĐÚNG khóa chủ cũ (cùng danh tính) - máy chủ không thể cài gói lạ.
  SecureKey _withRemoteFallback(SecureKey Function(AccountKeyBundle b) unlock) {
    try {
      return unlock(_bundle);
    } on Object {
      final raw = _store.getMeta(_mBundleRemote);
      if (raw == null) rethrow;
      final remote = AccountKeyBundle.fromJson((jsonDecode(utf8.decode(raw)) as Map).cast<String, Object?>());
      final SecureKey master;
      try {
        master = unlock(remote);
      } on Object {
        // Báo lỗi của lượt thử gói cục bộ (không lộ việc có gói chờ).
        rethrow;
      }
      if (!_sameIdentity(remote, _bundle) || !_opensIdentity(remote, master)) {
        master.dispose();
        _store.deleteMeta(_mBundleRemote);
        throw const EnvelopeException();
      }
      _store.transaction(() {
        _store.putMeta(_mBundle, raw);
        _store.deleteMeta(_mBundleRemote);
      });
      return master;
    }
  }

  void _open(SecureKey master) {
    lock();
    try {
      _acctKey = _kh.openWalletKey(master, _acctKeyId, _store.getMeta(_mAcctKey)!);
      _store.walletKeys().forEach((id, wrapped) => _walletKeys[id] = _kh.openWalletKey(master, id, wrapped));
      for (final w in _store.sharedWallets()) {
        _sharedCurrent[w.walletId] = w.localVer;
        _store.sharedKeys(w.walletId).forEach((ver, wrapped) {
          try {
            (_sharedKeys[w.walletId] ??= {})[ver] = sharing.openForSelf(master, wrapped, w.walletId, ver);
          } on EnvelopeException {
            // Bản bọc hỏng: phiên bản này không dùng được, lượt đồng bộ sau nhận lại từ máy chủ.
          }
        });
      }
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
    for (final m in _sharedKeys.values) {
      for (final k in m.values) {
        k.dispose();
      }
    }
    _master = null;
    _acctKey = null;
    _walletKeys.clear();
    _sharedKeys.clear();
    _sharedCurrent.clear();
  }

  /// Đổi mật khẩu mã hóa (cần đang mở khóa và biết mật khẩu cũ).
  void changePassword(String oldPassword, String newPassword) {
    final check = _kh.unlockWithPassword(_bundle, oldPassword);
    check.dispose();
    final updated = _kh.changePassword(_bundle, _requireMaster, newPassword);
    _putLocalBundle(updated);
  }

  /// Cấp 24 từ mới (bộ cũ hết hiệu lực). Trả về từ mới để hiển thị một lần.
  List<String> rotateRecovery() {
    final (updated, words) = _kh.rotateRecovery(_bundle, _requireMaster);
    _putLocalBundle(updated);
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

  bool hasWalletKey(String walletId) => _currentKey(walletId) != null;

  SecureKey? _currentKey(String walletId) {
    final ver = _sharedCurrent[walletId];
    if (ver != null) return keyForVersion(walletId, ver);
    return _walletKeys[walletId];
  }

  /// Khóa dùng để niêm phong bản ghi thuộc [walletId] (null = cấp tài khoản). Ví chung: phiên bản đang niêm phong
  /// bản ghi trên máy này (`local_ver`).
  SecureKey keyFor(String? walletId) {
    _requireMaster;
    if (walletId == null) return _acctKey!;
    return _currentKey(walletId) ?? (throw StateError('Không có khóa cho ví này'));
  }

  // ------------------------------------------------------------------ Ví chung (P9, ADR-0015)

  /// Khóa ví chung phiên bản [ver]. Phiên bản 1 của ví do mình tạo chính là khóa ví riêng trước khi chia sẻ.
  SecureKey? keyForVersion(String walletId, int ver) =>
      _sharedKeys[walletId]?[ver] ?? (ver == 1 ? _walletKeys[walletId] : null);

  /// Đặt phiên bản đang niêm phong bản ghi của ví trên máy này (sau khi mã hóa lại xong).
  void setLocalKeyVersion(String walletId, int ver) => _sharedCurrent[walletId] = ver;

  void forgetSharedWallet(String walletId) {
    final m = _sharedKeys.remove(walletId);
    for (final k in m?.values ?? const <SecureKey>[]) {
      k.dispose();
    }
    _sharedCurrent.remove(walletId);
  }

  /// Nhận khóa phiên bản [ver] (đã mở) và lưu bản bọc bằng khóa chủ. Vault giữ [key] (không dispose ở ngoài).
  void installSharedKey(String walletId, int ver, SecureKey key) {
    _store.putSharedKey(walletId, ver, sharing.wrapForSelf(_requireMaster, key, walletId, ver));
    final m = _sharedKeys[walletId] ??= {};
    m[ver]?.dispose();
    m[ver] = key;
  }

  /// Bản bọc phiên bản [ver] cho chính tài khoản mình (gửi máy chủ để các thiết bị khác của mình mở).
  /// [key]: khóa mới chưa cài (xoay khóa - chỉ cài sau khi máy chủ nhận).
  Uint8List wrapSharedForSelf(String walletId, int ver, {SecureKey? key}) => sharing.wrapForSelf(
    _requireMaster,
    key ?? keyForVersion(walletId, ver) ?? (throw StateError('Chưa có khóa phiên bản này')),
    walletId,
    ver,
  );

  /// Mở bản bọc khóa ví chung nhận từ máy chủ: phong bì của chính mình, hoặc khối X-Wing + một trong các bí mật cặp.
  /// Không mở được ⇒ null (bỏ qua, không cài khóa lạ).
  SecureKey? openSharedKey(String walletId, int ver, Uint8List wrapped, Iterable<Uint8List> pairSecrets) {
    final master = _requireMaster;
    if (!WalletSharing.isShareBlob(wrapped)) {
      try {
        return sharing.openForSelf(master, wrapped, walletId, ver);
      } on EnvelopeException {
        return null;
      }
    }
    final identity = _kh.openIdentity(_bundle, master);
    try {
      for (final secret in pairSecrets) {
        try {
          return sharing.openShare(wrapped, walletId: walletId, version: ver, identity: identity, pairSecret: secret);
        } on EnvelopeException {
          continue;
        }
      }
      return null;
    } finally {
      identity.dispose();
    }
  }

  /// Khối chia sẻ khóa phiên bản [ver] tới thành viên (khóa X-Wing [kemPublicKey], bí mật cặp [pairSecret]).
  Uint8List shareKeyTo(String walletId, int ver, Uint8List kemPublicKey, Uint8List pairSecret, {SecureKey? key}) =>
      sharing.shareKey(
        walletKey: key ?? keyForVersion(walletId, ver) ?? (throw StateError('Chưa có khóa phiên bản này')),
        walletId: walletId,
        version: ver,
        recipientKemPublicKey: kemPublicKey,
        pairSecret: pairSecret,
      );

  Uint8List get kemPublicKey => _bundle.kemPublicKey;

  /// Mã an toàn của tài khoản này (so với người cùng ví qua kênh ngoài).
  String get safetyCode => sharing.safetyCode(_bundle.kemPublicKey, _bundle.boxPublicKey);

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

  // ------------------------------------------------------------------ Đồng bộ (P6, ADR-0011)

  /// Gói khóa cục bộ dạng JSON (để đẩy lên máy chủ - mọi phần bí mật đã bọc).
  Map<String, Object?> get bundleJson => _bundle.toJson();

  /// Gói khóa đổi cục bộ (mật khẩu/24 từ) và chưa đẩy lên.
  bool get bundleDirty => _store.getMeta(_mBundleDirty) != null;
  void clearBundleDirty() => _store.deleteMeta(_mBundleDirty);

  void _putLocalBundle(AccountKeyBundle b) => _store.transaction(() {
    _store.putMeta(_mBundle, utf8.encode(jsonEncode(b.toJson())));
    _store.putMeta(_mBundleDirty, Uint8List.fromList([1]));
    _store.deleteMeta(_mBundleRemote);
  });

  /// Vân tay danh tính (SHA-256 của khóa công khai X-Wing ‖ X25519) - ghim chống tráo gói khóa (THREAT_MODEL T4).
  static String identityFingerprint(SodiumSumo sodium, AccountKeyBundle b) {
    final h = sodium.crypto.genericHash(
      message: Uint8List.fromList([...b.kemPublicKey, ...b.boxPublicKey]),
      outLen: 32,
    );
    return base64.encode(h);
  }

  String get localFingerprint => identityFingerprint(_sodium, _bundle);

  static bool _sameIdentity(AccountKeyBundle a, AccountKeyBundle b) =>
      _eq(a.kemPublicKey, b.kemPublicKey) && _eq(a.boxPublicKey, b.boxPublicKey);

  static bool _eq(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var d = 0;
    for (var i = 0; i < a.length; i++) {
      d |= a[i] ^ b[i];
    }
    return d == 0;
  }

  bool _opensIdentity(AccountKeyBundle b, SecureKey master) {
    try {
      _kh.openIdentity(b, master).dispose();
      return true;
    } on Object {
      return false;
    }
  }

  /// Mở một email chuyển tiếp đã được Email Worker niêm phong bằng `boxPk` của tài khoản (ADR-0006, ADR-0012).
  /// Khóa bí mật danh tính chỉ mở trong lượt gọi này rồi xóa khỏi bộ nhớ.
  Uint8List openSealedEmail(Uint8List sealed) {
    final identity = _kh.openIdentity(_bundle, _requireMaster);
    try {
      return _kh.openSealedEmail(sealed, identity);
    } finally {
      identity.dispose();
    }
  }

  /// So gói khóa máy chủ với tài khoản cục bộ đang mở: cùng danh tính VÀ phần bí mật mở được bằng khóa chủ này.
  /// false ⇒ hai khóa chủ khác nhau (tài khoản cục bộ khác) hoặc máy chủ tráo gói - KHÔNG được trộn dữ liệu.
  bool remoteBundleMatches(Map<String, Object?> json) {
    final AccountKeyBundle remote;
    try {
      remote = AccountKeyBundle.fromJson(json);
    } on FormatException {
      return false;
    }
    return _sameIdentity(remote, _bundle) && _opensIdentity(remote, _requireMaster);
  }

  /// Gói máy chủ cùng danh tính nhưng khác bản bọc (đổi mật khẩu ở máy khác): giữ để thử khi mở khóa lần sau.
  void offerRemoteBundle(Map<String, Object?> json) {
    final raw = utf8.encode(jsonEncode(json));
    if (utf8.decode(raw) == utf8.decode(_store.getMeta(_mBundle)!)) {
      _store.deleteMeta(_mBundleRemote);
    } else {
      _store.putMeta(_mBundleRemote, raw);
    }
  }

  /// Id khóa dữ liệu cấp tài khoản khi lưu trên máy chủ (bảng khóa ví đòi UUID). Phong bì vẫn dùng ngữ cảnh
  /// `wk|account` nên không thể nhầm với khóa ví thật.
  static const accountKeyServerId = '00000000-0000-4000-8000-000000000000';

  Uint8List get wrappedAccountKey => _store.getMeta(_mAcctKey)!;

  /// Nhận khóa ví từ máy chủ: chỉ nhận khóa mở được bằng khóa chủ (AEAD) và chưa có cục bộ. Trả số khóa mới.
  int importWalletKeys(Map<String, Uint8List> wrapped) {
    final master = _requireMaster;
    var added = 0;
    wrapped.forEach((id, w) {
      if (id == accountKeyServerId || _walletKeys.containsKey(id)) return;
      try {
        final key = _kh.openWalletKey(master, id, w);
        _store.putRemoteWalletKey(id, w);
        _walletKeys[id] = key;
        added++;
      } on Object {
        // Bản bọc hỏng/bị tráo: bỏ qua, bản ghi của ví đó sẽ không mở được (đếm vào "skipped").
      }
    });
    return added;
  }

  /// Thiết bị CHƯA có tài khoản: nhận tài khoản mã hóa đã có trên máy chủ, mở bằng mật khẩu hoặc 24 từ.
  /// Sai ⇒ [EnvelopeException]/[RecoveryPhraseException]; gói hỏng ⇒ [FormatException]. Thành công ⇒ đã mở khóa.
  void adoptRemoteAccount({
    required Map<String, Object?> bundleJson,
    required Uint8List wrappedAccountKey,
    required Map<String, Uint8List> walletKeys,
    String? password,
    List<String>? words,
  }) {
    if (hasAccount) throw StateError('Thiết bị đã có tài khoản');
    final bundle = AccountKeyBundle.fromJson(bundleJson);
    final master = password != null ? _kh.unlockWithPassword(bundle, password) : _kh.unlockWithRecovery(bundle, words!);
    try {
      if (!_opensIdentity(bundle, master)) throw const EnvelopeException();
      _kh.openWalletKey(master, _acctKeyId, wrappedAccountKey).dispose();
      _store.transaction(() {
        _store.putMeta(_mBundle, utf8.encode(jsonEncode(bundle.toJson())));
        _store.putMeta(_mAcctKey, wrappedAccountKey);
      });
    } on Object {
      master.dispose();
      rethrow;
    }
    _open(master);
    importWalletKeys(walletKeys);
  }

  // ------------------------------------------------------------------ Sao lưu tệp mã hóa

  static const backupFormat = 'qulythuchi-backup';
  static const backupVersion = 1;

  /// Tạo tệp sao lưu: gói khóa (đã bọc bởi mật khẩu/24 từ) + nội dung niêm phong bằng khóa chủ, ngữ cảnh
  /// `bak|<id>`. Nội dung gồm khóa tài khoản/khóa ví đã bọc và mọi bản ghi đã niêm phong - không có bản rõ nào.
  Uint8List createBackup(String backupId) {
    final payload = utf8.encode(
      jsonEncode({
        'acctKey': base64.encode(_store.getMeta(_mAcctKey)!),
        'walletKeys': {for (final e in _store.walletKeys().entries) e.key: base64.encode(e.value)},
        'records': [
          for (final r in _store.allRecords()) {'id': r.id, 't': r.type, 'w': r.walletId, 's': base64.encode(r.sealed)},
        ],
      }),
    );
    final sealed = _kh.envelope.seal(Uint8List.fromList(payload), _requireMaster, EnvelopeContext.backup(backupId));
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'format': backupFormat,
          'v': backupVersion,
          'id': backupId,
          'bundle': jsonDecode(utf8.decode(_store.getMeta(_mBundle)!)),
          'payload': base64.encode(sealed),
        }),
      ),
    );
  }

  /// Khôi phục vào thiết bị CHƯA có tài khoản. Sai mật khẩu/24 từ ⇒ [EnvelopeException]/[RecoveryPhraseException];
  /// tệp hỏng ⇒ [FormatException]. Thành công ⇒ kho khóa ở trạng thái đã mở. Trả về số bản ghi.
  Future<int> restoreBackup(Uint8List file, {String? password, List<String>? words}) async {
    if (hasAccount) throw StateError('Thiết bị đã có tài khoản');
    final Map<String, Object?> doc;
    final AccountKeyBundle bundle;
    final String id;
    final Uint8List sealed;
    try {
      doc = (jsonDecode(utf8.decode(file)) as Map).cast<String, Object?>();
      if (doc['format'] != backupFormat || doc['v'] != backupVersion) throw const FormatException('backup');
      id = doc['id']! as String;
      bundle = AccountKeyBundle.fromJson((doc['bundle']! as Map).cast<String, Object?>());
      sealed = base64.decode(doc['payload']! as String);
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('backup');
    }
    final master = password != null ? _kh.unlockWithPassword(bundle, password) : _kh.unlockWithRecovery(bundle, words!);
    final List<SealedRow> rows;
    final Uint8List acctKey;
    final Map<String, Uint8List> walletKeys;
    try {
      final payload = (jsonDecode(utf8.decode(_kh.envelope.open(sealed, master, EnvelopeContext.backup(id)))) as Map)
          .cast<String, Object?>();
      acctKey = base64.decode(payload['acctKey']! as String);
      walletKeys = {
        for (final e in (payload['walletKeys']! as Map).entries) e.key as String: base64.decode(e.value as String),
      };
      rows = [
        for (final r in (payload['records']! as List).cast<Map<Object?, Object?>>())
          SealedRow(
            id: r['id']! as String,
            type: r['t']! as String,
            walletId: r['w'] as String?,
            sealed: base64.decode(r['s']! as String),
          ),
      ];
    } on Object {
      master.dispose();
      throw const FormatException('backup');
    }
    // Một giao tác: lỗi giữa chừng không để lại thiết bị "có tài khoản" mà thiếu dữ liệu.
    try {
      _store.transaction(() {
        _store.putMeta(_mBundle, utf8.encode(jsonEncode(bundle.toJson())));
        _store.putMeta(_mAcctKey, acctKey);
        walletKeys.forEach(_store.putWalletKey);
        _store.putRecords(rows);
      });
    } on Object {
      master.dispose();
      rethrow;
    }
    _open(master);
    return rows.length;
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
