import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_vocabulary/core/themes/app_theme.dart';
import 'package:king_vocabulary/features/flashcards/models/flash_card.dart';
import 'package:king_vocabulary/features/flashcards/services/deck_service.dart';
import 'package:king_vocabulary/features/flashcards/services/sm2_service.dart';

class StudyScreen extends StatefulWidget {
  final String deckId;
  final String deckTitle;

  const StudyScreen({super.key, required this.deckId, required this.deckTitle});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with TickerProviderStateMixin {
  final _deckService = DeckService();
  final _sm2 = SM2Service();

  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;

  // Thống kê kết quả
  int _easyCount = 0;
  int _okCount = 0;
  int _hardCount = 0;
  int _forgotCount = 0;

  // Animation controller cho flip
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _loadCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final cards = await _deckService.watchFlashcards(widget.deckId).first;
    setState(() {
      _cards = cards..shuffle(); // shuffle để học không theo thứ tự
      _isLoading = false;
    });
  }

  // ── Lật thẻ ─────────────────────────────────────────────────────────────────
  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  // ── Trả lời ─────────────────────────────────────────────────────────────────
  Future<void> _onAnswer(int q) async {
    final card = _cards[_currentIndex];

    // Cập nhật thống kê
    setState(() {
      if (q == 5)
        _easyCount++;
      else if (q == 4)
        _okCount++;
      else if (q == 3)
        _hardCount++;
      else
        _forgotCount++;
    });

    // Tính SM-2 và cập nhật Firestore
    final result = _sm2.calculate(
      q: q,
      easeFactor: card.easeFactor,
      intervalDays: card.reviewIntervalDays,
      repetitionCount: card.repetitionCount,
    );

    await _deckService.updateFlashcard(
      widget.deckId,
      card.flashcardId,
      easeFactor: result.easeFactor,
      intervalDays: result.intervalDays,
      repetitionCount: result.repetitionCount,
      nextReviewAt: result.nextReviewAt,
    );

    // Chuyển sang thẻ tiếp theo
    _flipController.reset();
    setState(() {
      _isFlipped = false;
      _currentIndex++;
    });
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Màn hình kết quả
    if (_currentIndex >= _cards.length) {
      return _buildResultScreen();
    }

    return Scaffold(
      backgroundColor: LexiColors.sky50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            const SizedBox(height: 24),
            Expanded(child: _buildCardArea()),
            _buildBottomArea(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: LexiColors.sky100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: LexiColors.sky600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.deckTitle,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: LexiColors.slate800,
                  ),
                ),
                Text(
                  '${_currentIndex + 1} / ${_cards.length}',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: LexiColors.slate400,
                  ),
                ),
              ],
            ),
          ),
          // Mini stats
          Row(
            children: [
              _buildMiniStat('😊', '$_easyCount', LexiColors.mint600),
              const SizedBox(width: 8),
              _buildMiniStat('😐', '$_hardCount', LexiColors.sky600),
              const SizedBox(width: 8),
              _buildMiniStat('😵', '$_forgotCount', LexiColors.red400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LexiColors.sky100),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            count,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    final progress = _cards.isEmpty ? 0.0 : _currentIndex / _cards.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: LexiColors.sky100,
          valueColor: const AlwaysStoppedAnimation<Color>(LexiColors.sky400),
        ),
      ),
    );
  }

  // ── Card area ────────────────────────────────────────────────────────────────
  Widget _buildCardArea() {
    final card = _cards[_currentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _flipCard,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final angle = _flipAnimation.value * 3.14159;
            final isFrontVisible = _flipAnimation.value <= 0.5;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isFrontVisible
                  ? _buildCardFace(
                      label: 'Từ tiếng Anh',
                      content: card.frontContent,
                      hint: 'Nhấn để xem nghĩa',
                      gradient: const LinearGradient(
                        colors: [LexiColors.sky500, LexiColors.sky400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.14159),
                      child: _buildCardFace(
                        label: 'Nghĩa tiếng Việt',
                        content: card.backContent,
                        hint: 'Chọn mức độ nhớ bên dưới',
                        gradient: const LinearGradient(
                          colors: [LexiColors.mint600, LexiColors.mint400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFace({
    required String label,
    required String content,
    required String hint,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: LexiColors.sky400.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              content,
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white54,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  hint,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom area ──────────────────────────────────────────────────────────────
  Widget _buildBottomArea() {
    if (!_isFlipped) {
      // Chưa lật — hiện nút lật
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _flipCard,
            icon: const Icon(Icons.flip_rounded, size: 18),
            label: const Text('Lật thẻ'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      );
    }

    // Đã lật — hiện 4 nút đánh giá
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'Bạn nhớ từ này ở mức nào?',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: LexiColors.slate500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRatingButton(
                  label: 'Không nhớ',
                  emoji: '😵',
                  color: LexiColors.red400,
                  bgColor: LexiColors.red50,
                  onTap: () => _onAnswer(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRatingButton(
                  label: 'Khó',
                  emoji: '😓',
                  color: LexiColors.lav600,
                  bgColor: LexiColors.lav100,
                  onTap: () => _onAnswer(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRatingButton(
                  label: 'Ổn',
                  emoji: '😊',
                  color: LexiColors.sky600,
                  bgColor: LexiColors.sky100,
                  onTap: () => _onAnswer(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRatingButton(
                  label: 'Dễ',
                  emoji: '🤩',
                  color: LexiColors.mint600,
                  bgColor: LexiColors.mint100,
                  onTap: () => _onAnswer(5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton({
    required String label,
    required String emoji,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Result screen ────────────────────────────────────────────────────────────
  Widget _buildResultScreen() {
    final total = _cards.length;
    final remembered = _easyCount + _okCount + _hardCount;
    final percent = total == 0 ? 0 : (remembered / total * 100).round();

    return Scaffold(
      backgroundColor: LexiColors.sky50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Trophy icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LexiColors.sky500, LexiColors.sky400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: LexiColors.sky400.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hoàn thành!',
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: LexiColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đã học xong ${_cards.length} từ trong bộ "${widget.deckTitle}"',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LexiColors.slate400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Tỉ lệ nhớ
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LexiColors.sky100),
                ),
                child: Column(
                  children: [
                    Text(
                      '$percent%',
                      style: GoogleFonts.nunito(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: LexiColors.sky500,
                      ),
                    ),
                    Text(
                      'tỉ lệ nhớ',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LexiColors.slate400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildResultStat(
                            '🤩',
                            'Dễ',
                            '$_easyCount',
                            LexiColors.mint600,
                          ),
                        ),
                        Expanded(
                          child: _buildResultStat(
                            '😊',
                            'Ổn',
                            '$_okCount',
                            LexiColors.sky600,
                          ),
                        ),
                        Expanded(
                          child: _buildResultStat(
                            '😓',
                            'Khó',
                            '$_hardCount',
                            LexiColors.lav600,
                          ),
                        ),
                        Expanded(
                          child: _buildResultStat(
                            '😵',
                            'Quên',
                            '$_forgotCount',
                            LexiColors.red400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                      _easyCount = 0;
                      _okCount = 0;
                      _hardCount = 0;
                      _forgotCount = 0;
                      _isFlipped = false;
                      _cards.shuffle();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Học lại'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Về danh sách từ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(
    String emoji,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: LexiColors.slate400,
          ),
        ),
      ],
    );
  }
}
