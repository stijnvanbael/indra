library indra.task;

import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:indra/src/runner.dart';

var cyan = new AnsiPen()..cyan(bold: true);

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

  static Future<String> execute(String executable, List<String> args, {String workingDirectory}) async {
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
    output.showProcessOutput(stdout, process.stderr);
    var code = await completer.future;
    output.showEndStep(code);
    if (code != 0) {
      output.showError('Process "$executable" failed with exit code $code');
      throw new TaskFailed();
    }
    return processOutput.toString();
  }
}

class TaskFailed implements Exception {
  TaskFailed([String message]);
}
