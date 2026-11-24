// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/ledger_repository.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  CategoryKind get _kind => _tabs.index == 0 ? CategoryKind.expense : CategoryKind.income;

  Future<void> _edit({Category? category, String? parentId}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CategoryDialog(kind: category?.kind ?? _kind, category: category, parentId: parentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navCategories),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.categoryExpense),
            Tab(text: l.categoryIncome),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.categoryNew,
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: PageBody(
        child: TabBarView(
          controller: _tabs,
          children: [for (final kind in CategoryKind.values) _CategoryList(data: data, kind: kind, onEdit: _edit)],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.data, required this.kind, required this.onEdit});
  final LedgerData data;
  final CategoryKind kind;
  final Future<void> Function({Category? category, String? parentId}) onEdit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final roots = data.categories.where((c) => c.kind == kind && c.parentId == null).toList();
    if (roots.isEmpty) {
      return EmptyState(icon: Icons.category_outlined, title: l.noResults, body: '');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s4, QtSpace.s4, 96),
      children: [
        for (final r in roots)
          Padding(
            padding: const EdgeInsets.only(bottom: QtSpace.s3),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(categoryIcon(r.icon), color: p.primary),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      tooltip: '${l.categoryNew}: ${r.name}',
                      icon: const Icon(Icons.add),
                      onPressed: () => onEdit(parentId: r.id),
                    ),
                    onTap: () => onEdit(category: r),
                  ),
                  for (final c in data.categories.where((c) => c.parentId == r.id))
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: QtSpace.s12, right: QtSpace.s4),
                      leading: Icon(categoryIcon(c.icon ?? r.icon), size: 20),
                      title: Text(c.name),
                      onTap: () => onEdit(category: c),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Hộp thoại thêm/sửa danh mục.
class CategoryDialog extends ConsumerStatefulWidget {
  const CategoryDialog({super.key, required this.kind, this.category, this.parentId});
  final CategoryKind kind;
  final Category? category;
  final String? parentId;

  @override
  ConsumerState<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.category?.name ?? '');
  late String? _parentId = widget.category?.parentId ?? widget.parentId;
  late String _icon = widget.category?.icon ?? 'label';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final notifier = ref.read(ledgerProvider.notifier);
    final c = widget.category;
    try {
      notifier.saveCategory(
        Category(
          id: c?.id ?? notifier.newId(),
          name: _name.text.trim(),
          kind: widget.kind,
          parentId: _parentId,
          icon: _icon,
          color: c?.color,
          archived: c?.archived ?? false,
        ),
      );
      Navigator.pop(context);
      context.toast(context.l10n.saved);
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final c = widget.category!;
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.categoryDeleteConfirm(c.name)) || !mounted) return;
    ref.read(ledgerProvider.notifier).deleteCategory(c.id);
    Navigator.pop(context);
    context.toast(l.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final self = widget.category;
    final hasChildren = self != null && data.categories.any((c) => c.parentId == self.id);
    final parents = data.categories.where((c) => c.kind == widget.kind && c.parentId == null && c.id != self?.id);
    return AlertDialog(
      title: Text(self == null ? l.categoryNew : l.categoryEdit),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: l.categoryName, counterText: ''),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l.errNameRequired : null,
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: QtSpace.s4),
                DropdownButtonFormField<String?>(
                  initialValue: parents.any((c) => c.id == _parentId) ? _parentId : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.categoryParent),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.categoryNoParent)),
                    for (final c in parents) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  // Nhóm đang có danh mục con thì không thể thành danh mục con (chỉ 2 tầng).
                  onChanged: hasChildren ? null : (v) => setState(() => _parentId = v),
                ),
                const SizedBox(height: QtSpace.s4),
                Wrap(
                  spacing: QtSpace.s1,
                  runSpacing: QtSpace.s1,
                  children: [
                    for (final name in categoryIconNames)
                      IconButton(
                        tooltip: name,
                        isSelected: _icon == name,
                        style: IconButton.styleFrom(
                          backgroundColor: _icon == name ? p.primary : null,
                          foregroundColor: _icon == name ? p.onPrimary : p.textSecondary,
                        ),
                        icon: Icon(categoryIcon(name)),
                        onPressed: () => setState(() => _icon = name),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (self != null)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: p.danger),
            child: Text(l.actionDelete),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        FilledButton(onPressed: _save, child: Text(l.actionSave)),
      ],
    );
  }
}
