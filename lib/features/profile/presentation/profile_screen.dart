import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
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
      backgroundColor: const Color(0xFFFFFBF2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, palette),
              const SizedBox(height: 48),
              
              _buildSectionTitle(theme, palette, '播放设置'),
              const SizedBox(height: 16),
              _buildGroup(
                theme,
                children: [
                  _buildFadeOutSwitch(theme, palette),
                  _buildDivider(palette),
                  _buildRepeatModeItem(theme, palette),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle(theme, palette, '解析设置'),
              const SizedBox(height: 16),
              _buildGroup(
                theme,
                children: [
                   _buildAutoClipboardSwitch(theme, palette),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle(theme, palette, '关于与支持'),
              const SizedBox(height: 16),
              _buildGroup(
                theme,
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

  Widget _buildHeader(ThemeData theme, AppPalette palette) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF0D4),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF3A738).withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              color: Color(0xFFF3A738),
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
                color: const Color(0xFF5F4139), // Deeper brown text
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '享受安静的睡眠时光',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFAFA698),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, AppPalette palette, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFFC4B6A6),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildGroup(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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

  Widget _buildFadeOutSwitch(ThemeData theme, AppPalette palette) {
    return Consumer<AppPreferences>(
      builder: (context, prefs, _) {
        return _buildSwitchItem(
          theme: theme,
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
          icon: Icons.assignment_rounded, // or content_paste
          title: '自动识别剪贴板',
          value: prefs.autoDetectClipboard,
          onChanged: (val) {
             prefs.setAutoDetectClipboard(val);
          },
        );
      },
    );
  }

  Widget _buildSwitchItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: const Color(0xFFF3A738), size: 28),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: const Color(0xFF5F4139),
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFFFFDFB),
        activeTrackColor: const Color(0xFFF3A738),
        inactiveThumbColor: const Color(0xFFFFFDFB),
        inactiveTrackColor: const Color(0xFFE5DDD0),
      ),
    );
  }

  Widget _buildRepeatModeItem(ThemeData theme, AppPalette palette) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, stateSnap) {
        final state = stateSnap.data;
        // In AudioPlayerHandler, we can check its stream, but here we can just do a lightweight hack or add stream getters
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
                    leading: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFFF3A738), size: 28),
                    title: Text(
                      '播放队列逻辑',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF5F4139),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          modeText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFAFA698),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFE5DDD0), size: 20),
                      ],
                    ),
                    onTap: () async {
                      // Cycle logic
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

  Widget _buildNavItem(ThemeData theme, AppPalette palette, IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: const Color(0xFFF3A738), size: 28),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: const Color(0xFF5F4139),
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFE5DDD0), size: 20),
      onTap: () {
        // Placeholder for future actions
      },
    );
  }
}
