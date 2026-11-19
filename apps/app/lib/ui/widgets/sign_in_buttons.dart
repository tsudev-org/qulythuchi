import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import 'common.dart';

const _kLastProvider = 'lastLoginProvider';

/// Ba lối vào bắt buộc, ĐÚNG thứ tự (AUTH_AND_ACCOUNT.md mục 3): Google, GitHub, tài khoản tsudev. Cả ba đi qua
/// IdP tsudev.com (cùng một tài khoản). Đánh dấu "Lần trước bạn dùng cách này" để tránh tạo tài khoản thứ hai.
/// [onSignIn] nhận `google`, `github` hoặc null (tài khoản tsudev bằng email).
class SignInButtons extends ConsumerWidget {
  const SignInButtons({super.key, required this.onSignIn, this.busy = false});
  final Future<void> Function(String? provider) onSignIn;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final prefs = ref.watch(sharedPreferencesProvider);
    final last = prefs.getString(_kLastProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    Future<void> go(String key, String? provider) async {
      await prefs.setString(_kLastProvider, key);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            key: const Key('signin.google'),
            onPressed: busy ? null : () => go('google', 'google'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              side: BorderSide(color: p.borderStrong),
              shape: shape,
            ),
            icon: Image.asset('assets/brand/providers/google.png', width: 18, height: 18, excludeFromSemantics: true),
            label: Text(l.signInGoogle),
          ),
        ),
        lastBadge('google'),
        const SizedBox(height: QtSpace.s3),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            key: const Key('signin.github'),
            onPressed: busy ? null : () => go('github', 'github'),
            style: OutlinedButton.styleFrom(
              backgroundColor: dark ? p.bgSurface : const Color(0xFF24292F),
              foregroundColor: Colors.white,
              side: BorderSide(color: dark ? p.borderStrong : const Color(0xFF24292F)),
              shape: shape,
            ),
            icon: Image.asset(
              'assets/brand/providers/github-light.png',
              width: 18,
              height: 18,
              excludeFromSemantics: true,
            ),
            label: Text(l.signInGithub),
          ),
        ),
        lastBadge('github'),
        const SizedBox(height: QtSpace.s3),
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
