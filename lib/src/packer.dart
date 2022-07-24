import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

void main() {
  final Uint8List buf = File('example/example.xlsx').readAsBytesSync();
  final String data =
      "/// Embeded Excel template data.\nconst kTemplate = '${base64Encode(buf)}';\n";
  File('lib/src/assets.dart').writeAsString(data);
}
