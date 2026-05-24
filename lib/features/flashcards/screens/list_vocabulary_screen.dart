import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_vocabulary/core/themes/app_theme.dart';
import 'package:king_vocabulary/features/flashcards/models/flash_card.dart';
import 'package:king_vocabulary/features/flashcards/screens/add_vocabulary_screen.dart';
import 'package:king_vocabulary/features/flashcards/services/deck_service.dart';
import 'package:king_vocabulary/features/learning/screens/learning_mode_screen.dart';

class ListVocabularyScreen extends StatefulWidget {
  final String deckId;
  final String deckTitle;

  const ListVocabularyScreen({
    super.key,
    required this.deckId,
    required this.deckTitle,
  });

  @override
  State<ListVocabularyScreen> createState() => _ListVocabularyScreenState();
}

class _ListVocabularyScreenState extends State<ListVocabularyScreen> {
  final _deckService = DeckService();

  // ── Callbacks ────────────────────────────────────────────────────────────────
  void _onAddVocabulary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVocabularyScreen(
          deckId: widget.deckId,
          deckTitle: widget.deckTitle,
        ),
      ),
    );
  }

  void _onEditCard(Flashcard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditVocabSheet(
        card: card,
        onSave: (front, back) async {
          await _deckService.updateFlashcard(
            widget.deckId,
            card.flashcardId,
            frontContent: front,
            backContent: back,
          );
        },
      ),
    );
  }

  void _onDeleteCard(Flashcard card) {
    _deckService.deleteFlashcard(widget.deckId, card.flashcardId);
  }

  void _onStudy(int totalWorlds) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningModeScreen(
          deckId: widget.deckId,
          deckTitle: widget.deckTitle,
          totalWords: totalWorlds,
        ),
        // StudyScreen(deckId: widget.deckId, deckTitle: widget.deckTitle),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Flashcard>>(
      stream: _deckService.watchFlashcards(widget.deckId),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: LexiColors.sky50,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, cards.length),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 4),
                      _buildStatsRow(cards),
                      const SizedBox(height: 20),
                      _buildStudyButton(cards.length),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Danh sách từ vựng'),
                      const SizedBox(height: 12),
                      _buildVocabularyList(cards, snapshot),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, int totalCount) {
    return SliverAppBar(
      backgroundColor: LexiColors.sky50,
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: LexiColors.sky100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: LexiColors.sky600,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.deckTitle,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: LexiColors.slate800,
            ),
          ),
          Text(
            '$totalCount từ vựng',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: LexiColors.slate400,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: LexiColors.sky100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: LexiColors.sky600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(List<Flashcard> cards) {
    final now = DateTime.now();
    final learned = cards.where((c) => c.reviewCount > 0).length;
    final due = cards
        .where((c) => c.nextReviewAt != null && c.nextReviewAt!.isBefore(now))
        .length; // 👈

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.style_rounded,
            iconBg: LexiColors.sky100,
            iconColor: LexiColors.sky600,
            value: '${cards.length}',
            label: 'Tổng từ',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline_rounded,
            iconBg: LexiColors.mint100,
            iconColor: LexiColors.mint600,
            value: '$learned',
            label: 'Đã học',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.loop_rounded,
            iconBg: LexiColors.lav100,
            iconColor: LexiColors.lav600,
            value: '$due',
            label: 'Cần ôn',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LexiColors.sky100),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: LexiColors.slate800,
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
      ),
    );
  }

  // ── Study Button ─────────────────────────────────────────────────────────────
  Widget _buildStudyButton(int totalCount) {
    return GestureDetector(
      onTap: () => _onStudy(totalCount),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LexiColors.sky500, LexiColors.sky400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: LexiColors.sky400.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bắt đầu học',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Học tất cả $totalCount từ trong bộ này',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── Vocabulary List ──────────────────────────────────────────────────────────
  Widget _buildVocabularyList(
    List<Flashcard> cards,
    AsyncSnapshot<List<Flashcard>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LexiColors.red50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LexiColors.red100),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: LexiColors.red600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LexiColors.red600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (cards.isEmpty) return _buildEmptyState();

    return Column(
      children: cards
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildVocabCard(entry.value, entry.key),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LexiColors.sky100),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: LexiColors.sky100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.translate_rounded,
              color: LexiColors.sky400,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có từ nào',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: LexiColors.slate800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thêm từ vựng đầu tiên vào bộ từ này!',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LexiColors.slate400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onAddVocabulary,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm từ vựng'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabCard(Flashcard card, int index) {
    final colors = [LexiColors.sky400, LexiColors.mint400, LexiColors.lav400];
    final color = colors[index % colors.length];

    return Dismissible(
      key: Key(card.flashcardId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Xóa từ này?',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: LexiColors.slate800,
              ),
            ),
            content: Text(
              'Bạn có chắc muốn xóa "${card.frontContent}"?',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LexiColors.slate600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Hủy',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LexiColors.slate500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Xóa',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LexiColors.red600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _onDeleteCard(card),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: LexiColors.red400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: InkWell(
        onTap: () => _onEditCard(card),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LexiColors.sky100),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.frontContent,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: LexiColors.slate800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.backContent,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: LexiColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: LexiColors.slate300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _onAddVocabulary,
      backgroundColor: LexiColors.sky500,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: LexiColors.slate600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _EditVocabSheet extends StatefulWidget {
  final Flashcard card;
  final Future<void> Function(String front, String back) onSave;

  const _EditVocabSheet({required this.card, required this.onSave});

  @override
  State<_EditVocabSheet> createState() => _EditVocabSheetState();
}

class _EditVocabSheetState extends State<_EditVocabSheet> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card.frontContent);
    _backController = TextEditingController(text: widget.card.backContent);
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();

    if (front.isEmpty || back.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSave(front, back);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 24, // 👈 tránh bàn phím
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LexiColors.slate200,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chỉnh sửa từ vựng',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: LexiColors.slate800,
            ),
          ),
          const SizedBox(height: 16),
          // Front
          TextFormField(
            controller: _frontController,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Từ tiếng Anh',
              prefixIcon: const Icon(
                Icons.text_fields_rounded,
                size: 18,
                color: LexiColors.sky400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Back
          TextFormField(
            controller: _backController,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Nghĩa tiếng Việt',
              prefixIcon: const Icon(
                Icons.translate_rounded,
                size: 18,
                color: LexiColors.mint600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _onSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }
}
