Indra, continuous integration and automation tool
=================================================

Indra allows you to define continuous integration and automation jobs as Dart code.
Jobs can be ran from an IDE and debugged.
Indra runs as a command line tool or as a daemon with a JSON API.
Indra has a user interface that interacts with the daemon.

**Example build: reflective.dart**

```dart
import 'dart:isolate';

import 'package:indra/src/cli.dart';
import 'package:indra/src/task.dart';
import 'package:indra/src/tasks/git.dart';
import 'package:indra/src/tasks/pub.dart';

main(List<String> args, SendPort outputPort) async {
  var params = setup(outputPort, args, defaultParams: {'branch': 'dev'});

  var git = new GitRepo('git@github.com:stijnvanbael/reflection.git', branch: params['branch']);
  await git.cloneOrPull();
  await Pub.get();
  await Pub.run('test/reflective.dart');
}
```

You can either run this job directly by running `dart reflective.dart` from a Dart project that declares `indra` as a dependency in `pubspec.yaml`.
Or you can run it from the daemon.
To do so, `reflective.dart` must be placed in the `jobs/` folder relative to the path where you've checked out Indra.
Run `dart bin/daemon.dart` and call `POST /jobs/reflective/schedule` on `localhost:8080`.