// Màn chờ của web app (phiếu UI2): Flutter web cần ~4,8 MB gzip (AGENTS.md B.4), mạng chậm mất hơn 10 s - trước đây
// cả lúc đó là nền đen trống, cả ở chế độ Sáng. Tệp nạp CHẶN trong <head> (CSP chỉ cho script-src 'self', không nội
// tuyến) để đặt data-theme TRƯỚC khung hình đầu, cùng lựa chọn mà app sẽ dùng: shared_preferences trên web lưu ở
// localStorage "flutter.theme" dạng chuỗi JSON ("light"|"dark"|"system"; "warm" cũ = light), chưa có = theo hệ thống
// (ThemeChoice.parse trong lib/theme/app_theme.dart). Màn chờ được gỡ khi engine báo khung hình đầu.
(function () {
  'use strict';
  var NEN = { light: '#FAFAFA', dark: '#0A0A0A' };   // bgBase của tokens.g.dart (.standards/tokens)
  var goc = document.documentElement;
  var chon = null;
  try { chon = JSON.parse(window.localStorage.getItem('flutter.theme')); } catch (e) { chon = null; }
  if (chon === 'warm') chon = 'light';
  if (chon !== 'light' && chon !== 'dark') {
    var toi = false;
    try { toi = window.matchMedia('(prefers-color-scheme: dark)').matches; } catch (e) { toi = false; }
    chon = toi ? 'dark' : 'light';
  }
  goc.setAttribute('data-theme', chon);
  var meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', NEN[chon]);

  function go() {
    var m = document.getElementById('man-cho');
    if (m && m.parentNode) m.parentNode.removeChild(m);
  }
  window.addEventListener('flutter-first-frame', go, { once: true });
})();
