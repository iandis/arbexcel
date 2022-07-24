import 'dart:io';

import 'package:path/path.dart';

/// To match all args from a text.
final RegExp _kRegArgs = RegExp(r'{(\w+)}');

/// Parses .arb files to [Translation].
/// The [filename] is the main language.
Translation parseARB(String filename) {
  throw UnimplementedError();
}

/// Writes [Translation] to .arb files.
void writeARB(String filename, Translation data) {
  for (int i = 0; i < data.languages.length; i++) {
    final String lang = data.languages[i];
    final bool isDefault = i == 0;
    final File f = File('${withoutExtension(filename)}_$lang.arb');

    List<String> buf = [];
    for (final item in data.items) {
      final String? data = item.toJSON(lang, isDefault);
      if (data != null) {
        buf.add(data);
      }
    }

    buf = ['{', buf.join(',\n'), '}\n'];
    f.writeAsStringSync(buf.join('\n'));
  }
}

/// Describes an ARB record.
class ARBItem {
  static List<String> getArgs(String text) {
    final List<String> args = [];
    final Iterable<RegExpMatch> matches = _kRegArgs.allMatches(text);
    for (final RegExpMatch m in matches) {
      final String? arg = m.group(1);
      if (arg != null) {
        args.add(arg);
      }
    }

    return args;
  }

  const ARBItem({
    required this.name,
    this.description,
    this.translations = const <String, String>{},
  });

  final String name;
  final String? description;
  final Map<String, String> translations;

  /// Serialize in JSON.
  String? toJSON(String lang, [bool isDefault = false]) {
    final String? value = translations[lang];
    if (value == null || value.isEmpty) return null;

    final List<String> args = getArgs(value);
    final bool hasMetadata =
        isDefault && (args.isNotEmpty || description != null);

    final List<String> buf = <String>[];

    if (hasMetadata) {
      buf.add('  "$name": "$value",');
      buf.add('  "@$name": {');

      if (args.isEmpty) {
        if (description != null) {
          buf.add('    "description": "$description"');
        }
      } else {
        if (description != null) {
          buf.add('    "description": "$description",');
        }

        buf.add('    "placeholders": {');
        final List<String> group = [];
        for (final arg in args) {
          group.add('      "$arg": {"type": "String"}');
        }
        buf.add(group.join(',\n'));
        buf.add('    }');
      }

      buf.add('  }');
    } else {
      buf.add('  "$name": "$value"');
    }

    return buf.join('\n');
  }
}

/// Describes all arb records.
class Translation {
  const Translation({
    this.languages = const <String>[],
    this.items = const <ARBItem>[],
  });

  final List<String> languages;
  final List<ARBItem> items;
}
