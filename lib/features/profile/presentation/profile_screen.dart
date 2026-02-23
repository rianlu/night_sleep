import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
import 'package:night_sleep/core/theme/theme_controller.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/core/utils/app_preferences.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:night_sleep/main.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (viewportHeight * 0.30).clamp(200.0, 280.0);
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = theme.brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
          );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAtmosphereHero(theme, palette, heroHeight + topPadding),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(theme, palette, '播放设置'),
                    const SizedBox(height: 14),
                    _buildGroup(
                      theme,
                      palette,
                      children: [
                        _buildFadeOutSwitch(theme, palette),
                        _buildDivider(palette),
                        _buildRepeatModeItem(theme, palette),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle(theme, palette, '解析设置'),
                    const SizedBox(height: 14),
                    _buildGroup(
                      theme,
                      palette,
                      children: [_buildAutoClipboardSwitch(theme, palette)],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle(theme, palette, '个性化'),
                    const SizedBox(height: 14),
                    _buildPersonalizationGroup(theme, palette),
                    const SizedBox(height: 28),
                    _buildSectionTitle(theme, palette, '关于与支持'),
                    const SizedBox(height: 14),
                    _buildGroup(
                      theme,
                      palette,
                      children: [
                        _buildNavItem(
                          theme,
                          palette,
                          Icons.info_rounded,
                          '关于 夜眠',
                        ),
                        _buildDivider(palette),
                        _buildNavItem(
                          theme,
                          palette,
                          Icons.favorite_rounded,
                          '支持我们',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        '版本 1.2.4 (2023)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.titleMuted.withValues(alpha: 0.5),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtmosphereHero(
    ThemeData theme,
    AppPalette palette,
    double height,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final bg = theme.scaffoldBackgroundColor;
    final topColor = Color.lerp(bg, primary, isDark ? 0.12 : 0.06)!;
    final bottomColor = Color.lerp(bg, primary, isDark ? 0.04 : 0.015)!;
    final titleColor = Color.lerp(
      palette.titleStrong,
      primary,
      isDark ? 0.16 : 0.28,
    )!;
    final sloganColor = Color.lerp(
      palette.titleMuted,
      primary,
      isDark ? 0.08 : 0.06,
    )!;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _HeroCurvePainter(
                lineColor: primary.withValues(alpha: isDark ? 0.10 : 0.06),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '夜眠',
                  style: GoogleFonts.notoSerifSc(
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '享受安静的睡眠时光',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: sloganColor,
                    letterSpacing: 3.2,
                    fontWeight: FontWeight.w300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, AppPalette palette, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: palette.titleSecondary,
        letterSpacing: 2.2,
        fontSize: 11,
      ),
    );
  }

  Widget _buildGroup(
    ThemeData theme,
    AppPalette palette, {
    required List<Widget> children,
  }) {
    return Material(
      color: palette.groupBg,
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: palette.cardBorderSoft.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(
        height: 1,
        thickness: 1,
        color: palette.cardBorderSoft.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildSwitchItem({
    required ThemeData theme,
    required AppPalette palette,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: palette.titleStrong,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: palette.switchThumb,
        activeTrackColor: palette.switchActiveTrack,
        inactiveThumbColor: palette.switchThumb,
        inactiveTrackColor: palette.switchInactiveTrack,
      ),
    );
  }

  Widget _buildPersonalizationGroup(ThemeData theme, AppPalette palette) {
    return _buildGroup(
      theme,
      palette,
      children: [
        _buildThemeColorPicker(theme, palette),
        _buildDivider(palette),
        _buildAppearanceModeSelector(theme, palette),
      ],
    );
  }

  Widget _buildThemeColorPicker(ThemeData theme, AppPalette palette) {
    return Consumer<ThemeController>(
      builder: (context, ctrl, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '主题配色',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.titleStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ThemeSeed.presets.map((preset) {
                  final isSelected = ctrl.seed == preset;
                  return ThemeSwitcher(
                    builder: (context) {
                      return GestureDetector(
                        onTap: () {
                          ctrl.setTheme(preset);
                          ThemeSwitcher.of(
                            context,
                          ).changeTheme(theme: ctrl.themeData);
                        },
                        child: Column(
                          children: [
                            SizedBox(
                              width: 58,
                              height: 58,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(
                                          alpha:
                                              theme.brightness ==
                                                  Brightness.dark
                                              ? 0.28
                                              : 0.18,
                                        )
                                      : Colors.transparent,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: preset.primary,
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              preset.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? palette.titleStrong
                                    : palette.titleMuted,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceModeSelector(ThemeData theme, AppPalette palette) {
    return Consumer<ThemeController>(
      builder: (context, ctrl, _) {
        return ThemeSwitcher(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '外观模式',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.titleStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildModeOption(
                          context: context,
                          theme: theme,
                          palette: palette,
                          controller: ctrl,
                          mode: ThemeAppearanceMode.light,
                          label: '浅色',
                        ),
                        _buildModeOption(
                          context: context,
                          theme: theme,
                          palette: palette,
                          controller: ctrl,
                          mode: ThemeAppearanceMode.dark,
                          label: '深色',
                        ),
                        _buildModeOption(
                          context: context,
                          theme: theme,
                          palette: palette,
                          controller: ctrl,
                          mode: ThemeAppearanceMode.system,
                          label: '跟随系统',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required ThemeData theme,
    required AppPalette palette,
    required ThemeController controller,
    required ThemeAppearanceMode mode,
    required String label,
  }) {
    final selected = controller.mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.setAppearanceMode(mode);
          ThemeSwitcher.of(context).changeTheme(theme: controller.themeData);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? palette.groupBg : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? palette.titleStrong : palette.titleMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFadeOutSwitch(ThemeData theme, AppPalette palette) {
    return Consumer<AppPreferences>(
      builder: (context, prefs, _) {
        return _buildSwitchItem(
          theme: theme,
          palette: palette,
          icon: Icons.waves_rounded,
          title: '淡入淡出',
          value: prefs.fadeOutEnabled,
          onChanged: (val) {
            prefs.setFadeOutEnabled(val);
            if (audioHandler is AudioPlayerHandler) {
              (audioHandler as AudioPlayerHandler).setFadeOutEnabled(val);
            }
          },
        );
      },
    );
  }

  Widget _buildAutoClipboardSwitch(ThemeData theme, AppPalette palette) {
    return Consumer<AppPreferences>(
      builder: (context, prefs, _) {
        return _buildSwitchItem(
          theme: theme,
          palette: palette,
          icon: Icons.assignment_rounded,
          title: '自动识别剪贴板',
          value: prefs.autoDetectClipboard,
          onChanged: (val) {
            prefs.setAutoDetectClipboard(val);
          },
        );
      },
    );
  }

  Widget _buildRepeatModeItem(ThemeData theme, AppPalette palette) {
    final handler = audioHandler as AudioPlayerHandler;

    return StreamBuilder<AudioServiceRepeatMode>(
      stream: handler.repeatModeStream,
      initialData: AudioServiceRepeatMode.none,
      builder: (context, repeatSnap) {
        return StreamBuilder<bool>(
          stream: handler.shuffleModeStream,
          initialData: false,
          builder: (context, shuffleSnap) {
            final isShuffle = shuffleSnap.data ?? false;
            final repeatMode = repeatSnap.data ?? AudioServiceRepeatMode.none;

            var modeText = '顺序播放';
            if (isShuffle) {
              modeText = '随机播放';
            } else if (repeatMode == AudioServiceRepeatMode.one) {
              modeText = '单曲循环';
            } else if (repeatMode == AudioServiceRepeatMode.all) {
              modeText = '列表循环';
            }

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.format_list_bulleted_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              title: Text(
                '播放队列逻辑',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.titleStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    modeText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.titleMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.chevronColor,
                    size: 20,
                  ),
                ],
              ),
              onTap: () async {
                await handler.cyclePlayMode();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem(
    ThemeData theme,
    AppPalette palette,
    IconData icon,
    String title,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: palette.titleStrong,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: palette.chevronColor,
        size: 20,
      ),
      onTap: () {
        // Placeholder for future actions.
      },
    );
  }
}

class _HeroCurvePainter extends CustomPainter {
  const _HeroCurvePainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final farPath = Path()
      ..moveTo(-20, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.70,
        size.width * 0.56,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.80,
        size.width + 20,
        size.height * 0.74,
      );

    final nearPath = Path()
      ..moveTo(-20, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.80,
        size.width * 0.50,
        size.height * 0.84,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.90,
        size.width + 20,
        size.height * 0.84,
      );

    canvas.drawPath(farPath, linePaint);
    canvas.drawPath(
      nearPath,
      linePaint..color = lineColor.withValues(alpha: lineColor.a * 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _HeroCurvePainter other) {
    return other.lineColor != lineColor;
  }
}
