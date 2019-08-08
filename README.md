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

Finally, install Indra:

```
indra/bin/install.sh
```

Now you can run any Indra script as

```
indra <script.dart> [param1=value [param2=value [...]]]
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

Daemon
------

Indra can also be ran as a daemon:

```
indra-daemon <working/dir>
```

Any Dart file under the working directory can be scheduled to run from the daemon by calling:

```
POST http://localhost:8080/jobs/<name of the file excluding .dart>/schedule
```

You can request which jobs are running by calling:

```
GET http://localhost:8080/jobs
```

You can request the output of a job by calling:

```
GET http://localhost:8080/jobs/<script name>/<sequence number>/output
```
