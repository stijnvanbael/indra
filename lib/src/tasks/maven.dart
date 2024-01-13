import 'dart:async';

import 'package:indra/indra.dart';

typedef MavenGoal = String;

class Maven {
  static Future run(List<String> tasks) => Shell.execute('mvn', tasks);

  static MavenGoal clean = 'clean';
  static MavenGoal test = 'test';
  static MavenGoal package = 'package';
  static MavenGoal verify = 'verify';
  static MavenGoal install = 'install';
}
