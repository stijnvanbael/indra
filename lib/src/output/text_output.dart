import 'dart:async';

import 'package:indra/src/output/output.dart';

abstract class TextOutput implements Output {
  writeLine(String line);

  write(String text);

  writeError(String text);

  @override
  void showProcessOutput(Stream<List<int>> stdout, Stream<List<int>> stderr) {
    stdout.listen((e) => write(String.fromCharCodes(e)));
    stderr.listen((e) => writeError(String.fromCharCodes(e)));
  }

  @override
  void showStartStep(String executable, List<String> args) {
    writeLine('');
    writeLine(cyan('\$ $executable ${args.join(' ')}'));
  }

  @override
  void showStartRunner() {
    writeLine(cyan(r"  _____           _           "));
    writeLine(cyan(r"  \_   \_ __   __| |_ __ __ _ "));
    writeLine(cyan(r"   / /\/ '_ \ / _` | '__/ _` |"));
    writeLine(cyan(r"/\/ /_ | | | | (_| | | | (_| |"));
    writeLine(cyan(r"\____/ |_| |_|\__,_|_|  \__,_|"));
    writeLine(cyan(r"                              "));
  }

  @override
  void showEndScript(String script) {
    writeLine(green('Finished running job $script\n'));
    writeLine(green('JOB SUCCEEDED\n'));
  }

  @override
  void showStartScript(String script) {
    writeLine(green('\nRunning job $script\n'));
  }

  @override
  void showParameters(Map<String, dynamic> params) {
    writeLine(green('Parameters:\n'));
    params.entries.forEach((p) => writeLine(white('${p.key} = ${p.value}')));
    writeLine('');
  }

  @override
  void showError(String message, [String stackTrace = '']) {
    writeError(red('$message\n$stackTrace\n'));
  }

  @override
  void showJobFailed(String error) {
    writeLine(red('JOB FAILED\n$error'));
  }

  @override
  void showJobQueued(String jobName, int number) {
    writeLine(green('Job queued: $jobName #$number'));
  }

  @override
  void showJobCancelled(String jobName, int number) {
    writeLine(yellow('Job cancelled: $jobName #$number'));
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
