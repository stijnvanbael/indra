import 'package:indra/src/task.dart';

import 'builds.dart';
import 'config.dart';
import 'container.dart';

class GCloud {
  final String project;
  final String hostname;

  GCloud({
    required this.project,
    required this.hostname,
  });

  Container get container => Container(this);

  Config get config => Config(this);

  Builds get builds => Builds(this);

  Future<String> run(List<String> params, {bool showOutput: true}) =>
      Shell.execute('gcloud', params, showOutput: showOutput);
}
