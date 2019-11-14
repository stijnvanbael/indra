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
    String setup,
    bool reportFailure = true,
    bool showOutput = true,
    bool waitUntilFinished = true,
  }) async {
    if (waitUntilFinished) {
      _setRunning();
    }
    output.showStartStep(executable, args);
    Process process = await _startProcess(executable, args, workingDirectory, setup);
    var completer = Completer<int>();
    StringBuffer processOutput = _attachOutputListener(process, showOutput, completer);
    if (waitUntilFinished) {
      await _finishProcess(process, reportFailure, executable, processOutput, completer);
    }
    return processOutput.toString();
  }

  static void _setRunning() {
    if (running) {
      throw TaskFailed('Another task is still running, did you forget to put "await" in front of your task?');
    }
    running = true;
  }

  static Future<Process> _startProcess(
      String executable, List<String> args, String workingDirectory, String setup) async {
    try {
      var process = await Process.start(
        executable,
        args,
        workingDirectory: workingDirectory != null ? workingDirectory : Shell.workingDirectory,
      );
      return process;
    } on ProcessException catch (e) {
      output.showError('Failed to start $executable (${e.message}), make sure it is installed'
          '${setup != null ? '\nMore info on how to set up $executable: $setup' : ''}');
      throw Aborted();
    }
  }

  static StringBuffer _attachOutputListener(Process process, bool showOutput, Completer<int> completer) {
    var processOutput = StringBuffer();
    var stdout = process.stdout.asBroadcastStream();
    stdout.listen((e) => processOutput.write(String.fromCharCodes(e)),
        onDone: () async => completer.complete(await process.exitCode));
    if (showOutput) {
      output.showProcessOutput(stdout, process.stderr);
    }
    return processOutput;
  }

  static Future _finishProcess(Process process, bool reportFailure, String executable, StringBuffer processOutput,
      Completer<int> completer) async {
    var code = await completer.future;
    running = false;
    if (code != 0) {
      if (reportFailure) {
        output.showError('Process "$executable" exited with code $code');
      }
      throw TaskFailed(processOutput.toString());
    }
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
