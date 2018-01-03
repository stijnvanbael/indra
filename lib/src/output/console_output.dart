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
}
