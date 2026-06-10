import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/services/clipboard_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/clipboard_sync_service.dart';
import '../../data/models/clipboard_item.dart';
import '../notifiers/clipboard_history_notifier.dart';

/// Flat card for a single clipboard history item.
///
/// Features:
///  - Left teal border accent bar
///  - Content type label (TEXT / HTML)
///  - Relative timestamp
///  - Tap to copy with ✓ feedback
///  - Swipe-left to delete with confirmation
class ClipCard extends ConsumerStatefulWidget {
  const ClipCard({
    super.key,
    required this.item,
    required this.index,
  });

  final ClipboardItem item;
  final int index;

  @override
  ConsumerState<ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends ConsumerState<ClipCard> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    final clipService = ref.read(clipboardServiceProvider);
    
    ClipboardPayload payload;
    if (widget.item.contentType == 'image') {
      final repo = ref.read(clipboardRepositoryProvider);
      final bytes = widget.item.storagePath != null
          ? await repo.downloadImage(widget.item.storagePath!)
          : null;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download image')),
        );
        return;
      }
      payload = ClipboardPayload(
        contentType: 'image',
        imageBytes: bytes,
      );
    } else {
      payload = ClipboardPayload(
        contentType: widget.item.contentType,
        textContent: widget.item.preview,
      );
    }

    try {
      await clipService.writeClipboard(payload);
      if (!mounted) return;
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy to clipboard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) {
        ref.read(clipboardHistoryProvider.notifier).deleteItem(widget.item.id);
      },
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    final isImage = widget.item.contentType == 'image';
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: AppTheme.accentCard(),
      child: InkWell(
        onTap: _copyToClipboard,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildContent()),
              if (isImage && widget.item.storagePath != null) ...[
                const SizedBox(width: 12),
                _buildImagePreview(),
              ],
              const SizedBox(width: 12),
              _buildCopyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final imageUrl = Supabase.instance.client.storage
        .from('clipboards')
        .getPublicUrl(widget.item.storagePath!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            color: AppTheme.surfaceElevated,
            child: const Icon(Icons.broken_image_outlined,
                color: AppTheme.textMuted, size: 20),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: AppTheme.surfaceElevated,
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primary),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final preview = widget.item.preview;
    final isImage = widget.item.contentType == 'image';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type label + timestamp
        Row(
          children: [
            _TypeLabel(type: widget.item.contentType),
            const Spacer(),
            Text(
              timeago.format(widget.item.copiedAt),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Preview content
        if (isImage)
          const Row(
            children: [
              Icon(Icons.image_outlined, color: AppTheme.primaryLight, size: 16),
              SizedBox(width: 6),
              Text(
                'Image Clipboard Item',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        else
          Text(
            preview.isEmpty ? '(empty)' : preview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: preview.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildCopyButton() {
    if (_copied) {
      return Container(
        width: 32,
        height: 32,
        color: AppTheme.success.withAlpha(20),
        child: const Icon(Icons.check, color: AppTheme.success, size: 16),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border.all(color: AppTheme.border),
      ),
      child: const Icon(Icons.copy, color: AppTheme.textSecondary, size: 15),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: AppTheme.error.withAlpha(25),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
          SizedBox(width: 6),
          Text(
            'Delete',
            style: TextStyle(
              color: AppTheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'Delete this clip?',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        content: const Text(
          'This item will be permanently removed from your history on all devices.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

// ── Type Label ──────────────────────────────────────────────────────────────────

class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'html'  => ('HTML', AppTheme.warning),
      'image' => ('IMG',  AppTheme.primaryLight),
      _       => ('TEXT', AppTheme.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(120)),
        color: color.withAlpha(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
