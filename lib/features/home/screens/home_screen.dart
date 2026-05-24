import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_vocabulary/core/themes/app_theme.dart';
import 'package:king_vocabulary/features/auth/services/auth_service.dart';
import 'package:king_vocabulary/features/flashcards/screens/create_deck_screen.dart';
import 'package:king_vocabulary/features/flashcards/screens/list_vocabulary_screen.dart';
import 'package:king_vocabulary/features/flashcards/services/deck_service.dart';
import 'package:king_vocabulary/features/flashcards/models/flash_card_deck.dart';
import 'package:king_vocabulary/app.dart'; // Import để dùng routeObserver

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  final user = AuthService().currentUser;
  final _deckService = DeckService();
  bool _isUpdatingCounts = false;

  @override
  void initState() {
    super.initState();
    // Lắng nghe lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Cập nhật learnedCount khi vào màn hình (chỉ chạy 1 lần)
    _updateLearnedCountsOnce();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi app quay về foreground, refresh data
    if (state == AppLifecycleState.resumed) {
      _updateLearnedCountsOnce();
    }
  }

  @override
  void didPopNext() {
    // Được gọi khi pop về màn hình này từ màn hình khác
    debugPrint('🔄 HomeScreen: didPopNext - Refreshing data...');
    _updateLearnedCountsOnce();
  }

  Future<void> _updateLearnedCountsOnce() async {
    if (_isUpdatingCounts) return;

    setState(() => _isUpdatingCounts = true);

    try {
      await _deckService.updateAllLearnedCounts();
    } catch (e) {
      // Ignore errors, không ảnh hưởng đến UI
      debugPrint('Error updating learned counts: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingCounts = false);
      }
    }
  }

  // ── Callbacks (wire up khi có service) ──────────────────────────────────────
  Future<void> _onCreateDeck(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateDeckScreen()),
    );

    // Nếu có kết quả trả về (deck mới được tạo), refresh
    if (result != null && mounted) {
      // StreamBuilder sẽ tự động cập nhật
      setState(() {}); // Trigger rebuild để đảm bảo
    }
  }

  void _onStudyDeck(BuildContext context) {
    // TODO: mở màn hình chọn bộ từ để học
  }

  void _onReviewForgetting(BuildContext context) {
    // TODO: mở màn hình ôn lại từ sắp quên (spaced repetition)
  }

  Future<void> _onDeckTap(
    BuildContext context,
    String deckId,
    String deckTitle,
  ) async {
    // TODO: mở chi tiết bộ từ
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListVocabularyScreen(deckId: deckId, deckTitle: deckTitle),
      ),
    );

    // Khi quay về, refresh để cập nhật learnedCount
    if (mounted) {
      setState(() {}); // Trigger rebuild
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LexiColors.sky50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 4),
                  _buildReviewBanner(context),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Hành động nhanh'),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Bộ từ của bạn'),
                  const SizedBox(height: 12),
                  _buildDeckList(context),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: LexiColors.sky50,
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: LexiColors.sky400,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'King Vocabulary',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: LexiColors.slate800,
                ),
              ),
              Text(
                'Xin chào ${user?.displayName ?? 'User'} 👋',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: LexiColors.slate400,
                ),
              ),
            ],
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
              Icons.notifications_none_rounded,
              size: 18,
              color: LexiColors.sky600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Review banner (ôn từ sắp quên) ─────────────────────────────────────────
  Widget _buildReviewBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _onReviewForgetting(context),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⏰  Nhắc nhở hôm nay',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '24 từ sắp quên',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ôn ngay để không mất công học lại!',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ───────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.add_rounded,
            iconBg: LexiColors.sky100,
            iconColor: LexiColors.sky600,
            label: 'Tạo bộ từ',
            sublabel: 'Bộ từ mới',
            onTap: () => _onCreateDeck(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.play_arrow_rounded,
            iconBg: LexiColors.mint100,
            iconColor: LexiColors.mint600,
            label: 'Học ngay',
            sublabel: 'Chọn bộ từ',
            onTap: () => _onStudyDeck(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.refresh_rounded,
            iconBg: LexiColors.lav100,
            iconColor: LexiColors.lav600,
            label: 'Ôn lại',
            sublabel: 'Sắp quên',
            onTap: () => _onReviewForgetting(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LexiColors.sky100),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: LexiColors.slate800,
              ),
            ),
            Text(
              sublabel,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: LexiColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Deck list ───────────────────────────────────────────────────────────────
  Widget _buildDeckList(BuildContext context) {
    return StreamBuilder<List<FlashcardDeck>>(
      stream: _deckService.watchDecks(), // ← Dùng stream thông thường
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error
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

        // Empty
        final decks = snapshot.data ?? [];
        if (decks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LexiColors.sky100),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: LexiColors.sky100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: LexiColors.sky400,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bộ từ nào',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: LexiColors.slate800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tạo bộ từ đầu tiên để bắt đầu học!',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LexiColors.slate400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _onCreateDeck(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tạo bộ từ mới'),
                  ),
                ),
              ],
            ),
          );
        }

        // Render deck list
        return Column(
          children: decks
              .map(
                (deck) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _onDeckTap(context, deck.deckId, deck.title),
                    child: _buildDeckCard(context, deck),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildDismissibleDeckCard(
    BuildContext context,
    FlashcardDeck deck, {
    required String deckTitle,
  }) {
    return Dismissible(
      key: Key(deck.deckId),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {
        DismissDirection.endToStart: 0.3, // Giảm threshold để dễ swipe hơn
      },
      movementDuration: const Duration(milliseconds: 200),
      onUpdate: (details) {
        // Debug: xem có nhận được swipe gesture không
        debugPrint('📱 Swipe progress: ${details.progress}');
      },
      confirmDismiss: (direction) async {
        debugPrint('✅ Swipe completed! Showing dialog...');
        // Hiển thị dialog xác nhận
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Xóa bộ từ?',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: LexiColors.slate800,
              ),
            ),
            content: Text(
              'Bạn có chắc muốn xóa "$deckTitle"?\n\nTất cả ${deck.totalFlashcardCount} từ bên trong sẽ bị xóa vĩnh viễn.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LexiColors.slate600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
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
                onPressed: () => Navigator.pop(context, true),
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
      onDismissed: (direction) async {
        debugPrint('🗑️ Deleting deck: $deckTitle');
        // Xóa bộ từ
        try {
          await _deckService.deleteDeck(deck.deckId);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Đã xóa "$deckTitle"',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                ),
                backgroundColor: LexiColors.mint600,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Error deleting: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '❌ Lỗi: $e',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                ),
                backgroundColor: LexiColors.red600,
              ),
            );
          }
        }
      },
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onDeckTap(context, deck.deckId, deck.title),
          onLongPress: () {
            // Long press để xóa (backup method)
            debugPrint('🔴 Long press detected');
            showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Xóa bộ từ?',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: LexiColors.slate800,
                  ),
                ),
                content: Text(
                  'Bạn có chắc muốn xóa "$deckTitle"?\n\nTất cả ${deck.totalFlashcardCount} từ bên trong sẽ bị xóa vĩnh viễn.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LexiColors.slate600,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await _deckService.deleteDeck(deck.deckId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ Đã xóa "$deckTitle"',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: LexiColors.mint600,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '❌ Lỗi: $e',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: LexiColors.red600,
                            ),
                          );
                        }
                      }
                    },
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
          borderRadius: BorderRadius.circular(16),
          child: _buildDeckCard(context, deck),
        ),
      ),
    );
  }

  Widget _buildDeckCard(BuildContext context, FlashcardDeck deck) {
    // Tính progress (tạm thời dùng 0 vì chưa có thông tin learned)
    final progress = deck.totalFlashcardCount > 0
        ? deck.learnedCount / deck.totalFlashcardCount
        : 0.0;

    // Chọn màu dựa trên index (đơn giản)
    final colors = [LexiColors.sky400, LexiColors.mint400, LexiColors.lav400];
    final color = colors[deck.deckId.hashCode % colors.length];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LexiColors.sky100),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: LexiColors.slate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${deck.learnedCount}/${deck.totalFlashcardCount} từ',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: LexiColors.slate400,
                  ),
                ),
                if (deck.totalFlashcardCount > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: LexiColors.sky100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Thêm nút xóa trực tiếp
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: LexiColors.red400,
            ),
            onPressed: () async {
              // Hiển thị dialog xác nhận
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Xóa bộ từ?',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: LexiColors.slate800,
                    ),
                  ),
                  content: Text(
                    'Bạn có chắc muốn xóa "${deck.title}"?\n\nTất cả ${deck.totalFlashcardCount} từ bên trong sẽ bị xóa vĩnh viễn.',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: LexiColors.slate600,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
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
                      onPressed: () => Navigator.pop(context, true),
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

              if (confirm == true) {
                try {
                  debugPrint('🗑️ Deleting deck: ${deck.deckId}');
                  await _deckService.deleteDeck(deck.deckId);
                  debugPrint('✅ Deck deleted successfully');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Đã xóa "${deck.title}"',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: LexiColors.mint600,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('❌ Error deleting deck: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '❌ Lỗi: $e',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: LexiColors.red600,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────────────
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
