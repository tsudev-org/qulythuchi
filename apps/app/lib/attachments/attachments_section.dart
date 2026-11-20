import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../data/record_store.dart';
import '../state/providers.dart';
import '../state/sync_controller.dart';
import '../theme/tokens.g.dart';
import '../ui/widgets/common.dart';
import 'attachment_picker.dart';

/// Bộ chọn ảnh (test ghi đè bằng bản giả).
final attachmentPickerProvider = Provider<AttachmentPicker>((ref) => ImagePickerAttachmentPicker());

/// Hàm làm sạch ảnh (test ghi đè để chạy đồng bộ). Mặc định chạy trong isolate - giải mã ảnh 12 MP mất vài giây.
final imageSanitizerProvider = Provider<Future<SanitizedImage> Function(Uint8List)>(
  (ref) =>
      (bytes) => compute(ImageSanitizer.sanitize, bytes),
);

/// Bản rõ của ảnh: bản mã cục bộ, không có thì tải về (khi đã đăng nhập đồng bộ). null = chưa có ở đâu.
final attachmentBytesProvider = FutureProvider.autoDispose.family<Uint8List?, String>((ref, id) async {
  final repo = ref.read(repositoryProvider);
  final a = repo.attachment(id);
  if (a == null) return null;
  final local = repo.openAttachment(a);
  if (local != null) return local;
  return ref.read(syncProvider.notifier).fetchAttachment(a);
});

/// Ảnh nháp của giao dịch chưa lưu - gắn vào khi lưu ([commit]).
final class AttachmentDraft extends ChangeNotifier {
  final List<SanitizedImage> items = [];

  void add(SanitizedImage i) {
    items.add(i);
    notifyListeners();
  }

  void removeAt(int i) {
    items.removeAt(i);
    notifyListeners();
  }

  void commit(LedgerNotifier notifier, String txnId) {
    for (final i in items) {
      notifier.addAttachment(txnId, i);
    }
    items.clear();
  }
}

/// Mục "Ảnh hóa đơn" trong màn giao dịch (ADR-0017). [txnId] null = giao dịch mới (ảnh vào [draft]).
class AttachmentsSection extends ConsumerStatefulWidget {
  const AttachmentsSection({super.key, required this.txnId, required this.walletId, required this.draft});

  final String? txnId;
  final String? walletId;
  final AttachmentDraft draft;

  @override
  ConsumerState<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends ConsumerState<AttachmentsSection> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.draft.addListener(_changed);
  }

  @override
  void dispose() {
    widget.draft.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _add() async {
    final picker = ref.read(attachmentPickerProvider);
    final l = context.l10n;
    AttachmentSource? source = AttachmentSource.gallery;
    if (picker.supportsCamera) {
      source = await showModalBottomSheet<AttachmentSource>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l.attCamera),
                onTap: () => Navigator.pop(ctx, AttachmentSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l.attGallery),
                onTap: () => Navigator.pop(ctx, AttachmentSource.gallery),
              ),
            ],
          ),
        ),
      );
    }
    if (source == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final raw = await picker.pick(source);
      if (raw == null || !mounted) return;
      final image = await ref.read(imageSanitizerProvider)(raw);
      if (!mounted) return;
      if (widget.txnId == null) {
        widget.draft.add(image);
      } else {
        ref.read(ledgerProvider.notifier).addAttachment(widget.txnId!, image);
      }
    } on ImageRejectedException catch (e) {
      if (mounted) {
        context.toast(switch (e.reason) {
          ImageRejectReason.tooLarge => l.attRejectTooLarge,
          ImageRejectReason.tooManyPixels => l.attRejectPixels,
          ImageRejectReason.unsupported => l.attRejectUnsupported,
        });
      }
    } on Object catch (e) {
      if (mounted) context.toast(errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    final sync = ref.watch(syncProvider);
    final notifier = ref.read(ledgerProvider.notifier);
    final canEdit = data.canWrite(widget.walletId);
    final saved = widget.txnId == null ? const <Attachment>[] : notifier.attachmentsOf(widget.txnId!);
    final count = saved.length + widget.draft.items.length;
    final anyPending = saved.any((a) => notifier.attachmentState(a.id) == BlobState.pending);
    final small = Theme.of(context).textTheme.bodySmall;
    if (!canEdit && saved.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(l.attTitle, style: Theme.of(context).textTheme.titleSmall)),
            if (canEdit && count < Attachment.maxPerTxn)
              _busy
                  ? Semantics(
                      label: l.attProcessing,
                      child: const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : TextButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(l.attAdd),
                    ),
          ],
        ),
        if (count > 0) ...[
          const SizedBox(height: QtSpace.s2),
          Wrap(
            spacing: QtSpace.s2,
            runSpacing: QtSpace.s2,
            children: [
              for (final (i, a) in saved.indexed)
                _Thumb(
                  label: l.attView(i + 1),
                  pending: notifier.attachmentState(a.id) == BlobState.pending,
                  pendingLabel: l.attPending,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AttachmentViewerPage(id: a.id, canEdit: canEdit),
                    ),
                  ),
                  child: _SavedImage(id: a.id, cacheWidth: 160),
                ),
              for (final (i, img) in widget.draft.items.indexed)
                _Thumb(
                  label: l.attView(saved.length + i + 1),
                  onRemove: () => widget.draft.removeAt(i),
                  removeLabel: l.attDelete,
                  child: Image.memory(img.bytes, fit: BoxFit.cover, cacheWidth: 160),
                ),
            ],
          ),
        ],
        const SizedBox(height: QtSpace.s1),
        if (widget.txnId == null && widget.draft.items.isNotEmpty) Text(l.attNewHint, style: small),
        if (anyPending && sync.filesBlocked) Text(l.attProBlocked, style: small),
        if (canEdit) Text('${l.attPrivacy} ${l.attLimit(Attachment.maxPerTxn)}', style: small),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.label,
    required this.child,
    this.onTap,
    this.pending = false,
    this.pendingLabel,
    this.onRemove,
    this.removeLabel,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool pending;
  final String? pendingLabel;
  final VoidCallback? onRemove;
  final String? removeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: label,
      child: SizedBox.square(
        dimension: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(QtRadius.lg),
              child: Material(
                color: scheme.surfaceContainerHighest,
                child: InkWell(onTap: onTap, child: child),
              ),
            ),
            if (pending)
              Positioned(
                right: 2,
                bottom: 2,
                child: Tooltip(
                  message: pendingLabel ?? '',
                  child: Icon(Icons.cloud_off_outlined, size: 18, color: scheme.onSurface, semanticLabel: pendingLabel),
                ),
              ),
            if (onRemove != null)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  tooltip: removeLabel,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedImage extends ConsumerWidget {
  const _SavedImage({required this.id, this.cacheWidth, this.fit = BoxFit.cover});
  final String id;
  final int? cacheWidth;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return switch (ref.watch(attachmentBytesProvider(id))) {
      AsyncData(value: final bytes?) => Image.memory(bytes, fit: fit, cacheWidth: cacheWidth, gaplessPlayback: true),
      AsyncData() => Tooltip(
        message: l.attNotAvailable,
        child: Center(child: Icon(Icons.cloud_download_outlined, semanticLabel: l.attNotAvailable)),
      ),
      AsyncError() => Tooltip(
        message: l.attOpenFailed,
        child: Center(child: Icon(Icons.broken_image_outlined, semanticLabel: l.attOpenFailed)),
      ),
      _ => const Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
    };
  }
}

/// Xem ảnh toàn màn hình (phóng to được); xóa nếu có quyền ghi.
class AttachmentViewerPage extends ConsumerWidget {
  const AttachmentViewerPage({super.key, required this.id, required this.canEdit});
  final String id;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.attTitle),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: l.attDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirmDialog(context, message: l.attDeleteConfirm, confirmLabel: l.attDelete);
                if (!ok || !context.mounted) return;
                ref.read(ledgerProvider.notifier).deleteAttachment(id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: _SavedImage(id: id, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
