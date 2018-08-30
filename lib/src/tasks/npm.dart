import 'dart:async';

import 'package:indra/indra.dart';

String build = 'build';

class Npm {
  static Future run(String task) => Shell.execute('npm', ['run', task]);

  static Future install() => Shell.execute('npm', ['install']);
}
