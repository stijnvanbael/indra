Indra, continuous integration and automation tool
=================================================

Indra allows you to define continuous integration and automation scripts as Dart code.
Scripts can be ran from an IDE and debugged.
Indra runs as a command line tool or as a daemon with a JSON API.
Indra has a user interface that interacts with the daemon.

Installation
------------

First, install [Dart](https://www.dartlang.org/install).

Then, clone Indra from GitHub:

```
git clone https://github.com/stijnvanbael/indra.git
```

Finally define an alias for Indra in `~/.bash_profile`:

```
alias indra='dart <path-to-indra>/bin/run.dart'
```

Now you can run any Indra script as

```
indra <job.dart> [param1=value [param2=value [...]]]
```

Or in case the file is named build.dart, simply

```
indra <[param1=value [param2=value [...]]]
```

Example
-------

Example script: reflective.dart

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

To run the script

```
indra reflective.dart
```