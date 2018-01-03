library indra.task;

import 'dart:io';

import 'package:indra/src/runner.dart';

class Context {
  static void changeDir(String dir) {
    Shell.workingDirectory = dir.startsWith('/') ? dir : '${Shell.workingDirectory}/$dir';
  }
}

class Shell {
  static String workingDirectory = Directory.current.path;

  static execute(String executable, List<String> args, {String workingDirectory}) async {
    output.showStartStep(executable, args);
    var process = await Process.start(executable, args, workingDirectory: workingDirectory != null ? workingDirectory : Shell.workingDirectory);
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
