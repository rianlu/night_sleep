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
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "睡眠周报",
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "10月23日 - 10月29日",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProMaxColors.stitchReportCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ProMaxColors.stitchReportAccent, size: 16),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.manrope(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isTrendPositive ? "📈 $trend" : "📉 $trend",
              style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar("周一", 0.4),
                _buildBar("周二", 0.6),
                _buildBar("周三", 0.5),
                _buildBar("周四", 0.7),
                _buildBar("周五", 0.9, isHighlight: true),
                _buildBar("周六", 0.8),
                _buildBar("周日", 0.6),
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
        Container(
          width: 32,
          height: 100 * percent,
          decoration: BoxDecoration(
            color: isHighlight ? ProMaxColors.stitchReportAccent : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isHighlight ? [
              BoxShadow(color: ProMaxColors.stitchReportAccent.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)
            ] : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(day, style: TextStyle(color: isHighlight ? ProMaxColors.stitchReportAccent : Colors.white24, fontSize: 10, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProMaxColors.stitchReportCardBg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
            child: const Icon(Icons.music_note_rounded, color: Colors.white24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(duration, style: const TextStyle(color: ProMaxColors.stitchReportAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                      child: Text(category, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: const AlwaysStoppedAnimation(ProMaxColors.stitchReportAccent),
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
    return Center(
      child: Text(
        "\" 良好的睡眠是治愈一切的良药。\"",
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 14,
          fontStyle: FontStyle.italic,
          fontFamily: 'Serif',
        ),
      ),
    );
  }
}
