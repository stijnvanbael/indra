library indra.daemon;

import 'dart:io';

import 'package:indra/src/runner.dart';

main(List<String> arg) {
  runScript('${Directory.current.path}/${arg[0]}', arg.sublist(1),
      new RunnerControl());
}
