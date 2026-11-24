// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../theme/tokens.g.dart';
import 'common.dart';

/// Ô chọn ngày (DD/MM/YYYY). [onCleared] != null ⇒ có nút bỏ chọn (ngày không bắt buộc).
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onChanged, this.onCleared});
  final String label;
  final CivilDate? value;
  final ValueChanged<CivilDate> onChanged;
  final VoidCallback? onCleared;

  Future<void> _pick(BuildContext context) async {
    final v = value ?? todayCivil();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(v.year, v.month, v.day),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(CivilDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(QtRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null && onCleared != null
              ? IconButton(tooltip: l.clearValue, icon: const Icon(Icons.close), onPressed: onCleared)
              : const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? '-' : formatDate(value!)),
      ),
    );
  }
}

/// Ô chọn nhiều mục (mở hộp thoại có ô đánh dấu). Rỗng = "tất cả" ([allLabel]).
class MultiSelectField extends StatelessWidget {
  const MultiSelectField({
    super.key,
    required this.label,
    required this.allLabel,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String allLabel;

  /// (id, nhãn, thụt lề?)
  final List<(String, String, bool)> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  Future<void> _open(BuildContext context) async {
    final current = {...selected};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: 420,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final (id, name, indent) in options)
                  CheckboxListTile(
                    value: current.contains(id),
                    contentPadding: EdgeInsets.only(left: indent ? QtSpace.s8 : 0),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(name),
                    onChanged: (v) => setLocal(() => v == true ? current.add(id) : current.remove(id)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, <String>{}), child: Text(allLabel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, current), child: Text(ctx.l10n.actionDone)),
          ],
        ),
      ),
    );
    if (result == null) return;
    onChanged([
      for (final (id, _, _) in options)
        if (result.contains(id)) id,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final names = [
      for (final (id, name, _) in options)
        if (selected.contains(id)) name,
    ];
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(QtRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.arrow_drop_down)),
        child: Text(names.isEmpty ? allLabel : names.join(', '), maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Thanh tiến độ có nhãn đọc màn hình và màu theo trạng thái (kèm icon/chữ ở nơi gọi).
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.basisPoints, required this.color, required this.semanticLabel});
  final int basisPoints;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    value: '${(basisPoints / 100).floor()}%',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(QtRadius.sm),
      child: LinearProgressIndicator(
        value: (basisPoints.clamp(0, 10000)) / 10000,
        minHeight: 8,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
    ),
  );
}

/// Danh mục dạng (id, tên, là con?) theo thứ tự cha → con, lọc theo loại.
List<(String, String, bool)> categoryOptions(Iterable<Category> all, CategoryKind kind) {
  final out = <(String, String, bool)>[];
  for (final r in all.where((c) => c.kind == kind && c.parentId == null && !c.archived)) {
    out.add((r.id, r.name, false));
    for (final c in all.where((c) => c.parentId == r.id && !c.archived)) {
      out.add((c.id, c.name, true));
    }
  }
  return out;
}

/// Hộp thoại tự sở hữu các [TextEditingController] (hủy khi hộp thoại thật sự rời cây, SAU hiệu ứng đóng).
/// Không được hủy controller ngay sau `await showDialog(...)`: hiệu ứng đóng vẫn còn vẽ ô nhập.
class ControllerScope extends StatefulWidget {
  const ControllerScope({super.key, required this.count, required this.builder});
  final int count;
  final Widget Function(BuildContext context, List<TextEditingController> controllers) builder;

  @override
  State<ControllerScope> createState() => _ControllerScopeState();
}

class _ControllerScopeState extends State<ControllerScope> {
  late final List<TextEditingController> _c = List.generate(widget.count, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _c);
}
