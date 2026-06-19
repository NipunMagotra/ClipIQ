import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/clipboard_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clip_icons.dart';
import '../../application/clipboard_sync_service.dart';
import '../../data/models/clipboard_item.dart';
import '../notifiers/clipboard_history_notifier.dart';

/// Raycast-style compact list row for ClipQ v2.
///
/// Features:
///   • Height: 40px. No card decoration, transparent background by default.
///   • 1px hairline separator between rows.
///   • Inline custom thin-stroke content type icon (no circular background).
///   • Single-line truncated content preview.
///   • Right-aligned short timestamp (e.g., "2m").
///   • Actions only visible on hover with zero background decoration.
///   • Active/selected state: left 2px accent bar + very faint white tint.
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
  bool _hovered = false;

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
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.item.contentType == 'image';
    final text = widget.item.preview.replaceAll('\n', ' ');
    final isUrl = _looksLikeUrl(text);
    final isCode = _looksLikeCode(text);

    final icon = isImage
        ? const ClipImageIcon(size: 16)
        : isUrl
            ? const ClipLinkIcon(size: 16)
            : isCode
                ? const ClipCodeIcon(size: 16)
                : const ClipTextIcon(size: 16);

    final rowBackground = _copied
        ? AppTheme.accent.withOpacity(0.06)
        : _hovered
            ? Colors.white.withOpacity(0.03)
            : Colors.transparent;

    final decoration = BoxDecoration(
      color: rowBackground,
      border: Border(
        left: BorderSide(
          color: _hovered ? AppTheme.accent : Colors.transparent,
          width: 2,
        ),
        bottom: const BorderSide(
          color: AppTheme.divider,
          width: 0.5,
        ),
      ),
    );

    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) {
        ref.read(clipboardHistoryProvider.notifier).deleteItem(widget.item.id);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _copyToClipboard,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 40,
            decoration: decoration,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Content Type Icon
                icon,
                const SizedBox(width: 12),

                // Clipboard Content Preview
                Expanded(
                  child: Text(
                    isImage ? 'Image' : text,
                    style: isImage
                        ? AppTheme.uiBody.copyWith(color: AppTheme.textPrimary)
                        : isUrl
                            ? AppTheme.contentUrl
                            : isCode
                                ? AppTheme.contentMono.copyWith(fontSize: 12)
                                : AppTheme.uiBody.copyWith(color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (isImage && widget.item.storagePath != null) ...[
                  const SizedBox(width: 8),
                  _buildImageThumbnail(),
                ],

                const SizedBox(width: 12),

                // Right-aligned area (timestamp or actions)
                Container(
                  width: 56,
                  alignment: Alignment.centerRight,
                  child: _hovered
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _ActionButton(
                              icon: _copied
                                  ? const Icon(Icons.check_rounded,
                                      color: AppTheme.success, size: 14)
                                  : const ClipCopyIcon(size: 14),
                              tooltip: _copied ? 'Copied!' : 'Copy',
                              onTap: _copyToClipboard,
                            ),
                            const SizedBox(width: 4),
                            _ActionButton(
                              icon: const ClipDeleteIcon(size: 14),
                              tooltip: 'Delete',
                              onTap: () async {
                                final confirmed = await _confirmDelete(context);
                                if (confirmed && mounted) {
                                  ref
                                      .read(clipboardHistoryProvider.notifier)
                                      .deleteItem(widget.item.id);
                                }
                              },
                            ),
                          ],
                        )
                      : Text(
                          _formatTime(widget.item.copiedAt),
                          style: AppTheme.uiLabel.copyWith(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail() {
    final imageUrl = Supabase.instance.client.storage
        .from('clipboards')
        .getPublicUrl(widget.item.storagePath!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Image.network(
        imageUrl,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const ClipImageIcon(size: 14, color: AppTheme.textMuted),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 24,
            height: 24,
            color: AppTheme.surfaceElevated,
            child: const Center(
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.accent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.error,
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipDeleteIcon(size: 14, color: Colors.white),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete this clip?', style: AppTheme.uiStrong),
        content: Text(
          'This item will be permanently removed from your history on all devices.',
          style: AppTheme.uiBody.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative) return 'now';
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  bool _looksLikeCode(String text) {
    final codeIndicators = [
      '{',
      '}',
      '=>',
      'function',
      'class ',
      'import ',
      'const ',
      'var ',
      'let ',
      'def ',
      'return ',
      ';',
      '()',
      '[]'
    ];
    final lower = text.toLowerCase();
    return codeIndicators.any((ind) => lower.contains(ind));
  }

  bool _looksLikeUrl(String text) {
    final t = text.trim();
    return t.startsWith('http://') ||
        t.startsWith('https://') ||
        t.startsWith('www.') ||
        RegExp(r'^[\w.-]+\.\w{2,}(/|$)').hasMatch(t);
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Opacity(
                opacity: _hovered ? 1.0 : 0.6,
                child: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
