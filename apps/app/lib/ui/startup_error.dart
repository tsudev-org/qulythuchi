import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';

/// Màn hình khi không mở được kho bí mật/CSDL (ví dụ: libsecret chưa chạy trên Linux, kho khóa bị xóa).
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final choice = ThemeChoice.parse(prefs.getString('theme'));
    final loc = prefs.getString('locale');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: choice.mode,
      locale: loc == null ? null : Locale(loc),
      localeResolutionCallback: (device, _) => resolveAppLocale(device),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // ignore: deprecated_member_use
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // ignore: deprecated_member_use
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).errStorage, textAlign: TextAlign.center),
                  // Linux tối giản/WSL không có Secret Service (org.freedesktop.secrets) ⇒ plugin trả PlatformException:
                  // chỉ ra cách khắc phục thay vì câu lỗi chung (phiếu 20261125-01 mục 1.5).
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) ...[
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(AppLocalizations.of(context).errStorageLinuxHint, textAlign: TextAlign.center),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
