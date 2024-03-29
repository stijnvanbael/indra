import 'package:indra/src/daemon/job.dart';
import 'package:indra/src/daemon/script.dart';
import 'package:indra/src/daemon/worker.dart';
import 'package:indra/src/runner.dart';

class WorkerPool {
  late Set<Worker> _workers;
  List<Job> _queue = [];
  Map<String, Job> _jobs = {};
  Map<String, int> _latestJobNumber = {};

  WorkerPool(int numberOfWorkers, {required String workingDir}) {
    _workers = Set();
    for (var i = 0; i < numberOfWorkers; i++) {
      _workers.add(Worker(workingDir: workingDir, finished: _workerFinished));
    }
  }

  void schedule(Script script, List<String> arguments) {
    var job = Job(
      script: script,
      arguments: arguments,
      number: _nextNumber(script.name),
    );
    _jobs[job.toString()] = job;
    if (idleWorkers.isEmpty) {
      output.showJobQueued(job.name, job.number);
      _queue.add(job);
    } else {
      idleWorkers.first.run(job);
    }
  }

  Iterable<Worker> get idleWorkers => _workers.where((w) => w.idle);

  void _workerFinished(Worker worker, Job finishedJob) {
    _jobs.remove(finishedJob.toString());
    if (_queue.isNotEmpty) {
      var nextJob = _queue.removeAt(0);
      worker.run(nextJob);
    }
  }

  List<Job> get jobs => List.from(_jobs.values);

  int _nextNumber(String jobName) {
    _latestJobNumber.putIfAbsent(jobName, () => 1);
    var number = _latestJobNumber[jobName];
    _latestJobNumber[jobName] = _latestJobNumber[jobName]! + 1;
    return number!;
  }

  Job? job(String key) => _jobs[key];

  Job? cancel(String key) {
    var job = _jobs[key];
    if (job != null) {
      job.cancel();
      output.showJobCancelled(job.name, job.number);
    }
    return job;
  }
}
