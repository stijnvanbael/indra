library indra.tasks.gradle;

import 'dart:async';

import 'package:indra/indra.dart';

typedef GradleTask = String;

class Gradle {
  static Future run(List<String> tasks) => Shell.execute('gradle', tasks);
  static GradleTask clean = 'clean';
  static GradleTask build = 'build';
}
