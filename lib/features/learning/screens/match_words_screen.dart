import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_vocabulary/core/themes/app_theme.dart';
import 'package:king_vocabulary/features/flashcards/models/flash_card.dart';
import 'package:king_vocabulary/features/flashcards/services/deck_service.dart';

class MatchWordsScreen extends StatefulWidget {
  final String deckId;
  final String deckTitle;

  const MatchWordsScreen({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  @override
  State<MatchWordsScreen> createState() => _MatchWordsScreenState();
}

class _MatchWordsScreenState extends State<MatchWordsScreen> {
  final _deckService = DeckService();

  List<_WordPair> _englishWords = [];
  List<_WordPair> _vietnameseWords = [];

  String? _selectedEnglish;
  String? _selectedVietnamese;
  final Set<String> _matchedIds = {};
  int _score = 0;

  void _loadWords(List<Flashcard> flashcards) {
    final pairs = flashcards
        .map(
          (card) => _WordPair(
            id: card.flashcardId,
            english: card.frontContent,
            vietnamese: card.backContent,
          ),
        )
        .toList();

    final englishSide = List<_WordPair>.from(pairs)..shuffle();
    final vietnameseSide = List<_WordPair>.from(pairs)..shuffle();

    setState(() {
      _englishWords = englishSide;
      _vietnameseWords = vietnameseSide;
      _matchedIds.clear();
      _score = 0;
      _selectedEnglish = null;
      _selectedVietnamese = null;
    });
  }

  void _onEnglishTap(String id) {
    if (_matchedIds.contains(id)) return;
    setState(() => _selectedEnglish = id);
    _checkMatch();
  }

  void _onVietnameseTap(String id) {
    if (_matchedIds.contains(id)) return;
    setState(() => _selectedVietnamese = id);
    _checkMatch();
  }

  void _checkMatch() {
    if (_selectedEnglish == null || _selectedVietnamese == null) return;

    if (_selectedEnglish == _selectedVietnamese) {
      // Đúng!
      setState(() {
        _matchedIds.add(_selectedEnglish!);
        _score += 10;
        _selectedEnglish = null;
        _selectedVietnamese = null;
      });

      if (_matchedIds.length == _englishWords.length) {
        _showCompletionDialog();
      }
    } else {
      // Sai — reset sau 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _selectedEnglish = null;
            _selectedVietnamese = null;
          });
        }
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎉 Hoàn thành!',
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LexiColors.mint100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 50,
                color: LexiColors.mint600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Điểm số: $_score',
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: LexiColors.sky600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã nối đúng tất cả các từ!',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LexiColors.slate600,
              ),
              textAlign: TextAlign.center,
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
              _restartGame();
            },
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    final pairs = _englishWords; // vẫn giữ danh sách gốc
    final englishSide = List<_WordPair>.from(pairs)..shuffle();
    final vietnameseSide = List<_WordPair>.from(pairs)..shuffle();

    setState(() {
      _englishWords = englishSide;
      _vietnameseWords = vietnameseSide;
      _matchedIds.clear();
      _score = 0;
      _selectedEnglish = null;
      _selectedVietnamese = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Flashcard>>(
      stream: _deckService.watchFlashcards(widget.deckId),
      builder: (context, snapshot) {
        if (snapshot.hasData && _englishWords.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadWords(snapshot.data!);
          });
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            _englishWords.isEmpty) {
          return Scaffold(
            backgroundColor: LexiColors.sky50,
            appBar: AppBar(
              title: Text(
                widget.deckTitle,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: LexiColors.sky50,
          appBar: AppBar(
            title: Text(
              widget.deckTitle,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInstructions(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildWordColumn(
                            words: _englishWords,
                            isEnglish: true,
                            selectedId: _selectedEnglish,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildWordColumn(
                            words: _vietnameseWords,
                            isEnglish: false,
                            selectedId: _selectedVietnamese,
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
      },
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LexiColors.sky100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LexiColors.sky200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LexiColors.sky400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nhấn vào từ tiếng Anh và nghĩa tiếng Việt tương ứng để nối',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: LexiColors.sky800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordColumn({
    required List<_WordPair> words,
    required bool isEnglish,
    required String? selectedId,
  }) {
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        final isMatched = _matchedIds.contains(word.id);
        final isSelected = selectedId == word.id;
        final text = isEnglish ? word.english : word.vietnamese;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: isMatched
                ? null
                : () => isEnglish
                      ? _onEnglishTap(word.id)
                      : _onVietnameseTap(word.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMatched
                    ? LexiColors.mint100
                    : isSelected
                    ? LexiColors.sky400
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMatched
                      ? LexiColors.mint400
                      : isSelected
                      ? LexiColors.sky600
                      : LexiColors.sky100,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: LexiColors.sky400.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  if (isMatched)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: LexiColors.mint600,
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isMatched
                            ? LexiColors.mint800
                            : isSelected
                            ? Colors.white
                            : LexiColors.slate800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WordPair {
  final String id;
  final String english;
  final String vietnamese;

  _WordPair({
    required this.id,
    required this.english,
    required this.vietnamese,
  });
}
