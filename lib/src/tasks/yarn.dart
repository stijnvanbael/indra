import 'dart:async';

import 'package:indra/indra.dart';

String build = 'build';

class Yarn {
  static Future run(String task) => Shell.execute('yarn', ['run', task]);

  static Future build([String project]) => Shell.execute('yarn', ['build']..add(project));

  static Future install() => Shell.execute('yarn', []);
}
