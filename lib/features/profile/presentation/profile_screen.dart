import 'dart:math' as math;

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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _breathController.repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    }
  }

  Future<void> _openBilibili() async {
    final nativeUri = Uri.parse('bilibili://space/20656755');
    final webUri = Uri.parse('https://space.bilibili.com/20656755');
    
    try {
      // 尝试在原生应用中打开
      final launched = await launchUrl(
        nativeUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (!launched) {
        // 如果失败，回退到浏览器打开
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // 捕获可能抛出的 PlatformException 并安全地在浏览器打开
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开链接')),
          );
        }
      }
    }
  }

  void _shareApp() {
    Share.share('推荐一个超好用的助眠播放器——夜眠，自动跳过 B 站片尾，让你安心睡到天亮。🌙✨\n下载链接：https://www.pgyer.com/nightsleep');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (viewportHeight * 0.30).clamp(200.0, 280.0);
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
              AnimatedBuilder(
                animation: _breathController,
                builder: (context, child) {
                  final motion = reduceMotion ? 0.5 : _breathController.value;
                  return _buildAtmosphereHero(
                    theme,
                    palette,
                    heroHeight + topPadding,
                    motion,
                  );
                },
              ),
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
                    _buildSectionTitle(theme, palette, '联系与社交'),
                    const SizedBox(height: 14),
                    _buildGroup(
                      theme,
                      palette,
                      children: [
                        _buildNavItem(
                          theme,
                          palette,
                          Icons.share_rounded,
                          '分享给朋友',
                          onTap: _shareApp,
                        ),
                        _buildDivider(palette),
                        _buildNavItem(
                          theme,
                          palette,
                          Icons.ondemand_video_rounded,
                          '来 B 站催更',
                          onTap: _openBilibili,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        '版本 $_appVersion',
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
    double motion,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final bg = theme.scaffoldBackgroundColor;
    final topColor = Color.lerp(bg, primary, isDark ? 0.08 : 0.035)!;
    final bottomColor = Color.lerp(bg, primary, isDark ? 0.02 : 0.008)!;
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
        clipBehavior: Clip.hardEdge,
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
            child: _BreathingHaze(
              primary: primary,
              isDark: isDark,
              motion: motion,
            ),
          ),
          Positioned.fill(
            child: _DriftingMist(
              primary: primary,
              isDark: isDark,
              motion: motion,
            ),
          ),
          Positioned.fill(
            child: _FloatingGlow(
              primary: primary,
              isDark: isDark,
              motion: motion,
              phaseOffset: 0.0,
              anchorX: -0.42,
            ),
          ),
          Positioned.fill(
            child: _FloatingGlow(
              primary: primary,
              isDark: isDark,
              motion: motion,
              phaseOffset: math.pi * 0.86,
              anchorX: 0.42,
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
                    letterSpacing: 5,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '享受安静的睡眠时光',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: sloganColor,
                    letterSpacing: 2.8,
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
        activeThumbColor: palette.switchActiveThumb,
        activeTrackColor: palette.switchActiveTrack,
        inactiveThumbColor: palette.switchInactiveThumb,
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
        _buildDarkModeSwitch(theme, palette),
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

  Widget _buildDarkModeSwitch(ThemeData theme, AppPalette palette) {
    return Consumer<ThemeController>(
      builder: (context, ctrl, _) {
        return ThemeSwitcher(
          builder: (context) {
            return _buildSwitchItem(
              theme: theme,
              palette: palette,
              icon: ctrl.isDark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              title: '深色模式',
              value: ctrl.isDark,
              onChanged: (_) {
                ctrl.toggleBrightness();
                ThemeSwitcher.of(context).changeTheme(theme: ctrl.themeData);
              },
            );
          },
        );
      },
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
    String title, {
    VoidCallback? onTap,
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
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: palette.chevronColor,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _BreathingHaze extends StatelessWidget {
  const _BreathingHaze({
    required this.primary,
    required this.isDark,
    required this.motion,
  });

  final Color primary;
  final bool isDark;
  final double motion;

  @override
  Widget build(BuildContext context) {
    final wave = 0.5 + 0.5 * math.sin((motion * 2 * math.pi) - math.pi / 2);
    final baseAlpha = isDark ? 0.10 : 0.08;
    final alpha = (baseAlpha + wave * 0.07).clamp(0.0, 0.17);
    final spread = 0.95 + wave * 0.12;

    return Transform.translate(
      offset: Offset(0, -11 + wave * 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withValues(alpha: alpha * 0.48),
              primary.withValues(alpha: alpha * 0.30),
              Colors.transparent,
            ],
            stops: const [0.0, 0.22, 0.72],
          ),
        ),
        child: Transform.scale(
          scale: spread,
          alignment: Alignment.topCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.82),
                radius: 0.95,
                colors: [
                  primary.withValues(alpha: alpha),
                  primary.withValues(alpha: alpha * 0.60),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.34, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _DriftingMist extends StatelessWidget {
  const _DriftingMist({
    required this.primary,
    required this.isDark,
    required this.motion,
  });

  final Color primary;
  final bool isDark;
  final double motion;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin((motion * 2 * math.pi));
    final phase = math.sin((motion * 2 * math.pi) + math.pi / 2);
    final dx = wave * 32;
    final dy = phase * 5;
    final alpha = isDark ? 0.07 : 0.06;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-1.0, -0.25),
            end: const Alignment(1.0, 0.25),
            colors: [
              Colors.transparent,
              primary.withValues(alpha: alpha),
              primary.withValues(alpha: alpha * 0.58),
              Colors.transparent,
            ],
            stops: const [0.0, 0.44, 0.66, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FloatingGlow extends StatelessWidget {
  const _FloatingGlow({
    required this.primary,
    required this.isDark,
    required this.motion,
    required this.phaseOffset,
    required this.anchorX,
  });

  final Color primary;
  final bool isDark;
  final double motion;
  final double phaseOffset;
  final double anchorX;

  @override
  Widget build(BuildContext context) {
    final phase = (motion * 2 * math.pi) + phaseOffset;
    final sway = math.sin(phase);
    final breath = 0.5 + 0.5 * math.sin(phase - math.pi / 2);
    final dx = sway * 18;
    final dy = -12 + math.cos(phase * 0.6) * 4;
    final alpha = isDark ? 0.055 : 0.045;
    final radius = 78.0 + (breath * 10);

    return IgnorePointer(
      child: Align(
        alignment: Alignment(anchorX, -0.62),
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primary.withValues(alpha: alpha),
                  primary.withValues(alpha: alpha * 0.55),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.44, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
