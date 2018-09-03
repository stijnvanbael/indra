library indra.daemon;

import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:indra/src/runner.dart';

var red = new AnsiPen()..red(bold: true);

main(List<String> args) {
  if (args.isEmpty) {
    print(red('Usage: indra <script>'));
  } else {
    var script = args[0];
    if (!script.endsWith('.dart')) {
      script = '$script.dart';
    }
    runScript('${Directory.current.path}/${script}', args.sublist(1),
        new RunnerControl());
  }
}
