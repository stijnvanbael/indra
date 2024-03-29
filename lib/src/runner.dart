library indra.runner;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:indra/src/output/console_output.dart';
import 'package:indra/src/output/output.dart';

Output output = ConsoleOutput();

/// Spawns a new isolate to run the specified script. The returned Future will complete when the script completes.
Future runScript(
  String script,
  RunnerControl control, [
  List<String> args = const [],
]) async {
  var exitPort = ReceivePort();
  var errorPort = ReceivePort();
  var outputPort = ReceivePort();
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
  output.showStartScript(script);
  _configureOutput(outputPort, control);
  _configureErrorHandler(errorPort, control);
  await exitPort.listen((m) {
    if (!control.failed) {
      if (!control.restart && !control.aborted) {
        output.showEndScript(script);
      } else if (control.restart) {
        control.reset();
        runScript(script, control, args);
      }
    } else {
      output.showJobFailed(control.error!);
    }
    outputPort.close();
    errorPort.close();
    exitPort.close();
    control.close();
  }).asFuture();
}

List<String> _addParams(String script, List<String> args) {
  var workingDir = script.substring(0, script.lastIndexOf('/'));
  var jobName = workingDir.substring(workingDir.lastIndexOf('/') + 1);
  var newArgs = List<String>.from(args);
  newArgs.add('jobName=$jobName');
  newArgs.add('workingDir=$workingDir');
  return newArgs;
}

void _configureErrorHandler(ReceivePort errorPort, RunnerControl control) {
  errorPort.listen((e) {
    var errors = e as List<dynamic>;
    var firstError = (errors.first as String);
    if (firstError.contains('RestartRequested')) {
      control.restart = true;
    } else if (firstError.contains('Aborted')) {
      control.aborted = true;
    } else {
      control.failed = true;
      control.error = errors.join('\n');
    }
  });
}

void _configureOutput(ReceivePort outputPort, RunnerControl control) {
  outputPort.listen((message) {
    output.showMessage(message as String);
    control.appendOutput(message);
  });
}

class RunnerControl {
  StreamController _output = StreamController();

  late Isolate isolate;

  Stream get output => _output.stream;

  bool failed = false;
  bool restart = false;
  bool aborted = false;
  String? error;

  appendOutput(String message) => _output.add(message);

  void close() {
    _output.close();
  }

  void cancel() {
    isolate.kill(priority: Isolate.immediate);
  }

  void reset() {
    failed = false;
    restart = false;
    aborted = false;
    error = null;
  }
}
