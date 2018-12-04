library indra.task;

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

  static execute(String executable, List<String> args, {String workingDirectory}) async {
    output.showStartStep(executable, args);
    var process = await Process.start(executable, args,
        workingDirectory: workingDirectory != null ? workingDirectory : Shell.workingDirectory);
    output.showProcessOutput(process);
    var code = await process.exitCode;
    output.showEndStep(code);
    if (code != 0) {
      output.showJobFailed();
      throw new TaskFailed('Process "$executable" failed with exit code $code');
    }
  }
}

class TaskFailed implements Exception {
  TaskFailed([String message]);
}
