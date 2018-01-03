import 'dart:async';

import 'package:indra/src/daemon/job.dart';
import 'package:indra/src/runner.dart';

class Worker {
  Function _finished;
  bool _running = false;
  String _name;
  final String workingDir;

  bool get idle => !_running;

  Worker({this.workingDir, finished(Worker worker, Job job), String name}) {
    _finished = finished;
    _name = name == null ? _nextWorkerName() : name;
  }

  Future run(Job job) async {
    _running = true;
    output.showWorkerStarted(_name, job.name, job.number);
    await job.start();
    _running = false;
    output.showWorkerFinished(_name, job.name, job.number, job.status.toString().substring('JobStatus.'.length));
    if (_finished != null) {
      _finished(this, job);
    }
  }
}

int _index = 1;

String _nextWorkerName() => 'Worker ${_index++}';
