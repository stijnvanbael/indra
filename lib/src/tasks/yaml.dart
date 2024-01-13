import 'dart:io';

import 'package:yaml_edit/yaml_edit.dart';

class Yaml {
  static Future replace(
    String filename, {
    int documentIndex = 0,
    required List<dynamic> key,
    required String value,
  }) async {
    final file = File(filename);
    final contents = await file.readAsString();
    final documents = contents
        .split('---\n')
        .where((element) => element.trim().isNotEmpty)
        .toList();
    final editor = YamlEditor(documents[documentIndex]);
    editor.update(key, value);
    if (documents.length > 1) {
      documents[documentIndex] = editor.toString();
      final output = '---\n' + documents.join('---\n');
      await file.writeAsString(output);
    } else {
      await file.writeAsString(editor.toString());
    }
  }
}
