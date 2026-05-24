import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_vocabulary/core/themes/app_theme.dart';

class FillBlankScreen extends StatefulWidget {
  final String deckId;
  final String deckTitle;

  const FillBlankScreen({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  @override
  State<FillBlankScreen> createState() => _FillBlankScreenState();
}

class _FillBlankScreenState extends State<FillBlankScreen> {
  // Mock data - sẽ thay bằng data thật từ service
  final List<_Question> _questions = [
    _Question(
      id: '1',
      sentence: 'I eat an ___ every day',
      correctAnswer: 'apple',
      hint: 'Quả táo',
    ),
    _Question(
      id: '2',
      sentence: 'She is reading a ___',
      correctAnswer: 'book',
      hint: 'Quyển sách',
    ),
    _Question(
      id: '3',
      sentence: 'The ___ is sleeping on the sofa',
      correctAnswer: 'cat',
      hint: 'Con mèo',
    ),
    _Question(
      id: '4',
      sentence: 'My ___ is very friendly',
      correctAnswer: 'dog',
      hint: 'Con chó',
    ),
    _Question(
      id: '5',
      sentence: 'We live in a big ___',
      correctAnswer: 'house',
      hint: 'Ngôi nhà',
    ),
  ];

  int _currentIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  int _score = 0;
  int _correctCount = 0;
  bool _showResult = false;
  bool? _isCorrect;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = _questions[_currentIndex].correctAnswer.toLowerCase();

    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _showResult = true;

      if (_isCorrect!) {
        _score += 10;
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answerController.clear();
        _showResult = false;
        _isCorrect = null;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final percentage = (_correctCount / _questions.length * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          percentage >= 80
              ? '🎉 Xuất sắc!'
              : percentage >= 60
              ? '👍 Tốt lắm!'
              : '💪 Cố gắng lên!',
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: LexiColors.slate800,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: percentage >= 80
                    ? LexiColors.mint100
                    : percentage >= 60
                    ? LexiColors.sky100
                    : LexiColors.amber100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: percentage >= 80
                        ? LexiColors.mint600
                        : percentage >= 60
                        ? LexiColors.sky600
                        : LexiColors.amber600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Điểm số: $_score',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: LexiColors.sky600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đúng: $_correctCount/${_questions.length}',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: LexiColors.slate600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Về trang chủ',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: LexiColors.slate500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _correctCount = 0;
                _showResult = false;
                _isCorrect = null;
                _answerController.clear();
              });
            },
            child: const Text('Làm lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: LexiColors.sky50,
      appBar: AppBar(
        title: Text(
          widget.deckTitle,
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: LexiColors.mint100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⭐ $_score',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: LexiColors.mint600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(progress),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question number
                    Text(
                      'Câu ${_currentIndex + 1}/${_questions.length}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LexiColors.sky600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sentence with blank
                    _buildSentenceCard(question),
                    const SizedBox(height: 24),

                    // Hint
                    _buildHintCard(question.hint),
                    const SizedBox(height: 24),

                    // Answer input
                    _buildAnswerInput(),
                    const SizedBox(height: 16),

                    // Result feedback
                    if (_showResult) _buildResultFeedback(),
                    const SizedBox(height: 24),

                    // Action button
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 6,
      color: LexiColors.sky100,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [LexiColors.sky400, LexiColors.mint400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSentenceCard(_Question question) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LexiColors.sky100),
        boxShadow: [
          BoxShadow(
            color: LexiColors.sky200.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        question.sentence,
        style: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: LexiColors.slate800,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHintCard(String hint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LexiColors.lav50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LexiColors.lav100),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LexiColors.lav400,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gợi ý',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LexiColors.lav600,
                  ),
                ),
                Text(
                  hint,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LexiColors.lav800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return TextFormField(
      controller: _answerController,
      enabled: !_showResult,
      style: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: LexiColors.slate800,
      ),
      decoration: InputDecoration(
        hintText: 'Nhập câu trả lời...',
        hintStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: LexiColors.slate300,
        ),
        prefixIcon: const Icon(Icons.edit_rounded, color: LexiColors.sky400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LexiColors.sky200, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LexiColors.sky200, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LexiColors.sky400, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _isCorrect == true ? LexiColors.mint400 : LexiColors.red400,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildResultFeedback() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect! ? LexiColors.mint50 : LexiColors.red50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCorrect! ? LexiColors.mint400 : LexiColors.red400,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isCorrect! ? LexiColors.mint600 : LexiColors.red600,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCorrect! ? 'Chính xác! 🎉' : 'Chưa đúng 😔',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _isCorrect! ? LexiColors.mint800 : LexiColors.red800,
                  ),
                ),
                if (!_isCorrect!) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đáp án đúng: ${_questions[_currentIndex].correctAnswer}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: LexiColors.red700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _showResult ? _nextQuestion : _checkAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: _showResult ? LexiColors.sky400 : LexiColors.mint600,
        ),
        child: Text(
          _showResult
              ? (_currentIndex < _questions.length - 1
                    ? 'Câu tiếp theo'
                    : 'Xem kết quả')
              : 'Kiểm tra',
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _Question {
  final String id;
  final String sentence;
  final String correctAnswer;
  final String hint;

  _Question({
    required this.id,
    required this.sentence,
    required this.correctAnswer,
    required this.hint,
  });
}
