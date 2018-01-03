import 'dart:io';

import 'package:indra/src/output/output.dart';

abstract class TextOutput implements Output {
  writeLine(String line);

  write(String text);

  writeError(String text);

  @override
  void showProcessOutput(Process process) {
    process.stdout.listen((e) => write(_indent(new String.fromCharCodes(e))));
    process.stderr.listen((e) => writeError(_indent(new String.fromCharCodes(e))));
  }

  @override
  void showStartStep(String executable, List<String> args) {
    writeLine('\$ $executable ${args.join(' ')}');
    writeLine('');
  }

  static _indent(String string) {
    var s = '    ' + string.splitMapJoin('\n', onMatch: (m) => '\n    ', onNonMatch: (n) => n);
    if (s.endsWith('    ')) s = s.substring(0, s.length - 4);
    return s;
  }

  @override
  void showEndStep(int exitCode) {
    if (exitCode != 0) {
      writeLine('');
      writeLine('  Step finished with exit code $exitCode');
    }
    writeLine('');
  }

  @override
  void showStartRunner() {
//    writeLine(r"  _____           _           ");
//    writeLine(r"  \_   \_ __   __| |_ __ __ _ ");
//    writeLine(r"   / /\/ '_ \ / _` | '__/ _` |");
//    writeLine(r"/\/ /_ | | | | (_| | | | (_| |");
//    writeLine(r"\____/ |_| |_|\__,_|_|  \__,_|");
//    writeLine(r"                              ");
  }

  @override
  void showEndScript(String script) {
    writeLine('Finished running job $script\n');
  }

  @override
  void showStartScript(String script, [List<String> args]) {
    writeLine('\nRunning job $script${args.isNotEmpty ? ' with parameters:\n' : ''}');
    args.forEach((a) => writeLine('    $a'));
    writeLine('');
  }

  @override
  void showError(String message, String stackTrace) {
    writeError('Error: $message\n$stackTrace\n');
    writeLine('Stopped on error\n');
  }

  @override
  void showJobFailed() {
    writeLine('JOB FAILED');
  }

  @override
  void showJobQueued(String jobName, int number) {
    writeLine('Job queued: $jobName #$number');
  }

  @override
  void showJobCancelled(String jobName, int number) {
    writeLine('Job cancelled: $jobName #$number');
  }

  @override
  void showWorkerStarted(String workerName, String jobName, int number) {
    writeLine('$workerName started job: $jobName #$number');
  }

  @override
  void showWorkerFinished(String workerName, String jobName, int number, String status) {
    writeLine('$workerName finished job: $jobName #$number ($status)');
  }

  @override
  void showMessage(String message) {
    write(message);
  }
}
