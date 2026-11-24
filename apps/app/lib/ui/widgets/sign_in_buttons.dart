import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings.dart';
import '../../state/sync_controller.dart' show loginProvidersProvider;
import '../../sync/pkce.dart' show fallbackLoginProviders;
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import 'common.dart';

/// Khoá SharedPreferences ghi lối đăng nhập lần trước (dùng chung với màn chào [TsuSignInScreen]).
const kLastLoginProvider = 'lastLoginProvider';

/// Lối vào ĐÚNG thứ tự (AUTH_AND_ACCOUNT.md mục 3 + 3.2): Google, Apple, GitHub - chỉ những lối IdP tsudev.com đang
/// bật ([loginProvidersProvider]) - rồi tài khoản tsudev. Tất cả đi qua IdP (cùng một tài khoản). Đánh dấu "Lần trước
/// bạn dùng cách này" để tránh tạo tài khoản thứ hai. [onSignIn] nhận id lối liên kết hoặc null (tài khoản tsudev).
class SignInButtons extends ConsumerWidget {
  const SignInButtons({super.key, required this.onSignIn, this.busy = false});
  final Future<void> Function(String? provider) onSignIn;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final prefs = ref.watch(sharedPreferencesProvider);
    final last = prefs.getString(kLastLoginProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Lối liên kết do IdP quyết (mục 3.2); đang tải ⇒ dùng dự phòng Google + GitHub để không giật bố cục.
    final providers = ref.watch(loginProvidersProvider).value ?? fallbackLoginProviders;

    Future<void> go(String key, String? provider) async {
      await prefs.setString(kLastLoginProvider, key);
      await onSignIn(provider);
    }

    Widget lastBadge(String key) => last == key
        ? Padding(
            padding: const EdgeInsets.only(top: QtSpace.s1),
            child: Text(
              l.signInLastUsed,
              style: TextStyle(color: p.textMuted, fontSize: QtFontSize.xs),
            ),
          )
        : const SizedBox.shrink();

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(QtRadius.md));

    Widget providerButton(String id) {
      final (Color bg, Color fg, Color border, Widget icon, String label) = switch (id) {
        'google' => (
          Colors.white,
          const Color(0xFF1F1F1F),
          p.borderStrong,
          Image.asset('assets/brand/providers/google.png', width: 18, height: 18, excludeFromSemantics: true),
          l.signInGoogle,
        ),
        // Apple HIG: nền đen ở chế độ Sáng, nền trắng ở chế độ Tối, cùng cỡ nút Google (AUTH_AND_ACCOUNT mục 3).
        'apple' => (
          dark ? Colors.white : Colors.black,
          dark ? Colors.black : Colors.white,
          dark ? Colors.white : Colors.black,
          const Icon(Icons.apple, size: 20),
          l.signInApple,
        ),
        _ => (
          dark ? p.bgSurface : const Color(0xFF24292F),
          Colors.white,
          dark ? p.borderStrong : const Color(0xFF24292F),
          Image.asset('assets/brand/providers/github-light.png', width: 18, height: 18, excludeFromSemantics: true),
          l.signInGithub,
        ),
      };
      return SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          key: Key('signin.$id'),
          onPressed: busy ? null : () => go(id, id),
          style: OutlinedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            iconColor: fg,
            side: BorderSide(color: border),
            shape: shape,
          ),
          icon: icon,
          label: Text(label),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in providers) ...[providerButton(id), lastBadge(id), const SizedBox(height: QtSpace.s3)],
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            key: const Key('signin.tsudev'),
            onPressed: busy ? null : () => go('tsudev', null),
            style: FilledButton.styleFrom(shape: shape),
            icon: const Icon(Icons.mail_outline, size: 18),
            label: Text(busy ? l.syncWaitingBrowser : l.signInTsudev),
          ),
        ),
        lastBadge('tsudev'),
      ],
    );
  }
}
