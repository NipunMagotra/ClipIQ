import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Content type filter for clipboard items.
enum ClipFilter { all, text, code, links, images, html }

/// Horizontal row of minimalist text-only tabs for filtering clipboard items.
///
/// Inactive tabs are flat text; the active tab shows a 2px bottom accent underline.
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ClipFilter selected;
  final ValueChanged<ClipFilter> onChanged;

  static const _filters = [
    (ClipFilter.all,    'All'),
    (ClipFilter.text,   'Text'),
    (ClipFilter.code,   'Code'),
    (ClipFilter.links,  'Links'),
    (ClipFilter.images, 'Images'),
    (ClipFilter.html,   'HTML'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _filters.map((item) {
          final (filter, label) = item;
          final isActive = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: _FilterTab(
              label: label,
              isActive: isActive,
              onTap: () => onChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterTab extends StatefulWidget {
  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_FilterTab> createState() => _FilterTabState();
}

class _FilterTabState extends State<_FilterTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isActive
        ? AppTheme.textPrimary
        : _hovered
            ? AppTheme.textSecondary
            : AppTheme.textMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                widget.label,
                style: AppTheme.uiLabel.copyWith(
                  color: textColor,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedContainer(
              duration: AppConstants.animQuick,
              curve: Curves.easeOut,
              width: widget.isActive ? 20 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: widget.isActive ? AppTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
