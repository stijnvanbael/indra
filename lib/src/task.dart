library indra.task;

import 'dart:async';
import 'dart:io';

import 'package:indra/src/runner.dart';

import 'output/output.dart';

class Context {
  static void changeDir(String dir) {
    if (Shell.workingDirectory != dir) {
      Shell.workingDirectory = dir.startsWith('/') ? dir : '${Shell.workingDirectory}/$dir';
      output.showMessage(cyan('\$ cd ${Shell.workingDirectory}\n'));
    }
  }
}

class Shell {
  static String workingDirectory = Directory.current.path;
  static String rootDirectory = Directory.current.path;
  static bool running = false;

  static Future<String> execute(
    String executable,
    List<String> args, {
    String workingDirectory,
    bool reportFailure: true,
    bool showOutput: true,
  }) async {
    if (running) {
      throw TaskFailed('Another task is still running, did you forget to put "await" in front of your task?');
    }
    running = true;
    output.showStartStep(executable, args);
    var processOutput = StringBuffer();
    var process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory != null ? workingDirectory : Shell.workingDirectory,
    );
    var completer = Completer<int>();
    var stdout = process.stdout.asBroadcastStream();
    stdout.listen((e) => processOutput.write(new String.fromCharCodes(e)),
        onDone: () async => completer.complete(await process.exitCode));
    if (showOutput) {
      output.showProcessOutput(stdout, process.stderr);
    }
    var code = await completer.future;
    running = false;
    if (code != 0) {
      if (reportFailure) {
        output.showError('Process "$executable" exited with code $code');
      }
      throw TaskFailed(processOutput.toString());
    }
    return processOutput.toString();
  }
}

class TaskFailed implements Exception {
  String message;

  TaskFailed([this.message]);

  String toString() => message;
}

class Aborted extends TaskFailed {
  Aborted() : super('Aborted');
}
