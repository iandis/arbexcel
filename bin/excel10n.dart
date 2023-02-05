import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

Future<void> main(List<String> args) async {
  final ArgParser argParser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addOption(
      'path',
      defaultsTo: 'lib/src/l10n',
      help: 'Path containing the localization files.',
    )
    ..addOption(
      'excel-source-file',
      abbr: 'e',
      defaultsTo: 'app.xlsx',
      help: 'Excel file for generating the localization files.',
    )
    ..addOption(
      'excel-main-sheet-name',
      abbr: 's',
      defaultsTo: 'Main',
      help: 'Target Excel main sheet name.',
    )
    ..addOption(
      'excel-placeholder-sheet-name',
      abbr: 'p',
      defaultsTo: '',
      help: 'Target Excel placeholder sheet name.',
    )
    ..addOption(
      'template-arb-file',
      abbr: 't',
      defaultsTo: 'app_en.arb',
      help: 'Template ARB file for generating the localization files.',
    )
    ..addOption(
      'output-localization-file',
      abbr: 'o',
      defaultsTo: 'app_localizations.dart',
      help: 'Output localization file for generating the localization files.',
    )
    ..addOption(
      'flutter-path',
      abbr: 'f',
      valueHelp: 'path/to/flutter/bin',
      help: 'Path to the flutter SDK.',
    );
  final ArgResults argResults = argParser.parse(args);

  if (argResults['help']) {
    showHelp(argParser);
  }

  final String path = argResults['path'];
  final String excelSourceFile = argResults['excel-source-file'];
  final String excelMainSheetName = argResults['excel-main-sheet-name'];
  final String excelPlaceholderSheetName =
      argResults['excel-placeholder-sheet-name'];
  final String templateArbFile = argResults['template-arb-file'];
  final String outputLocalizationFile = argResults['output-localization-file'];
  final String? flutterBin = argResults['flutter-path'];
  final String flutterPath;
  final String dartPath;
  if (flutterBin == null || flutterBin.trim().isEmpty) {
    flutterPath = 'flutter';
    dartPath = 'dart';
  } else {
    flutterPath = '$flutterBin/flutter';
    dartPath = '$flutterBin/dart';
  }

  checkPath(path);
  checkExcelSourceFile('$path/$excelSourceFile');
  checkExcelSheetName(excelMainSheetName);
  checkTemplateArbFileArg(templateArbFile);
  checkOutputLocalizationFile(outputLocalizationFile);
  checkFlutterPath(flutterPath);

  final String arbXcelTarget = '$path/$excelSourceFile';
  print('Running "arbxcel"...');
  await runArbXcel(
    flutterPath,
    arbXcelTarget,
    excelMainSheetName,
    excelPlaceholderSheetName,
  );
  checkTemplateArbFileExists('$path/$templateArbFile');
  print('Running "flutter gen-l10n"...');
  await runFlutterGenL10n(
    flutterPath,
    path,
    templateArbFile,
    outputLocalizationFile,
  );
  print('Removing .arb files...');
  deleteArbFiles(path);
  print('Formatting generated code...');
  await runDartFix(dartPath, path);
}

Never showHelp(ArgParser argParser) {
  print(argParser.usage);
  exit(0);
}

void checkPath(String path) {
  if (path.isEmpty) {
    print('Path cannot be empty');
    exit(1);
  }

  if (!Directory(path).existsSync()) {
    print('Path not found: $path');
    exit(1);
  }
}

void checkExcelSourceFile(String excelSourceFile) {
  if (excelSourceFile.isEmpty) {
    print('Excel source file cannot be empty');
    exit(1);
  }

  if (!File(excelSourceFile).existsSync()) {
    print('Excel source file not found: $excelSourceFile');
    exit(1);
  }
}

void checkExcelSheetName(String excelSheetName) {
  if (excelSheetName.isEmpty) {
    print('Excel sheet name cannot be empty');
    exit(1);
  }
}

void checkTemplateArbFileArg(String templateArbFile) {
  if (templateArbFile.isEmpty) {
    print('Template ARB file cannot be empty');
    exit(1);
  }
}

void checkTemplateArbFileExists(String templateArbFile) {
  if (!File(templateArbFile).existsSync()) {
    print('Template ARB file not found: $templateArbFile');
    exit(1);
  }
}

void checkOutputLocalizationFile(String outputLocalizationFile) {
  if (outputLocalizationFile.isEmpty) {
    print('Output localization file cannot be empty');
    exit(1);
  }
}

void checkFlutterPath(String flutterPath) {
  if (flutterPath.isEmpty) {
    print('Flutter path cannot be empty');
    exit(1);
  }
}

Future<void> printProcessOutput(Stream<List<int>> out) async {
  final Stream<String> lines = out.transform(utf8.decoder);
  await for (final String line in lines) {
    stdout.write(line);
  }
}

Future<void> runArbXcel(
  String flutterPath,
  String arbXcelTarget,
  String excelMainSheetName,
  String excelPlaceholderSheetName,
) async {
  final Process abrXcelProcess = await Process.start(
    flutterPath,
    <String>[
      'pub',
      'run',
      'arbxcel',
      '-a',
      arbXcelTarget,
      '-s',
      excelMainSheetName,
      if (excelPlaceholderSheetName.isNotEmpty) ...<String>[
        '-p',
        excelPlaceholderSheetName,
      ],
    ],
    runInShell: true,
  );
  await Future.wait<void>(
    <Future<void>>[
      printProcessOutput(abrXcelProcess.stdout),
      printProcessOutput(abrXcelProcess.stderr),
    ],
  );
  final int arbXcelExitCode = await abrXcelProcess.exitCode;
  if (arbXcelExitCode != 0) {
    exit(arbXcelExitCode);
  }
}

Future<void> runFlutterGenL10n(
  String flutterPath,
  String path,
  String templateArbFile,
  String outputLocalizationFile,
) async {
  final Process flutterGenL10nProcess = await Process.start(
    flutterPath,
    <String>[
      'gen-l10n',
      '--arb-dir',
      path,
      '--template-arb-file',
      templateArbFile,
      '--output-localization-file',
      outputLocalizationFile,
      '--output-dir',
      path,
      '--no-synthetic-package',
    ],
    runInShell: true,
  );
  await Future.wait<void>(
    <Future<void>>[
      printProcessOutput(flutterGenL10nProcess.stdout),
      printProcessOutput(flutterGenL10nProcess.stderr),
    ],
  );
  final int flutterGenL10nExitCode = await flutterGenL10nProcess.exitCode;
  if (flutterGenL10nExitCode != 0) {
    exit(flutterGenL10nExitCode);
  }
}

Future<void> runDartFix(String dartPath, String path) async {
  final Process dartFixProcess = await Process.start(
    dartPath,
    <String>[
      'fix',
      '--apply',
      path,
    ],
    runInShell: true,
  );
  await Future.wait<void>(
    <Future<void>>[
      printProcessOutput(dartFixProcess.stdout),
      printProcessOutput(dartFixProcess.stderr),
    ],
  );
  final int dartFixExitCode = await dartFixProcess.exitCode;
  if (dartFixExitCode != 0) {
    exit(dartFixExitCode);
  }
}

void deleteArbFiles(String path) {
  final Directory directory = Directory(path);
  final Iterable<File> files = directory.listSync().whereType<File>();
  for (final File file in files) {
    if (file.path.endsWith('.arb')) {
      file.delete();
    }
  }
}
