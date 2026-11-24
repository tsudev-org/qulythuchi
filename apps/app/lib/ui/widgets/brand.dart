// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/brand.dart';

export '../../theme/brand.dart';

final tsudevHome = Uri.parse('https://tsudev.com');

/// Dấu hiệu sản phẩm trong giao diện (trang trí: tên sản phẩm luôn có chữ đi kèm nên bỏ khỏi cây ngữ nghĩa).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(brandLogoAsset, width: size, height: size, filterQuality: FilterQuality.medium),
  );
}

/// Khối nhà làm: logo tsudev + chữ, dẫn về tsudev.com.
class MakerTile extends StatelessWidget {
  const MakerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      leading: ExcludeSemantics(child: Image.asset(tsudevLogoAsset, width: 24, height: 24)),
      title: Text(l.settingsMadeBy),
      subtitle: const Text('tsudev.com'),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => launchUrl(tsudevHome, mode: LaunchMode.externalApplication),
    );
  }
}
