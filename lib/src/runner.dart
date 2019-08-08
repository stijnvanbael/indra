library indra.runner;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:indra/src/output/console_output.dart';
import 'package:indra/src/output/output.dart';

Output output = ConsoleOutput();

/**
 * Spawns a new isolate to run the specified script. The returned Future will complete when the script completes.
 */
Future runScript(String script, [List<String> args = const [], RunnerControl control]) async {
  var exitPort = ReceivePort();
  var errorPort = ReceivePort();
  var outputPort = ReceivePort();
  output.showStartRunner();
  args = _addParams(script, args);
  try {
    control.isolate = await Isolate.spawnUri(
      Uri.file(script),
      args,
      outputPort.sendPort,
      onExit: exitPort.sendPort,
      onError: errorPort.sendPort,
      errorsAreFatal: true,
    );
  } on IsolateSpawnException catch (e) {
    var message = e.message.substring('Unable to spawn isolate: '.length);
    print('Failed to run script:\n $message');
    exit(-1);
  }
  output.showStartScript(script, args);
  _configureOutput(outputPort, control);
  _configureErrorHandler(errorPort, control);
  await exitPort.listen((m) {
    if (!control.failed) {
      output.showEndScript(script);
    }
    outputPort.close();
    errorPort.close();
    exitPort.close();
    if (control != null) {
      control.close();
    }
  }).asFuture();
}

List<String> _addParams(String script, List<String> args) {
  var workingDir = script.substring(0, script.lastIndexOf('/'));
  var jobName = script.endsWith("/build.dart")
      ? workingDir.substring(workingDir.lastIndexOf('/') + 1)
      : script.substring(script.lastIndexOf('/') + 1, script.indexOf('.dart'));
  var newArgs = List<String>.from(args);
  newArgs.add('jobName=$jobName');
  newArgs.add('workingDir=$workingDir');
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
  StreamController _output = StreamController();

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
