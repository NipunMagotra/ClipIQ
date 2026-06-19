import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'clip_icons.dart';

/// Hero search field for ClipQ v2.
///
/// Height: 48px. Full-width with 12px horizontal margin.
/// Borderless by default with flat zinc-900 surface background.
/// Blinks accent blue cursor, and gains accent border only on focus.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search clips...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<SearchField> createState() => SearchFieldState();
}

class SearchFieldState extends State<SearchField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  /// Expose focus node so parent can programmatically request focus.
  FocusNode get focusNode => _focus;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void clear() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final isMac = !kIsWeb && Platform.isMacOS;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard, // zinc-900 (slightly elevated)
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: _focused ? AppTheme.accent : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          onChanged: widget.onChanged,
          style: AppTheme.uiBody.copyWith(
            color: AppTheme.textPrimary,
          ),
          cursorColor: AppTheme.accent,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTheme.uiBody.copyWith(
              color: AppTheme.textMuted,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: ClipSearchIcon(color: AppTheme.textMuted, size: 16),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: hasText
                ? GestureDetector(
                    onTap: clear,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppTheme.textMuted,
                        size: 14,
                      ),
                    ),
                  )
                : (!_focused
                    ? Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: _ShortcutBadge(label: isMac ? '⌃⌘V' : 'Ctrl+Alt+V'),
                      )
                    : null),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  const _ShortcutBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Text(
        label,
        style: AppTheme.uiLabel.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
