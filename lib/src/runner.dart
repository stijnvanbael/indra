library indra.runner;

import 'dart:async';
import 'dart:isolate';

import 'package:indra/src/output/console_output.dart';
import 'package:indra/src/output/output.dart';

Output output = new ConsoleOutput();

/**
 * Spawns a new isolate to run the specified script. The returned Future will complete when the script completes.
 */
Future runScript(String script,
    [List<String> args = const [], RunnerControl control]) async {
  var exitPort = new ReceivePort();
  var errorPort = new ReceivePort();
  var outputPort = new ReceivePort();
  output.showStartRunner();
  args = _addWorkingDir(script, args);
  control.isolate = await Isolate.spawnUri(
    new Uri.file(script),
    args,
    outputPort.sendPort,
    onExit: exitPort.sendPort,
    onError: errorPort.sendPort,
    errorsAreFatal: true,
  );
  output.showStartScript(script, args);
  _configureOutput(outputPort, control);
  _configureErrorHandler(errorPort, control);
  await exitPort.listen((m) {
    output.showEndScript(script);
    outputPort.close();
    errorPort.close();
    exitPort.close();
    if (control != null) {
      control.close();
    }
  }).asFuture();
}

List<String> _addWorkingDir(String script, List<String> args) {
  var workingDir =
      script.substring(script.lastIndexOf('/') + 1, script.indexOf('.dart'));
  var newArgs = new List<String>.from(args);
  newArgs.add('jobName=$workingDir');
  return newArgs;
}

void _configureErrorHandler(ReceivePort errorPort, RunnerControl control) {
  errorPort.listen((e) {
    control.failed = true;
  });
}

void _configureOutput(ReceivePort outputPort, RunnerControl control) {
  outputPort.listen((message) {
    output.showMessage(message);
    if (control != null) {
      control.appendOutput(message);
    }
  });
}

class RunnerControl {
  StreamController _output = new StreamController();

  Isolate isolate;

  Stream get output => _output.stream;

  bool failed = false;

  appendOutput(String message) => _output.add(message);

  void close() {
    _output.close();
  }

  void cancel() {
    isolate.kill(priority: Isolate.immediate);
  }
}
