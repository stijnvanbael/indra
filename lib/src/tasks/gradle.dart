library indra.tasks.gradle;

import 'dart:async';

import 'package:indra/indra.dart';

String clean = 'clean';
String build = 'build';

class Gradle {
  static Future run(List<String> tasks) => Shell.execute('gradle', tasks);
}
