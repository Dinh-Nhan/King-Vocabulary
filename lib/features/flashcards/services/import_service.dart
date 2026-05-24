import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

class ImportResult {
  final List<({String front, String back})> entries;
  final String fileName;

  const ImportResult({required this.entries, required this.fileName});
}

class ImportService {
  Future<ImportResult?> pickAndParseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;

    // Guard: tránh crash khi cả bytes lẫn path đều null (thường xảy ra trên web)
    if (file.bytes == null && file.path == null) return null;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();

    final extension = file.extension?.toLowerCase();

    final entries = switch (extension) {
      'csv' => _parseCsv(bytes),
      'txt' => _parseTxt(bytes),
      'xlsx' => _parseXlsx(bytes),
      _ => <({String front, String back})>[],
    };

    return ImportResult(entries: entries, fileName: file.name);
  }

  List<({String front, String back})> parsePasteText(String text) {
    // Truyền thẳng String vào _parseTxtString thay vì convert qua codeUnits
    // để tránh lỗi Unicode với tiếng Việt có dấu
    return _parseTxtString(text);
  }

  List<({String front, String back})> _parseCsv(List<int> bytes) {
    final content = String.fromCharCodes(bytes);
    final rows = const CsvToListConverter().convert(content);
    return rows
        .where((row) => row.length >= 2)
        .map(
          (row) =>
              (front: row[0].toString().trim(), back: row[1].toString().trim()),
        )
        .where((e) => e.front.isNotEmpty && e.back.isNotEmpty)
        .toList();
  }

  List<({String front, String back})> _parseTxt(List<int> bytes) {
    final content = String.fromCharCodes(bytes);
    return _parseTxtString(content);
  }

  List<({String front, String back})> _parseTxtString(String content) {
    final lines = content.split('\n');
    final entries = <({String front, String back})>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      String? front, back;

      if (trimmed.contains(' - ')) {
        final parts = trimmed.split(' - ');
        front = parts[0].trim();
        back = parts.sublist(1).join(' - ').trim();
      } else if (trimmed.contains(': ')) {
        final parts = trimmed.split(': ');
        front = parts[0].trim();
        back = parts.sublist(1).join(': ').trim();
      } else if (trimmed.contains('\t')) {
        final parts = trimmed.split('\t');
        front = parts[0].trim();
        back = parts[1].trim();
      } else if (trimmed.contains(',')) {
        final parts = trimmed.split(',');
        front = parts[0].trim();
        back = parts.sublist(1).join(',').trim();
      }

      if (front != null &&
          back != null &&
          front.isNotEmpty &&
          back.isNotEmpty) {
        entries.add((front: front, back: back));
      }
    }

    return entries;
  }

  List<({String front, String back})> _parseXlsx(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) return [];

    return sheet.rows
        .where((row) => row.length >= 2)
        .map(
          (row) => (
            front: row[0]?.value?.toString().trim() ?? '',
            back: row[1]?.value?.toString().trim() ?? '',
          ),
        )
        .where((e) => e.front.isNotEmpty && e.back.isNotEmpty)
        .toList();
  }
}
