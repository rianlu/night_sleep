import 'package:flutter/material.dart';
import 'package:night_sleep/core/constants/app_constants.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
import 'package:night_sleep/core/theme/glass_style.dart';

class StitchBottomNavBar extends StatelessWidget {
  const StitchBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width <= AppConstants.compactBreakpoint;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: compact ? 32.0 : 48.0,
        right: compact ? 32.0 : 48.0,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 24.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.24 : 0.06,
              ),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: GlassStyle.blurFilter(
              theme.brightness,
              level: GlassLevel.nav,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: palette.navBg.withValues(
                  alpha: GlassStyle.opacity(
                    theme.brightness,
                    level: GlassLevel.nav,
                  ),
                ),
                borderRadius: BorderRadius.circular(100),
                border: Border.fromBorderSide(
                  GlassStyle.border(theme.brightness),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _item(context, 0, Icons.nightlight_round, '今晚', compact),
                  _item(context, 1, Icons.bookmark_rounded, '收藏', compact),
                  _item(context, 2, Icons.settings_rounded, '设置', compact),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int idx,
    IconData icon,
    String label,
    bool compact,
  ) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final selected = currentIndex == idx;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(idx),
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 20 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: compact ? 22 : 24,
                      color: selected
                          ? theme.colorScheme.primary
                          : palette.iconMuted,
                    ),
                    // 选中的时候展现文字，未选中则只展示图标，增加呼吸感
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 13 : 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
