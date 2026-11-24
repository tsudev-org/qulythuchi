# Contributing to Quly Thu Chi

_Tiếng Việt: mọi đóng góp đều được chào đón. Bạn có thể viết issue và pull request bằng tiếng Việt hoặc tiếng Anh._

Quly Thu Chi is an end-to-end encrypted personal finance app (Flutter) with a sync server (Cloudflare Workers). The
data it handles is financial (classification **D3**), so the bar for changes to encryption, sync and sign-in is high.

## Get the source and run it

```bash
git clone https://github.com/tsudev-org/qulythuchi.git && cd qulythuchi
(cd packages/core && dart pub get && dart test)                 # core: money, crypto envelopes, sync records
(cd apps/app && flutter pub get && flutter test)                # app (Flutter 3.50.1, pinned in CI)
(cd services/sync-api && npm ci && npm test)                    # sync server (Workers + D1 + R2, runs in workerd)
(cd apps/site && npm ci) && ./scripts/build-web.sh                # web app (/app/) + website (Astro), checked dist
```

Linux desktop builds need `libsecret-1-dev` and `libgtk-3-dev`. Architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md);
decisions: [`docs/adr/`](docs/adr/).

## Reporting

- **Bugs and feature requests**: [GitHub Issues](https://github.com/tsudev-org/qulythuchi/issues/new/choose) (forms).
  Never paste your financial data, recovery words or passwords.
- **Vulnerabilities**: never in a public issue - see [`SECURITY.md`](SECURITY.md).

## Pull request requirements

1. One change per pull request, merged into `main` by squash. Commit messages follow
   [Conventional Commits](https://www.conventionalcommits.org/) (`feat: ...`, `fix: ...`).
2. **Tests**: every change in behaviour comes with tests in the same pull request; a bug fix comes with a regression test
   that fails without the fix. Money is always an integer in minor units with an ISO 4217 code - never `double`.
3. **All CI checks green** ([`ci.yml`](.github/workflows/ci.yml), [`apple.yml`](.github/workflows/apple.yml)):
   `dart format` + `dart analyze --fatal-infos` / `flutter analyze --fatal-infos` (zero warnings), `flutter test`,
   `dart test`, `tsc --noEmit`, `eslint`, `vitest`, npm audit, gitleaks, the conformance vectors checked against an
   independent libsodium, and the iOS/macOS builds.
4. **Cryptography**: never implement primitives - only libsodium calls; every envelope format has a version and AAD
   ([ADR-0002](docs/adr/0002-ma-hoa-dau-cuoi-phan-cap-khoa.md)). Changing a format bumps its version and regenerates
   `conformance/` in the same pull request. Changes to encryption, sync or sign-in add a security review in
   [`docs/security-reviews/`](docs/security-reviews/).
5. Never write user data to logs, error messages, URLs or analytics.
6. By contributing you agree that your work is licensed under [AGPL-3.0-only](LICENSE).

## Code of conduct

Everyone taking part follows the [tsudev-org Code of Conduct](https://github.com/tsudev-org/.github/blob/main/CODE_OF_CONDUCT.md).
