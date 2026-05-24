import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_vocabulary/core/themes/app_theme.dart';
import 'package:king_vocabulary/features/learning/screens/match_words_screen.dart';
import 'package:king_vocabulary/features/learning/screens/fill_blank_screen.dart';
import 'package:king_vocabulary/features/learning/screens/study_screen.dart';

class LearningModeScreen extends StatelessWidget {
  final String deckId;
  final String deckTitle;
  final int totalWords;

  const LearningModeScreen({
    super.key,
    required this.deckId,
    required this.deckTitle,
    this.totalWords = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LexiColors.sky50,
      appBar: AppBar(
        title: Text(
          'Chọn chế độ học',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header info
              _buildDeckInfo(),
              const SizedBox(height: 32),

              // Title
              Text(
                'Chọn cách học phù hợp với bạn',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: LexiColors.slate600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Mode 1: Flashcards (Lật từ)
              _buildModeCard(
                context,
                icon: Icons.flip_rounded,
                iconBg: LexiColors.sky100,
                iconColor: LexiColors.sky600,
                title: 'Lật từ',
                subtitle: 'Flashcards',
                description: 'Xem từ và nghĩa, lật thẻ để ghi nhớ',
                difficulty: 'Dễ',
                difficultyColor: LexiColors.mint600,
                estimatedTime: '5-10 phút',
                onTap: () {
                  // TODO: Navigate to FlashcardScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudyScreen(deckId: deckId, deckTitle: deckTitle),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Mode 2: Match Words (Nối từ)
              _buildModeCard(
                context,
                icon: Icons.compare_arrows_rounded,
                iconBg: LexiColors.lav100,
                iconColor: LexiColors.lav600,
                title: 'Nối từ',
                subtitle: 'Match Game',
                description: 'Nối từ tiếng Anh với nghĩa tiếng Việt',
                difficulty: 'Trung bình',
                difficultyColor: LexiColors.amber600,
                estimatedTime: '10-15 phút',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchWordsScreen(
                        deckId: deckId,
                        deckTitle: deckTitle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Mode 3: Fill in the Blank (Điền từ)
              _buildModeCard(
                context,
                icon: Icons.edit_note_rounded,
                iconBg: LexiColors.mint100,
                iconColor: LexiColors.mint600,
                title: 'Điền từ',
                subtitle: 'Fill in the Blank',
                description: 'Điền từ vào chỗ trống trong câu',
                difficulty: 'Khó',
                difficultyColor: LexiColors.red600,
                estimatedTime: '15-20 phút',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FillBlankScreen(deckId: deckId, deckTitle: deckTitle),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Tips section
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LexiColors.sky500, LexiColors.sky400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LexiColors.sky400.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            deckTitle,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalWords từ vựng',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
    required String difficulty,
    required Color difficultyColor,
    required String estimatedTime,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LexiColors.sky100, width: 2),
          boxShadow: [
            BoxShadow(
              color: LexiColors.sky200.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: LexiColors.slate800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: LexiColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              description,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LexiColors.slate600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Meta info
            Row(
              children: [
                // Difficulty badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: difficultyColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_rounded,
                        size: 14,
                        color: difficultyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        difficulty,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: difficultyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Time estimate
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: LexiColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: LexiColors.slate500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        estimatedTime,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: LexiColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LexiColors.amber50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LexiColors.amber100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: LexiColors.amber400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mẹo học hiệu quả',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: LexiColors.amber800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Bắt đầu với Lật từ để làm quen'),
          _buildTipItem('Chơi Nối từ để kiểm tra trí nhớ'),
          _buildTipItem('Thử Điền từ khi đã thuộc từ vựng'),
          _buildTipItem('Lặp lại mỗi ngày để ghi nhớ lâu dài'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: LexiColors.amber600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: LexiColors.amber900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
