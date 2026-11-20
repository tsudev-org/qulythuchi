import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:test/test.dart';

const txn1 = '0f8fad5b-d9cb-469f-a165-70867728950e';
const txn2 = '9b2c6f4e-1d3a-4c5b-8e7f-0a1b2c3d4e5f';
const att1 = '3f1e2d4c-5b6a-4789-8a0b-1c2d3e4f5a6b';
const w1 = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const w2 = '16fd2706-8baf-433b-82eb-8c7fada847da';

bool _hasApp1(Uint8List jpeg) {
  for (var i = 0; i + 1 < jpeg.length; i++) {
    if (jpeg[i] == 0xFF && jpeg[i + 1] == 0xE1) return true;
    if (jpeg[i] == 0xFF && jpeg[i + 1] == 0xDA) return false; // tới dữ liệu ảnh
  }
  return false;
}

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
    }
  }
  return c ^ 0xFFFFFFFF;
}

Uint8List _photo({int w = 300, int h = 200, int orientation = 1}) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(200, 120, 40));
  im.exif.imageIfd['Make'] = 'MayAnhThu';
  im.exif.imageIfd['Orientation'] = orientation;
  im.exif.gpsIfd['GPSLatitudeRef'] = 'N';
  im.exif.gpsIfd['GPSLatitude'] = [21, 1, 42];
  return img.encodeJpg(im);
}

void main() {
  late SodiumSumo sodium;
  late AttachmentCipher cipher;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    cipher = AttachmentCipher(sodium);
  });

  Attachment att(Uint8List key, int size, {String? wallet = w1, String txn = txn1, String id = att1}) => Attachment(
    id: id,
    walletId: wallet,
    txnId: txn,
    fileKey: key,
    mime: 'image/jpeg',
    size: size,
    width: 10,
    height: 10,
  );

  group('ImageSanitizer', () {
    test('ảnh có GPS/EXIF ⇒ đầu ra JPEG mới không còn EXIF, đã xoay theo Orientation', () {
      final input = _photo(orientation: 6);
      expect(_hasApp1(input), isTrue, reason: 'ảnh mẫu phải có EXIF');
      final out = ImageSanitizer.sanitize(input);
      expect(_hasApp1(out.bytes), isFalse);
      expect(latin1.decode(out.bytes).contains('MayAnhThu'), isFalse);
      expect(out.mime, 'image/jpeg');
      expect((out.width, out.height), (200, 300));
      final back = img.decodeJpg(out.bytes)!;
      expect(back.hasExif && !back.exif.isEmpty, isFalse);
    });

    test('thu cạnh dài về 2000 px, PNG cũng thành JPEG', () {
      final png = img.encodePng(img.Image(width: 3000, height: 1000));
      final out = ImageSanitizer.sanitize(png);
      expect((out.width, out.height), (2000, 667));
      expect(out.bytes.sublist(0, 2), [0xFF, 0xD8]);
      expect(out.bytes.length, lessThanOrEqualTo(ImageSanitizer.maxOutputBytes));
    });

    test('từ chối: không phải ảnh, quá lớn, quá nhiều điểm ảnh (đọc kích thước trước khi giải mã)', () {
      expect(
        () => ImageSanitizer.sanitize(Uint8List.fromList(utf8.encode('%PDF-1.7 không phải ảnh'))),
        throwsA(isA<ImageRejectedException>().having((e) => e.reason, 'reason', ImageRejectReason.unsupported)),
      );
      expect(
        () => ImageSanitizer.sanitize(Uint8List(ImageSanitizer.maxInputBytes + 1)),
        throwsA(isA<ImageRejectedException>().having((e) => e.reason, 'reason', ImageRejectReason.tooLarge)),
      );
      // Đầu PNG khai 8000 x 8000 (64 triệu điểm ảnh) nhưng gần như không có dữ liệu.
      final bomb = img.encodePng(img.Image(width: 1, height: 1));
      final bd = ByteData.sublistView(bomb);
      bd.setUint32(16, 8000);
      bd.setUint32(20, 8000);
      bd.setUint32(29, _crc32(bomb.sublist(12, 29))); // CRC của khối IHDR
      expect(
        () => ImageSanitizer.sanitize(bomb),
        throwsA(isA<ImageRejectedException>().having((e) => e.reason, 'reason', ImageRejectReason.tooManyPixels)),
      );
    });
  });

  group('AttachmentCipher', () {
    test('mở đúng; đệm 64 KiB giấu cỡ; khóa mỗi tệp khác nhau', () {
      final key = cipher.newFileKey();
      expect(key.length, 32);
      expect(cipher.newFileKey(), isNot(equals(key)));
      final plain = Uint8List.fromList(List.generate(70000, (i) => i % 251));
      final a = att(key, plain.length);
      final sealed = cipher.seal(plain, a);
      expect(sealed.sublist(0, 4), [0x51, 0x54, 1, 1]);
      expect(sealed.length, Envelope.overhead + 2 * EnvelopeContext.attachmentPadBlock);
      expect(cipher.open(sealed, a), plain);
      final small = cipher.seal(Uint8List(10), att(key, 10));
      expect(small.length, Envelope.overhead + EnvelopeContext.attachmentPadBlock);
    });

    test('máy chủ tráo tệp sang giao dịch/ví/id khác hoặc sửa byte ⇒ không mở được', () {
      final key = cipher.newFileKey();
      final plain = Uint8List.fromList(utf8.encode('hoa don'));
      final sealed = cipher.seal(plain, att(key, plain.length));
      final ex = throwsA(isA<EnvelopeException>());
      expect(() => cipher.open(sealed, att(key, plain.length, txn: txn2)), ex);
      expect(() => cipher.open(sealed, att(key, plain.length, wallet: w2)), ex);
      expect(() => cipher.open(sealed, att(key, plain.length, wallet: null)), ex);
      expect(() => cipher.open(sealed, att(key, plain.length, id: txn2)), ex);
      expect(() => cipher.open(sealed, att(cipher.newFileKey(), plain.length)), ex);
      expect(() => cipher.open(sealed, att(key, plain.length + 1)), ex);
      final bad = Uint8List.fromList(sealed)..[40] ^= 1;
      expect(() => cipher.open(bad, att(key, plain.length)), ex);
    });

    test('bản ghi đính kèm: khứ hồi, từ chối định dạng lạ/khóa sai cỡ', () {
      final clock = HlcClock('dev1');
      final a = att(cipher.newFileKey(), 123);
      final r = SyncRecord(id: a.id, type: RecordTypes.attachment, walletId: w1).setAll(a.toValues(), clock);
      final back = Attachment.fromRecord(SyncRecord.fromBytes(r.toBytes()))!;
      expect((back.txnId, back.size), (txn1, 123));
      expect(back.fileKey, a.fileKey);
      expect(Attachment.fromRecord(r.set('fmt', 2, clock)), isNull);
      expect(Attachment.fromRecord(r.set('key', base64.encode([1, 2]), clock)), isNull);
      expect(r.toValues().containsKey('name'), isFalse);
    });
  });
}

extension on SyncRecord {
  Map<String, Object?> toValues() => {for (final e in fields.entries) e.key: e.value.value};
}
