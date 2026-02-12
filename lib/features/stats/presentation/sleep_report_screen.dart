import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';

class SleepReportScreen extends StatelessWidget {
  const SleepReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProMaxColors.stitchReportBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSummaryCards(),
            const SizedBox(height: 32),
            _buildTrendsChart(),
            const SizedBox(height: 32),
            _buildSleepCompanions(),
            const SizedBox(height: 48),
            _buildBottomQuote(),
            const SizedBox(height: 120), // Padding for Bottom Nav
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "睡眠周报",
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "10月23日 - 10月29日",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ProMaxColors.stitchReportCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 20),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time_filled_rounded,
            title: "本周总听",
            value: "28.5",
            unit: "小时",
            trend: "+2.4h",
            isTrendPositive: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.nights_stay_rounded,
            title: "平均入睡",
            value: "23:45",
            unit: "",
            trend: "早睡15m",
            isTrendPositive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String trend,
    required bool isTrendPositive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ProMaxColors.stitchReportCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative Circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: ProMaxColors.stitchPrimary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title, 
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4), 
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value, 
                        style: GoogleFonts.manrope(
                          color: Colors.white, 
                          fontSize: 32, 
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          unit, 
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3), 
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title.contains("总听"))
                          Icon(Icons.trending_up_rounded, color: ProMaxColors.stitchPrimary.withValues(alpha: 0.8), size: 12),
                        if (title.contains("入睡"))
                          Icon(Icons.check_rounded, color: ProMaxColors.stitchPrimary.withValues(alpha: 0.8), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: const TextStyle(
                            color: ProMaxColors.stitchPrimary, 
                            fontSize: 11, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ProMaxColors.stitchReportCardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: ProMaxColors.stitchReportAccent, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  const Text("收听时长趋势", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: const Text("近7天", style: TextStyle(color: Colors.white38, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildBar("周一", 0.4)),
                Expanded(child: _buildBar("周二", 0.6)),
                Expanded(child: _buildBar("周三", 0.5)),
                Expanded(child: _buildBar("周四", 0.7)),
                Expanded(child: _buildBar("周五", 0.9, isHighlight: true)),
                Expanded(child: _buildBar("周六", 0.8)),
                Expanded(child: _buildBar("周日", 0.6)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("日均收听 4.1h", style: TextStyle(color: Colors.white38, fontSize: 12)),
              const Text("比上周增加 12%", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double percent, {bool isHighlight = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Track Background
        Container(
          width: 36,
          height: 140, // Fixed track height
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), // Flat bottom
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 36,
            height: 140 * percent.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: isHighlight ? ProMaxColors.stitchPrimary : Colors.white.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), // Flat bottom matching track
              boxShadow: isHighlight ? [
                BoxShadow(
                  color: ProMaxColors.stitchPrimary.withValues(alpha: 0.3), 
                  blurRadius: 15, 
                  spreadRadius: 1,
                )
              ] : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          day, 
          style: TextStyle(
            color: isHighlight ? ProMaxColors.stitchPrimary : Colors.white.withValues(alpha: 0.3), 
            fontSize: 12, 
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepCompanions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: ProMaxColors.stitchReportAccent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            const Text("本周睡眠伴侣", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        _buildCompanionItem("罗翔说刑法", "法律科普", 0.85, "8.5h"),
        _buildCompanionItem("盗月社食遇记", "美食探店", 0.52, "5.2h"),
        _buildCompanionItem("助眠白噪音 - 雨声", "白噪音", 0.38, "3.8h"),
      ],
    );
  }

  Widget _buildCompanionItem(String title, String category, double progress, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProMaxColors.stitchCardBg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.black26, 
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      duration, 
                      style: const TextStyle(
                        color: ProMaxColors.stitchPrimary, 
                        fontSize: 14, 
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08), 
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        category, 
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5), 
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: const AlwaysStoppedAnimation(ProMaxColors.stitchPrimary),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomQuote() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          "\" 良好的睡眠是治愈一切的良药。\"",
          style: GoogleFonts.notoSans(
            color: Colors.white.withValues(alpha: 0.15),
            fontSize: 15,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
