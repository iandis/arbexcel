import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arbxcel/src/assets.dart';
import 'package:arbxcel/src/predefined_placeholder.dart';
import 'package:excel/excel.dart';

import 'arb.dart';

const int _kRowHeader = 0;
const int _kRowValue = 1;
const int _kColName = 0;
const int _kColDescription = 1;
const int _kColPlaceholders = 2;
const int _kColValue = 3;

/// Create a new Excel template file.
///
/// Embedded data will be packed via `template.dart`.
void newTemplate(String filename) {
  final Uint8List buf = base64Decode(kTemplate);
  File(filename).writeAsBytesSync(buf);
}

/// Reads Excel sheet.
///
/// Uses `arb_sheet -n path/to/file` to create a translation file
/// from the template.
Translation parseExcel({
  required String filename,
  required String sheetname,
  required String placeholderSheetname,
  int headerRow = _kRowHeader,
  int valueRow = _kRowValue,
}) {
  final Uint8List buf = File(filename).readAsBytesSync();
  final Excel excel = Excel.decodeBytes(buf);
  final Sheet? sheet = excel.sheets[sheetname];
  if (sheet == null) {
    return const Translation();
  }

  final List<ARBItem> items = <ARBItem>[];
  final List<List<Data?>> sheetRows = sheet.rows;
  final List<Data?> columns = sheetRows[headerRow];
  for (int i = valueRow; i < sheetRows.length; i++) {
    final List<Data?> row = sheetRows[i];
    final String? name = row[_kColName]?.value;
    if (name?.trim().isNotEmpty != true) continue;

    final String? description = row[_kColDescription]?.value;
    final String? placeholders = row[_kColPlaceholders]?.value;
    final Map<String, String> translations = <String, String>{};
    final ARBItem item = ARBItem(
      name: name!,
      description: description,
      placeholders: placeholders,
      translations: translations,
    );

    for (int i = _kColValue; i < sheet.maxCols; i++) {
      final lang = columns[i]?.value ?? i.toString();
      translations[lang] = row[i]?.value ?? '';
    }

    items.add(item);
  }

  final List<String> languages = columns
      .where((Data? e) => e != null && e.colIndex >= _kColValue)
      .map<String>((Data? e) => e?.value)
      .toList();
  final PredefinedPlaceholderTable table = getPredefinedPlaceholders(
    placeholderSheetname: placeholderSheetname,
    excel: excel,
  );

  return Translation(
    languages: languages,
    items: items,
    predefinedPlaceholderTable: table,
  );
}

/// Writes a Excel file, includes all translations.
void writeExcel(String filename, Translation data) {
  throw UnimplementedError();
}
