import 'dart:io';

import 'package:yaml_edit/yaml_edit.dart';

class Yaml {
  static Future replace(
    String filename, {
    int documentIndex = 0,
    required String key,
    required String value,
  }) async {
    var file = File(filename);
    var contents = await file.readAsString();
    var documents = contents
        .split('---')
        .where((element) => element.trim().isNotEmpty)
        .toList();
    final editor = YamlEditor(documents[documentIndex]);
    editor.update([key], value);
    await file.writeAsString(editor.toString());
  }
}
