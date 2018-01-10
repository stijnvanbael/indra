import 'dart:isolate';

import 'package:indra/src/cli.dart';
import 'package:indra/src/tasks/git.dart';
import 'package:indra/src/tasks/gradle.dart';

main(List<String> args, SendPort outputPort) async {
  var params = setup(outputPort, args, defaultParams: {'branch': 'develop'});

  var git = new GitRepo('git@gitlab.jforce.be:myccv/joint-event-source.git', branch: params['branch']);
  await git.cloneOrPull();
  await Gradle.run([clean, build]);
}
