import 'package:flutter/material.dart';
import 'package:night_sleep/features/home/presentation/home_play_screen.dart';
import 'package:night_sleep/features/home/presentation/widgets/stitch_bottom_nav_bar.dart';
import 'package:night_sleep/features/library/presentation/library_screen.dart';
import 'package:night_sleep/features/profile/presentation/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 这是悬浮导航栏的关键设置，允许内容区延伸到导航栏下方
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePlayScreen(
            onNavigateToLibrary: () => setState(() => _currentIndex = 1),
          ),
          const LibraryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: StitchBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
