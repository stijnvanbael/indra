library indra.output;

import 'dart:async';

abstract class Output {
  void showStartStep(String executable, List<String> args);

  void showProcessOutput(Stream<List<int>> stdout, Stream<List<int>> stderr);

  void showEndStep(int exitCode);

  void showStartRunner();

  void showStartScript(String script, [List<String> args]);

  void showEndScript(String script);

  void showError(String message, String stackTrace);

  void showJobFailed();

  void showJobQueued(String jobName, int number);

  void showJobCancelled(String jobName, int number);

  void showWorkerStarted(String workerName, String jobName, int number);

  void showWorkerFinished(String workerName, String jobName, int number, String status);

  void showMessage(String message);
}
