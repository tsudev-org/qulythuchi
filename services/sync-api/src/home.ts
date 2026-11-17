/** Trang chủ tạm (một trang tĩnh, không script) cho tới khi site Astro lên ở P8. */
const STYLE =
  'body{margin:0;font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;background:#f7f8fa;color:#14171f}' +
  'main{max-width:40rem;margin:0 auto;padding:3rem 1rem}h1{font-size:1.75rem;margin:0 0 .5rem}' +
  'p{line-height:1.6}a{color:#0b5cad}' +
  '@media (prefers-color-scheme:dark){body{background:#101318;color:#e7e9ee}a{color:#7cb7ff}}';

async function sha256B64(s: string): Promise<string> {
  const d = new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s)));
  let b = '';
  for (const x of d) b += String.fromCharCode(x);
  return btoa(b);
}

let csp: string | null = null;

/** CSP của trang chủ: style nội tuyến cho phép theo băm (không 'unsafe-inline'), không script nào. */
export async function homeCsp(): Promise<string> {
  csp ??= `default-src 'none'; style-src 'sha256-${await sha256B64(STYLE)}'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`;
  return csp;
}

export function homePage(): string {
  return `<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Quly Thu Chi</title>
<meta name="description" content="Quly Thu Chi - quản lý thu chi mã hóa đầu-cuối của hệ sinh thái tsudev.">
<style>${STYLE}</style>
</head>
<body>
<main>
<h1>Quly Thu Chi</h1>
<p>App quản lý thu chi <strong>mã hóa đầu-cuối</strong>: dữ liệu được mã hóa trên thiết bị của bạn trước khi đồng bộ.
Máy chủ này chỉ giữ bản mã - không ai, kể cả chúng tôi, đọc được số tiền hay ghi chú của bạn.</p>
<p>Trang giới thiệu và bản web đang được hoàn thiện. Mã nguồn (AGPL-3.0):
<a href="https://github.com/tsudev-org/qulythuchi" rel="noopener">github.com/tsudev-org/qulythuchi</a>.</p>
<p>Một sản phẩm của <a href="https://tsudev.com" rel="noopener">tsudev</a>.</p>
</main>
</body>
</html>`;
}
