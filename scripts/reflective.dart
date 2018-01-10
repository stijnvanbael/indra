import 'dart:isolate';

import 'package:indra/src/cli.dart';
import 'package:indra/src/tasks/git.dart';
import 'package:indra/src/tasks/pub.dart';

main(List<String> args, SendPort outputPort) async {
  var params = setup(outputPort, args, defaultParams: {'branch': 'dev'});

  var git = new GitRepo('git@github.com:stijnvanbael/reflection.git', branch: params['branch']);
  await git.cloneOrPull();
  await Pub.get();
  await Pub.run('test/reflective.dart');
}
