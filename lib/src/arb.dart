import 'dart:convert';
import 'dart:io';

import 'package:arbxcel/src/predefined_placeholder.dart';
import 'package:path/path.dart';

/// To match all args from a text.
final RegExp _kRegArgs = RegExp(r'{(\w+)}');

final RegExp _kRegSelect = RegExp(r'{(\w+),\s*select\s*,.*}}');

final JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

/// Parses .arb files to [Translation].
/// The [filename] is the main language.
Translation parseARB(String filename) {
  throw UnimplementedError();
}

/// Writes [Translation] to .arb files.
void writeARB(String filename, Translation data) {
  for (int i = 0; i < data.languages.length; i++) {
    final String lang = data.languages[i];
    final File f = File('${withoutExtension(filename)}_$lang.arb');

    final StringBuffer buf = StringBuffer('{\n');
    for (int i = 0; i < data.items.length; i++) {
      final ARBItem item = data.items[i];
      final String? json = item.toJSON(lang, data.predefinedPlaceholderTable);
      if (json != null) {
        buf.write(json);
        if (i < data.items.length - 1) {
          buf.writeln(',');
        } else {
          buf.writeln();
        }
      }
    }
    buf.writeln('}');
    f.writeAsStringSync(buf.toString());
  }
}

/// Describes an ARB record.
class ARBItem {
  const ARBItem({
    required this.name,
    this.description,
    this.placeholders,
    this.translations = const <String, String>{},
  });

  final String name;
  final String? description;
  final String? placeholders;
  final Map<String, String> translations;

  static List<String> getArgs(String text) {
    final List<String> args = <String>[];

    final Iterable<RegExpMatch> selectMatches = _kRegSelect.allMatches(text);
    for (final RegExpMatch selectMatch in selectMatches) {
      final String selectArg = selectMatch.group(1)!;
      args.add(selectArg);
    }

    final String textNoSelect = text.replaceAll(_kRegSelect, '');
    final Iterable<RegExpMatch> matches = _kRegArgs.allMatches(textNoSelect);
    for (final RegExpMatch m in matches) {
      final String? arg = m.group(1);
      if (arg != null) {
        args.add(arg);
      }
    }

    return args;
  }

  /// Serialize in JSON.
  String? toJSON(String lang, PredefinedPlaceholderTable placeholderTable) {
    final String? value = translations[lang];
    if (value == null || value.isEmpty) return null;

    final List<String> args = getArgs(value);
    final bool hasMetadata = args.isNotEmpty || description != null;

    final StringBuffer buf = StringBuffer();
    String valueEscaped = json.encode(<String, String>{name: value});
    valueEscaped = valueEscaped.substring(1, valueEscaped.length - 1);
    valueEscaped = '  $valueEscaped';
    buf.write(valueEscaped);

    if (hasMetadata) {
      buf.writeln(',');
      buf.writeln('  "@$name": {');

      if (description != null) {
        buf.write('    "description": "$description"');
      }

      String? placeholders = this.placeholders;
      if (placeholders != null && placeholders.trim().isNotEmpty) {
        if (placeholderTable.isNotEmpty) {
          placeholders = _replacePlaceholderVariables(
            lang: lang,
            placeholder: placeholders,
            table: placeholderTable,
          );
        }

        if (description != null) {
          buf.writeln(',');
        }

        final Map<String, dynamic> placeholdersMap =
            json.decode(placeholders) as Map<String, dynamic>;
        for (final String arg in args) {
          placeholdersMap[arg] ??= const <String, String>{'type': 'String'};
        }
        final String placeholdersPretty = _prettyJson.convert(placeholdersMap);
        buf.writeln('    "placeholders": {');
        for (final String line in placeholdersPretty.split('\n')) {
          if (line == '{' || line == '}') continue;
          buf.writeln('    $line');
        }
        buf.writeln('    }');
      } else if (args.isNotEmpty) {
        if (description != null) {
          buf.writeln(',');
        }
        buf.writeln('    "placeholders": {');
        for (int i = 0; i < args.length; i++) {
          final String arg = args[i];
          buf.write('      "$arg": {"type": "String"}');
          if (i == args.length - 1) {
            buf.writeln();
          } else {
            buf.writeln(',');
          }
        }
        buf.writeln('    }');
      } else {
        buf.writeln();
      }

      buf.write('  }');
    }

    return buf.toString();
  }
}

String _replacePlaceholderVariables({
  required String lang,
  required String placeholder,
  required PredefinedPlaceholderTable table,
}) {
  final StringBuffer resultBuffer = StringBuffer();
  int previousCharCode = -1;
  bool hasFoundDollarSign = false;
  String placeholderVariable = '';

  void writeVariableValue() {
    if (placeholderVariable.isEmpty) return;
    final String? langValue = table[placeholderVariable]![lang];
    if (langValue == null) {
      throw UnimplementedError('No value for $placeholderVariable in $lang');
    }
    resultBuffer.write(langValue);
    placeholderVariable = '';
    hasFoundDollarSign = false;
  }

  void checkCharCode(int charCode) {
    if (charCode == dollarSignCharCode && !hasFoundDollarSign) {
      if (previousCharCode != escapeSignCharCode) {
        hasFoundDollarSign = true;
      } else {
        resultBuffer.writeCharCode(dollarSignCharCode);
      }
      return;
    }

    if (isAllowedVariableCharCode(charCode) && hasFoundDollarSign) {
      placeholderVariable += String.fromCharCode(charCode);
      return;
    }

    if (!isAllowedVariableCharCode(charCode) && hasFoundDollarSign) {
      writeVariableValue();
    }

    resultBuffer.writeCharCode(charCode);
  }

  for (final int charCode in placeholder.codeUnits) {
    checkCharCode(charCode);
    previousCharCode = charCode;
  }
  writeVariableValue();

  return resultBuffer.toString();
}

/// Describes all arb records.
class Translation {
  const Translation({
    this.languages = const <String>[],
    this.items = const <ARBItem>[],
    this.predefinedPlaceholderTable = const <String, Map<String, String>>{},
  });

  final List<String> languages;
  final List<ARBItem> items;
  final PredefinedPlaceholderTable predefinedPlaceholderTable;
}
