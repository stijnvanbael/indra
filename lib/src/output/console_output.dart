import 'dart:convert';
import 'dart:io';

import 'package:indra/src/output/text_output.dart';

class ConsoleOutput extends TextOutput {
  @override
  write(String text) {
    stdout.write(text);
  }

  @override
  writeError(String text) {
    stderr.write(text);
  }

  @override
  writeLine(String line) {
    print(line);
  }

  @override
  String readInput() {
    return stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
  }
}
