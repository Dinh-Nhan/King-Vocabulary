import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:king_vocabulary/core/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/manual_input_result.dart';
import '../services/import_service.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _deckNameController = TextEditingController();
  final _manualInputService = ManualInputService();

  bool _isSaving = false;
  String? _errorMessage;

  // Entries từ import tab, truyền xuống _ManualInputTab qua constructor
  List<({String front, String back})>? _pendingImportEntries;

  // Key để truy cập state của tab Manual Input
  final _manualTabKey = GlobalKey<_ManualInputTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _deckNameController.dispose();
    super.dispose();
  }

  // ── Lưu bộ từ ───────────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    final deckName = _deckNameController.text.trim();

    if (deckName.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên bộ từ');
      return;
    }

    // Chỉ xử lý tab Manual Input (tab 0)
    if (_tabController.index == 0) {
      final entries = _manualTabKey.currentState?.getEntries() ?? [];

      if (entries.isEmpty) {
        setState(() => _errorMessage = 'Vui lòng thêm ít nhất 1 từ');
        return;
      }

      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      try {
        final result = await _manualInputService.createDeckWithWords(
          title: deckName,
          entries: entries,
        );

        if (!mounted) return;

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Đã lưu ${result.savedCount} từ${result.skippedCount > 0 ? ' (bỏ qua ${result.skippedCount} từ trống)' : ''}',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
            ),
            backgroundColor: LexiColors.mint600,
          ),
        );

        // Quay về màn hình trước
        Navigator.pop(context, result.deck);
      } on FirebaseException catch (e) {
        debugPrint('🔥 Firebase Error Code: ${e.code}');
        debugPrint('🔥 Firebase Error Message: ${e.message}');
        debugPrint('🔥 Firebase Error Plugin: ${e.plugin}');

        String errorMsg = 'Lỗi Firebase: ${e.code}';
        if (e.code == 'permission-denied') {
          errorMsg =
              'Không có quyền truy cập Firestore. Vui lòng kiểm tra Firestore Rules.';
        } else if (e.code == 'unavailable') {
          errorMsg =
              'Không thể kết nối Firestore. Kiểm tra internet hoặc Firestore đã được kích hoạt chưa.';
        } else if (e.message != null) {
          errorMsg = e.message!;
        }

        setState(() => _errorMessage = errorMsg);
      } catch (e) {
        debugPrint('❌ Unknown Error: $e');
        setState(() => _errorMessage = e.toString());
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      // Tab Import — không cần xử lý, import tab tự chuyển sang tab nhập tay
      setState(
        () => _errorMessage =
            'Vui lòng dùng tab Import để tải file, sau đó kiểm tra và nhấn Lưu',
      );
    }
  }

  /// Nhận entries từ _ImportTab → nạp vào _ManualInputTab → chuyển sang tab 0
  void _onImported(List<({String front, String back})> entries) {
    setState(() => _pendingImportEntries = entries);
    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Đã tải ${entries.length} từ — kiểm tra và chỉnh sửa trước khi lưu',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        backgroundColor: LexiColors.sky600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LexiColors.sky50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 8),
            ],
            _buildDeckNameField(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ManualInputTab(
                    key: _manualTabKey,
                    importedEntries: _pendingImportEntries,
                  ),
                  _ImportTab(onImported: _onImported),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error banner ────────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: LexiColors.red50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: LexiColors.red100),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: LexiColors.red600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LexiColors.red600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: LexiColors.sky100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: LexiColors.sky600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tạo bộ từ mới',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: LexiColors.slate800,
              ),
            ),
          ),
          GestureDetector(
            onTap: _isSaving ? null : _onSave,
            child: AnimatedOpacity(
              opacity: _tabController.index == 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: _tabController.index != 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isSaving ? LexiColors.slate300 : LexiColors.sky400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 40,
                          height: 16,
                          child: Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'Lưu',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Deck name ───────────────────────────────────────────────────────────────
  Widget _buildDeckNameField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextFormField(
        controller: _deckNameController,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: LexiColors.slate800,
        ),
        decoration: InputDecoration(
          hintText: 'Tên bộ từ, ví dụ: TOEIC 600+',
          hintStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: LexiColors.slate400,
          ),
          prefixIcon: const Icon(
            Icons.menu_book_rounded,
            size: 18,
            color: LexiColors.sky400,
          ),
        ),
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: LexiColors.sky100,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: LexiColors.sky200.withValues(alpha: 0.6),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          labelColor: LexiColors.sky600,
          unselectedLabelColor: LexiColors.slate400,
          tabs: const [
            Tab(text: '✏️  Nhập tay'),
            Tab(text: '📂  Import file'),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 1 — NHẬP TAY
// ════════════════════════════════════════════════════════════════════════════
class _ManualInputTab extends StatefulWidget {
  final List<({String front, String back})>? importedEntries;

  const _ManualInputTab({super.key, this.importedEntries});

  @override
  State<_ManualInputTab> createState() => _ManualInputTabState();
}

class _ManualInputTabState extends State<_ManualInputTab> {
  final List<_WordEntry> _entries = [_WordEntry(), _WordEntry()];

  @override
  void didUpdateWidget(_ManualInputTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.importedEntries != null &&
        widget.importedEntries != oldWidget.importedEntries) {
      _loadEntries(widget.importedEntries!);
    }
  }

  void _loadEntries(List<({String front, String back})> imported) {
    setState(() {
      for (final e in _entries) {
        e.wordController.dispose();
        e.meaningController.dispose();
      }
      _entries.clear();

      for (final item in imported) {
        final entry = _WordEntry();
        entry.wordController.text = item.front;
        entry.meaningController.text = item.back;
        _entries.add(entry);
      }

      // Dòng trống ở cuối để user thêm từ mới
      _entries.add(_WordEntry());
    });
  }

  void _addEntry() {
    setState(() => _entries.add(_WordEntry()));
  }

  void _removeEntry(int index) {
    if (_entries.length <= 1) return;
    setState(() => _entries.removeAt(index));
  }

  List<({String front, String back})> getEntries() {
    return _entries
        .map(
          (e) => (
            front: e.wordController.text.trim(),
            back: e.meaningController.text.trim(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            itemCount: _entries.length,
            itemBuilder: (context, index) => _buildWordCard(index),
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildWordCard(int index) {
    final entry = _entries[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LexiColors.sky100),
      ),
      child: Column(
        children: [
          // Header số thứ tự + nút xóa
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 0),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: LexiColors.sky100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: LexiColors.sky600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (_entries.length > 1)
                  GestureDetector(
                    onTap: () => _removeEntry(index),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: LexiColors.slate300,
                    ),
                  ),
              ],
            ),
          ),
          // Từ
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: _buildInlineField(
              controller: entry.wordController,
              hint: 'Từ tiếng Anh',
              icon: Icons.text_fields_rounded,
              iconColor: LexiColors.sky400,
            ),
          ),
          // Nghĩa
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: _buildInlineField(
              controller: entry.meaningController,
              hint: 'Nghĩa tiếng Việt',
              icon: Icons.translate_rounded,
              iconColor: LexiColors.mint600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: LexiColors.slate800,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: LexiColors.slate300,
        ),
        prefixIcon: Icon(icon, size: 16, color: iconColor),
        filled: true,
        fillColor: LexiColors.sky50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: LexiColors.sky100, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: LexiColors.sky100, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: LexiColors.sky400, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: OutlinedButton.icon(
        onPressed: _addEntry,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Thêm từ mới'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }
}

// Model cho mỗi hàng từ
class _WordEntry {
  final wordController = TextEditingController();
  final meaningController = TextEditingController();
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 2 — IMPORT FILE
// ════════════════════════════════════════════════════════════════════════════
class _ImportTab extends StatefulWidget {
  final void Function(List<({String front, String back})> entries) onImported;

  const _ImportTab({required this.onImported});

  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab> {
  final _quizletController = TextEditingController();
  final _pasteController = TextEditingController();

  final _importService = ImportService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _quizletController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  // ── Gọi service pick file ───────────────────────────────────────────────────
  Future<void> _onPickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final importResult = await _importService.pickAndParseFile();

      if (!mounted) return;

      if (importResult == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (importResult.entries.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Không tìm thấy từ nào trong file "${importResult.fileName}".\nKiểm tra định dạng: mỗi dòng gồm "từ - nghĩa".';
        });
        return;
      }

      setState(() => _isLoading = false);
      widget.onImported(importResult.entries);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi đọc file: $e';
        });
      }
    }
  }

  // ── Quizlet — chưa có service ───────────────────────────────────────────────
  void _onImportQuizlet() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chức năng nhập từ Quizlet đang được phát triển',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        backgroundColor: LexiColors.lav600,
      ),
    );
  }

  // ── Gọi service parse paste text ───────────────────────────────────────────
  Future<void> _onPasteImport() async {
    final text = _pasteController.text.trim();

    if (text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng dán nội dung vào ô văn bản');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = _importService.parsePasteText(text);

      if (!mounted) return;

      if (entries.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Không phân tích được từ nào.\nKiểm tra định dạng: mỗi dòng gồm "từ - nghĩa".';
        });
        return;
      }

      setState(() => _isLoading = false);
      widget.onImported(entries);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi phân tích: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),

          // Error banner
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: LexiColors.red50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: LexiColors.red100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: LexiColors.red600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LexiColors.red600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: LexiColors.red400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildImportOption(
            icon: Icons.upload_file_rounded,
            iconBg: LexiColors.sky100,
            iconColor: LexiColors.sky600,
            title: 'Tải lên file',
            subtitle: '.csv · .txt · .xlsx',
            pill: _buildPill(
              'Nhanh nhất',
              LexiColors.sky100,
              LexiColors.sky700,
            ),
            onTap: _onPickFile,
            child: _buildFilePickArea(),
          ),
          const SizedBox(height: 12),
          _buildImportOption(
            icon: Icons.link_rounded,
            iconBg: LexiColors.lav100,
            iconColor: LexiColors.lav600,
            title: 'Nhập từ Quizlet',
            subtitle: 'Dán link bộ từ Quizlet công khai',
            pill: _buildPill('Phổ biến', LexiColors.lav100, LexiColors.lav600),
            onTap: null,
            child: _buildQuizletInput(),
          ),
          const SizedBox(height: 12),
          _buildImportOption(
            icon: Icons.content_paste_rounded,
            iconBg: LexiColors.mint100,
            iconColor: LexiColors.mint600,
            title: 'Dán văn bản',
            subtitle: 'Paste nội dung, app tự phân tích',
            pill: null,
            onTap: null,
            child: _buildPasteArea(),
          ),
        ],
      ),
    );
  }

  // ── Option card ─────────────────────────────────────────────────────────────
  Widget _buildImportOption({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget? pill,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LexiColors.sky100),
      ),
      child: Column(
        children: [
          // Row header
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: LexiColors.slate800,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: LexiColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?pill,
                ],
              ),
            ),
          ),
          // Divider
          const Divider(height: 1, color: LexiColors.sky100),
          // Content
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  // ── File pick area ──────────────────────────────────────────────────────────
  Widget _buildFilePickArea() {
    return GestureDetector(
      onTap: _onPickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: LexiColors.sky50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LexiColors.sky200,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: LexiColors.sky300,
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn để chọn file',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: LexiColors.sky600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '.csv · .txt · .xlsx',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: LexiColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quizlet input ───────────────────────────────────────────────────────────
  Widget _buildQuizletInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hướng dẫn
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: LexiColors.sky50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LexiColors.sky100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cách lấy link từ Quizlet',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: LexiColors.sky700,
                ),
              ),
              const SizedBox(height: 8),
              _buildStep('1', 'Mở bộ từ trên Quizlet (chế độ Public)'),
              _buildStep('2', 'Nhấn Share → Copy link'),
              _buildStep('3', 'Dán link vào ô bên dưới'),
            ],
          ),
        ),
        // Input link
        TextFormField(
          controller: _quizletController,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LexiColors.slate800,
          ),
          decoration: InputDecoration(
            hintText: 'quizlet.com/vn/123456789/...',
            hintStyle: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LexiColors.slate300,
            ),
            prefixIcon: const Icon(
              Icons.link_rounded,
              size: 16,
              color: LexiColors.lav400,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _onImportQuizlet,
            child: const Text('Nhập bộ từ từ Quizlet'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: LexiColors.sky200,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: LexiColors.sky800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: LexiColors.slate700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Paste area ──────────────────────────────────────────────────────────────
  Widget _buildPasteArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _pasteController,
          maxLines: 5,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LexiColors.slate800,
          ),
          decoration: InputDecoration(
            hintText:
                'Dán nội dung vào đây...\nví dụ:\napple - quả táo\nbanana - quả chuối',
            hintStyle: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LexiColors.slate300,
            ),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: LexiColors.sky200,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: LexiColors.sky200,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: LexiColors.sky400,
                width: 1.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _onPasteImport,
            child: const Text('Phân tích & Nhập'),
          ),
        ),
      ],
    );
  }

  // ── Pill badge ──────────────────────────────────────────────────────────────
  Widget _buildPill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
