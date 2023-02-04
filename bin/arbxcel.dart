import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';

import 'package:arbxcel/arbxcel.dart';

const _kVersion = '0.0.2';

void main(List<String> args) {
  final ArgParser parse = ArgParser();
  parse.addFlag(
    'new',
    abbr: 'n',
    defaultsTo: false,
    help: 'New example translation sheet',
  );
  parse.addFlag(
    'arb',
    abbr: 'a',
    defaultsTo: false,
    help: 'Export to ARB files from an Excel file',
  );
  parse.addOption(
    'sheet',
    abbr: 's',
    defaultsTo: 'Main',
    help: 'Main sheet name',
  );
  parse.addOption(
    'placeholders',
    abbr: 'p',
    defaultsTo: '',
    help: 'Sheet name for predefined placeholders',
  );
  parse.addFlag(
    'excel',
    abbr: 'e',
    defaultsTo: false,
    help: 'Export to an Excel file from ARB files',
  );
  final ArgResults flags = parse.parse(args);

  // Not enough args
  if (args.length < 2) {
    usage(parse);
    exit(1);
  }

  final String filename = flags.rest.first;

  if (flags['new']) {
    stdout.writeln('Create new Excel file for translation: $filename');
    newTemplate(filename);
    exit(0);
  }

  if (flags['arb']) {
    stdout.writeln('Generate ARB from: $filename');
    final String sheetname = flags['sheet'];
    final String placeholderSheetname = flags['placeholders'];
    final Translation data = parseExcel(
      filename: filename,
      sheetname: sheetname,
      placeholderSheetname: placeholderSheetname,
    );
    writeARB('${withoutExtension(filename)}.arb', data);
    exit(0);
  }

  if (flags['excel']) {
    stdout.writeln('Generate Excel from: $filename');
    final Translation data = parseARB(filename);
    writeExcel('${withoutExtension(filename)}.xlsx', data);
    exit(0);
  }
}

void usage(ArgParser parse) {
  stdout.writeln('arb_sheet v$_kVersion\n');
  stdout.writeln('USAGE:');
  stdout.writeln(
    '  arb_sheet [OPTIONS] path/to/file/name\n',
  );
  stdout.writeln('OPTIONS');
  stdout.writeln(parse.usage);
}
