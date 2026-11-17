import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tokens.g.dart';
import 'common.dart';

/// Khung trang sửa/thêm: tiêu đề, nút xóa (khi sửa), danh sách trường, nút Lưu.
class EditPage extends StatelessWidget {
  const EditPage({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
    this.onDelete,
    this.extraActions = const [],
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...extraActions,
          if (onDelete != null)
            IconButton(tooltip: l.actionDelete, icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
      body: PageBody(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(QtSpace.s4),
            children: [
              for (final c in children) ...[c, const SizedBox(height: QtSpace.s4)],
              const SizedBox(height: QtSpace.s2),
              FilledButton(onPressed: onSave, child: Text(l.actionSave)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Đóng trang sửa: quay lại nếu có lịch sử, nếu không về [fallback].
void closePage(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// Ẩn toast của trang trước để không che nút Lưu.
void hideToastSoon(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
  });
}
