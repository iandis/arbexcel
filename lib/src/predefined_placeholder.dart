import 'package:excel/excel.dart';

const int _kRowHeader = 0;
const int _kRowValue = 1;
const int _kColKey = 0;

/// The key of the parent [Map] is the placeholder key.
/// The key of the child [Map] is the language code.
/// The value of the child [Map] is the placeholder value.
///
/// Example:
/// ```json
/// {
///   "date1": {
///     "id": "{\"type\":\"DateTime\", \"format\":\"DD/MM/YYYY\"}",
///     "en": "{\"type\":\"DateTime\", \"format\":\"YYYY/MM/DD\"}"
///   },
///   "date2": {
///     "id": "{\"type\":\"DateTime\", \"format\":\"DD MMMM YYYY\"}",
///     "en": "{\"type\":\"DateTime\", \"format\":\"MMMM DD, YYYY\"}"
///   }
/// }
/// ```
typedef PredefinedPlaceholderTable = Map<String, Map<String, String>>;

const int dollarSignCharCode = 36;
const int escapeSignCharCode = 92;

bool _isAlphanumericCharCode(int charCode) =>
    (charCode >= 48 && charCode <= 57) ||
    (charCode >= 65 && charCode <= 90) ||
    (charCode >= 97 && charCode <= 122);

bool _isUnderscoreCharCode(int charCode) => charCode == 95;

bool isAllowedVariableCharCode(int charCode) =>
    _isAlphanumericCharCode(charCode) || _isUnderscoreCharCode(charCode);

bool _isAllowedKeyCharCodes(String key) {
  for (int i = 0; i < key.length; i++) {
    if (!isAllowedVariableCharCode(key.codeUnitAt(i))) return false;
  }
  return true;
}

Map<String, Map<String, String>> getPredefinedPlaceholders({
  required String placeholderSheetname,
  required Excel excel,
}) {
  if (placeholderSheetname.isEmpty) {
    return const <String, Map<String, String>>{};
  }
  final Sheet? placeholderSheet = excel.sheets[placeholderSheetname];
  if (placeholderSheet == null) {
    return const <String, Map<String, String>>{};
  }

  final PredefinedPlaceholderTable table = <String, Map<String, String>>{};
  final List<List<Data?>> sheetRows = placeholderSheet.rows;
  final List<Data?> headerRows = sheetRows[_kRowHeader];
  for (int i = _kRowValue; i < sheetRows.length; i++) {
    final List<Data?> rows = sheetRows[i];
    final String key = (rows[_kColKey]?.value as String?)?.trim() ?? '';
    if (key.isEmpty) {
      throw FormatException('Key is empty at row ${i + 1}');
    }
    if (!_isAllowedKeyCharCodes(key)) {
      throw FormatException('Key contains invalid characters at row ${i + 1}');
    }
    if (rows.length < 2) {
      print('No value at row ${i + 1}\nIgnoring...');
      continue;
    }

    final Map<String, String> values = <String, String>{};
    for (int vi = 1; vi < rows.length; vi++) {
      final String langCode = (headerRows[vi]?.value as String?)?.trim() ?? '';
      final String value = (rows[vi]?.value as String?)?.trim() ?? '';
      if (langCode.isEmpty) {
        print('No language code at column ${vi + 1}\nIgnoring...');
        continue;
      }
      if (value.isEmpty) {
        print('No value at column ${vi + 1}\nIgnoring...');
        continue;
      }
      values[langCode] = value;
    }
    if (values.isEmpty) {
      print('No values for key $key\nIgnoring...');
      continue;
    }

    table[key] = values;
  }

  return table;
}
