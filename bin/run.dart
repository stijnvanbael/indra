library indra.daemon;

import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:indra/src/runner.dart';

var red = new AnsiPen()..red(bold: true);

main(List<String> args) {
  if (args.isNotEmpty && args[0].contains('=')) {
    args = new List.from(args);
    args.insert(0, 'build.dart');
  }
  if (args.isEmpty) {
    var defaultScript = new File('${Directory.current.path}/build.dart');
    if (!defaultScript.existsSync()) {
      print(red('Usage: indra <job> [param1=value [param2=value [...]]]\n'
          'job: the job to run, defaults to build.dart, the .dart extension can be omitted\n'
          'param1, param2, ...: parameters to pass to the job'));
      exit(-1);
    } else {
      args = ['build.dart'];
    }
  }
  var script = args[0];
  if (!script.endsWith('.dart')) {
    script = '$script.dart';
  }
  var workingDirectory;
  if (script.contains('/')) {
    var path = script.substring(0, script.lastIndexOf('/'));
    script = script.substring(script.lastIndexOf('/') + 1);
    workingDirectory = '${Directory.current.path}/$path';
  } else {
    workingDirectory = Directory.current.path;
  }
  runScript('$workingDirectory/${script}', args.sublist(1), new RunnerControl());
}
