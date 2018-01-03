import 'dart:async';

import 'package:indra/src/runner.dart';
import 'package:meta/meta.dart';

class Job {
  final Function function;
  final String name;
  final int number;
  DateTime startTimestamp;

  JobStatus status = JobStatus.queued;
  RunnerControl control = new RunnerControl();
  StringBuffer output = new StringBuffer();

  Job({
    @required this.function,
    @required this.name,
    @required this.number,
  });

  Future start() async {
    status = JobStatus.running;
    startTimestamp = new DateTime.now();
    control.output.listen(output.write);
    var result = await function(control);
    if(!control.failed) {
      status = JobStatus.completed;
    } else {
      status = JobStatus.failed;
    }
    return result;
  }

  @override
  String toString() => '$name#$number';

  Map toJson() => {
        'name': name,
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
