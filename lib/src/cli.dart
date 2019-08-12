import 'dart:io';
import 'dart:isolate';

import 'package:indra/indra.dart';
import 'package:indra/src/output/console_output.dart';
import 'package:indra/src/output/isolate_output.dart';
import 'package:indra/src/runner.dart';

Map<String, String> params;

Map<String, String> setup(SendPort outputPort, List<String> args, {Map<String, String> defaultParams = const {}}) {
  output = outputPort != null ? new IsolateOutput(outputPort) : new ConsoleOutput();
  params = defaultParams;
  args.forEach((a) {
    var keyValue = a.split('=');
    if (keyValue.length != 2) {
      throw new ArgumentError('$a\nUsage: parameter=value');
    }
    params[keyValue[0]] = keyValue[1];
  });
  if (params.containsKey('workingDir')) {
    Context.changeDir(params['workingDir']);
  } else {
    Context.changeDir(Shell.workingDirectory);
  }
  Shell.rootDirectory = Shell.workingDirectory;
  return params;
}

String requiredParam(Map<String, String> params, String name) {
  if (!params.containsKey(name)) {
    output.showError('Missing required param $name');
    exit(-1);
  }
  return params[name];
}
