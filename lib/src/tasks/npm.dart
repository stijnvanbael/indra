import 'dart:async';

import 'package:indra/indra.dart';

typedef NpmTask = String;

class Npm {
  static Future run(NpmTask task) => Shell.execute('npm', ['run', task]);

  static Future install() => Shell.execute('npm', ['install']);

  static NpmTask build = 'build';
}
