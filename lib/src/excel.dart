import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arbxcel/src/assets.dart';
import 'package:excel/excel.dart';

import 'arb.dart';

const int _kRowHeader = 0;
const int _kRowValue = 1;
const int _kColName = 0;
const int _kColDescription = 1;
const int _kColValue = 2;

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
  String sheetname = 'Text',
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
  final List<Data?> columns = sheet.rows[headerRow];
  for (int i = valueRow; i < sheet.rows.length; i++) {
    final List<Data?> row = sheet.rows[i];
    final ARBItem item = ARBItem(
      name: row[_kColName]?.value,
      description: row[_kColDescription]?.value,
      translations: {},
    );

    for (int i = _kColValue; i < sheet.maxCols; i++) {
      final lang = columns[i]?.value ?? i.toString();
      item.translations[lang] = row[i]?.value ?? '';
    }

    items.add(item);
  }

  final List<String> languages = columns
      .where((e) => e != null && e.colIndex >= _kColValue)
      .map<String>((e) => e?.value)
      .toList();
  return Translation(languages: languages, items: items);
}

/// Writes a Excel file, includes all translations.
void writeExcel(String filename, Translation data) {
  throw UnimplementedError();
}
