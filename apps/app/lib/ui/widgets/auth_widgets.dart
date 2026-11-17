import 'package:flutter/material.dart';

import 'common.dart';

/// Ô mật khẩu có nút hiện/ẩn (nhãn đọc màn hình đầy đủ), tắt gợi ý/tự sửa của bàn phím.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.autofocus = false,
    this.onSubmitted,
    this.digitsOnly = false,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final bool digitsOnly;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      autofocus: widget.autofocus,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: widget.digitsOnly ? TextInputType.number : TextInputType.visiblePassword,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _visible ? l.hidePassword : l.showPassword,
          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

/// Khung chung cho màn khởi tạo/khóa: căn giữa, tối đa 480px.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, this.body, required this.children, this.leading});
  final String title;
  final String? body;
  final List<Widget> children;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: leading == null ? null : AppBar(leading: leading),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
                  if (body != null) ...[const SizedBox(height: 12), Text(body!)],
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cho khung hình kịp vẽ vòng quay trước khi chạy Argon2id (chặn luồng giao diện ~0,5-2 giây).
Future<void> yieldFrame() => Future<void>.delayed(const Duration(milliseconds: 60));
