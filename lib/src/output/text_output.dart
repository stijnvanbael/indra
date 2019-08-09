import 'dart:async';

import 'package:ansicolor/ansicolor.dart';
import 'package:indra/src/output/output.dart';

var cyan = new AnsiPen()..cyan(bold: true);
var green = new AnsiPen()..green(bold: true);
var yellow = new AnsiPen()..yellow(bold: true);
var red = new AnsiPen()..red(bold: true);
var white = new AnsiPen()..rgb(r: 1.0, g: 1.0, b: 1.0);

abstract class TextOutput implements Output {
  writeLine(String line);

  write(String text);

  writeError(String text);

  @override
  void showProcessOutput(Stream<List<int>> stdout, Stream<List<int>> stderr) {
    stdout.listen((e) => write(new String.fromCharCodes(e)));
    stderr.listen((e) => writeError(new String.fromCharCodes(e)));
  }

  @override
  void showStartStep(String executable, List<String> args) {
    writeLine(cyan('\$ $executable ${args.join(' ')}'));
    writeLine('');
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
  void showStartScript(String script, [List<String> args]) {
    writeLine(green('\nRunning job $script${args.isNotEmpty ? ' with parameters:\n' : ''}'));
    args.forEach((a) => writeLine(white('  $a')));
    writeLine('');
  }

  @override
  void showError(String message, [String stackTrace = '']) {
    writeError(red('Error: $message\n$stackTrace\n'));
  }

  @override
  void showJobFailed() {
    writeLine(red('JOB FAILED'));
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
