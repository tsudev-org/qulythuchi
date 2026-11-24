# Bản vá tạm `sodium` 4.1.5+1

Bản chép nguyên gói [`sodium` 4.1.5+1](https://pub.dev/packages/sodium/versions/4.1.5+1) (BSD-3-Clause, `LICENSE`)
từ pub.dev, bỏ `example/`, `test/`, `tool/`. App dùng qua `dependency_overrides` trong `apps/app/pubspec.yaml`.

**Thay đổi duy nhất** - `lib/src/hooks/sodium_builder/automake_builder.dart`, hàm `_configure`: gọi `configure` bằng
đường dẫn tuyệt đối. Lý do: Dart 3.14.0 chuyển `Process.start` trên macOS sang `posix_spawn` (changelog Dart 3.14.0,
`dart:io`), đường dẫn tương đối `./configure` bị giải theo thư mục của tiến trình cha ⇒ build hook hỏng trên
macOS/iOS ("ProcessException: No such file or directory"). Upstream:
<https://github.com/Skycoder42/libsodium_dart_bindings/issues/245>.

Không đụng mã gọi libsodium (`lib/src/api`, `lib/src/ffi`, `lib/src/js`), tarball libsodium và chữ ký minisign giữ
nguyên. Kiểm: `diff -r ~/.pub-cache/hosted/pub.dev/sodium-4.1.5+1/lib third_party/sodium/lib` chỉ khác đúng hàm trên.

**Gỡ khi** upstream phát hành bản có sửa: xoá thư mục này + khối `dependency_overrides`, nâng `sodium` trong
`apps/app/pubspec.yaml` và `packages/core/pubspec.yaml`.
