import 'dart:async';

import 'package:indra/src/daemon/script.dart';
import 'package:indra/src/runner.dart';
import 'package:meta/meta.dart';

class Job {
  final Script script;
  final List arguments;
  final int number;
  DateTime startTimestamp;

  JobStatus status = JobStatus.queued;
  RunnerControl control = new RunnerControl();
  StringBuffer output = new StringBuffer();

  Job({
    @required this.script,
    @required this.arguments,
    @required this.number,
  });

  Future start() async {
    status = JobStatus.running;
    startTimestamp = new DateTime.now();
    control.output.listen(output.write);
    var result = await script.function(control, arguments);
    if(!control.failed) {
      status = JobStatus.completed;
    } else {
      status = JobStatus.failed;
    }
    return result;
  }

  String get name => script.name;

  @override
  String toString() => '${script.name}#$number';

  Map toJson() => {
        'name': script.name,
        'number': number,
        'status': status.toString().substring('JobStatus.'.length),
        'startTimestamp': startTimestamp?.toIso8601String(),
      };

  void cancel() {
    status = JobStatus.cancelled;
    control.cancel();
  }
}

enum JobStatus { queued, running, cancelled, completed, failed }
