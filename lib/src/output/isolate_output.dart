import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:indra/src/output/text_output.dart';

class IsolateOutput extends TextOutput {
  SendPort _sendPort;

  IsolateOutput(this._sendPort);

  @override
  write(String text) {
    _sendPort.send(text);
  }

  @override
  writeError(String text) {
    _sendPort.send(text);
  }

  @override
  writeLine(String line) {
    _sendPort.send('$line\n');
  }

  @override
  String readInput() {
    return stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
  }
}
