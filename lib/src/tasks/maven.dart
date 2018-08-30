import 'dart:async';

import 'package:indra/indra.dart';

String clean = 'clean';
String test = 'test';
String package = 'package';
String install = 'install';

class Maven {
  static Future run(List<String> tasks) => Shell.execute('mvn', tasks);
}
