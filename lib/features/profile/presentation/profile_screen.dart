import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
import 'package:night_sleep/core/theme/theme_controller.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/core/utils/app_preferences.dart';
import 'package:night_sleep/main.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, palette),
              const SizedBox(height: 48),

              // ── 外观设置 ──
              _buildSectionTitle(theme, palette, '外观设置'),
              const SizedBox(height: 16),
              _buildGroup(
                theme,
                palette,
                children: [
                  _buildDarkModeSwitch(theme, palette),
                  _buildDivider(palette),
                  _buildThemeColorPicker(theme, palette),
                ],
              ),
              const SizedBox(height: 32),
              
              // ── 播放设置 ──
              _buildSectionTitle(theme, palette, '播放设置'),
              const SizedBox(height: 16),
              _buildGroup(
                theme,
                palette,
                children: [
                  _buildFadeOutSwitch(theme, palette),
                  _buildDivider(palette),
                  _buildRepeatModeItem(theme, palette),
                ],
              ),
              const SizedBox(height: 32),
              
              // ── 解析设置 ──
              _buildSectionTitle(theme, palette, '解析设置'),
              const SizedBox(height: 16),
              _buildGroup(
                theme,
                palette,
                children: [
                   _buildAutoClipboardSwitch(theme, palette),
                ],
              ),
              const SizedBox(height: 32),
              
              // ── 关于 ──
              _buildSectionTitle(theme, palette, '关于与支持'),
              const SizedBox(height: 16),
              _buildGroup(
                theme,
                palette,
                children: [
                   _buildNavItem(theme, palette, Icons.info_rounded, '关于 夜眠'),
                   _buildDivider(palette),
                   _buildNavItem(theme, palette, Icons.favorite_rounded, '支持我们'),
                ],
              ),
              const SizedBox(height: 64),
              
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
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  头部
  // ─────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, AppPalette palette) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.headerAvatar,
            border: Border.all(color: palette.headerAvatarBorder, width: 3),
            boxShadow: [
              BoxShadow(
                color: palette.headerAvatarShadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '夜眠用户',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.titleStrong,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '享受安静的睡眠时光',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.titleMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  通用组件
  // ─────────────────────────────────────────────

  Widget _buildSectionTitle(ThemeData theme, AppPalette palette, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: palette.titleSecondary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildGroup(ThemeData theme, AppPalette palette, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: palette.groupBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.groupShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(height: 1, thickness: 1, color: palette.cardBorderSoft.withValues(alpha: 0.4)),
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
      leading: Icon(icon, color: theme.colorScheme.primary, size: 28),
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
        activeColor: palette.switchThumb,
        activeTrackColor: palette.switchActiveTrack,
        inactiveThumbColor: palette.switchThumb,
        inactiveTrackColor: palette.switchInactiveTrack,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  外观设置
  // ─────────────────────────────────────────────

  Widget _buildDarkModeSwitch(ThemeData theme, AppPalette palette) {
    return Consumer<ThemeController>(
      builder: (context, ctrl, _) {
        return ThemeSwitcher(
          builder: (context) {
            return _buildSwitchItem(
              theme: theme,
              palette: palette,
              icon: ctrl.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: '深色模式',
              value: ctrl.isDark,
              onChanged: (_) {
                ctrl.toggleBrightness();
                // We use next frame to let provider update ThemeData before snapshotting
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ThemeSwitcher.of(context).changeTheme(
                    theme: ctrl.themeData,
                  );
                });
              },
            );
          },
        );
      },
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
              Row(
                children: [
                  Icon(Icons.palette_rounded, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 16),
                  Text(
                    '色彩主题',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.titleStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ThemeSwitcher.of(context).changeTheme(
                              theme: ctrl.themeData,
                            );
                          });
                        },
                        child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: preset.primary,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: preset.primary.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: preset.primary.computeLuminance() > 0.45
                                      ? const Color(0xFF1F1F1F)
                                      : Colors.white,
                                  size: 20,
                                )
                              : null,
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
                            fontSize: 11,
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

  // ─────────────────────────────────────────────
  //  播放设置
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  //  播放队列逻辑
  // ─────────────────────────────────────────────

  Widget _buildRepeatModeItem(ThemeData theme, AppPalette palette) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, stateSnap) {
        return StreamBuilder<AudioServiceRepeatMode>(
          stream: (audioHandler as AudioPlayerHandler).repeatModeStream,
          initialData: AudioServiceRepeatMode.none,
          builder: (context, repeatSnap) {
            return StreamBuilder<bool>(
              stream: (audioHandler as AudioPlayerHandler).shuffleModeStream,
              initialData: false,
              builder: (context, shuffleSnap) {
                 final isShuffle = shuffleSnap.data ?? false;
                 final repeatMode = repeatSnap.data ?? AudioServiceRepeatMode.none;
                 
                 String modeText = '顺序播放';
                 if (isShuffle) {
                    modeText = '随机播放';
                 } else if (repeatMode == AudioServiceRepeatMode.one) {
                    modeText = '单曲循环';
                 } else if (repeatMode == AudioServiceRepeatMode.all) {
                    modeText = '列表循环';
                 }

                 return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Icon(Icons.format_list_bulleted_rounded, color: theme.colorScheme.primary, size: 28),
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
                        Icon(Icons.chevron_right_rounded, color: palette.chevronColor, size: 20),
                      ],
                    ),
                    onTap: () async {
                      final handler = audioHandler as AudioPlayerHandler;
                      await handler.cyclePlayMode();
                    },
                 );
              }
            );
          }
        );
      }
    );
  }

  // ─────────────────────────────────────────────
  //  导航项
  // ─────────────────────────────────────────────

  Widget _buildNavItem(ThemeData theme, AppPalette palette, IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: theme.colorScheme.primary, size: 28),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: palette.titleStrong,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: palette.chevronColor, size: 20),
      onTap: () {
        // Placeholder for future actions
      },
    );
  }
}
