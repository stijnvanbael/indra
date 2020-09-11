library indra.output;

import 'dart:async';

import 'package:ansicolor/ansicolor.dart';

var cyan = textColor(AnsiPen()..cyan(bold: true));
var green = textColor(AnsiPen()..green(bold: true));
var yellow = textColor(AnsiPen()..yellow(bold: true));
var red = textColor(AnsiPen()..red(bold: true));
var white = textColor(AnsiPen()..rgb(r: 1.0, g: 1.0, b: 1.0));
var blue = textColor(AnsiPen()..blue(bold: true));
var highlight = textColor(AnsiPen()..gray(level: 1.0)..gray(level: 0.5, bg: true));

typedef StringFormatter = String Function(String input);

StringFormatter textColor(AnsiPen pen) => (String input) => pen(input) as String;

abstract class Output {
  void showStartStep(String executable, List<String> args);

  void showProcessOutput(Stream<List<int>> stdout, Stream<List<int>> stderr);

  void showStartRunner();

  void showStartScript(String script);

  void showParameters(Map<String, dynamic> params);

  void showEndScript(String script);

  void showError(String message, [String stackTrace]);

  void showJobFailed(String error);

  void showJobQueued(String jobName, int number);

  void showJobCancelled(String jobName, int number);

  void showWorkerStarted(String workerName, String jobName, int number);

  void showWorkerFinished(String workerName, String jobName, int number, String status);

  void showMessage(String message);

  String readInput();
}
