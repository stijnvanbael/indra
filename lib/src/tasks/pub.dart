import 'dart:async';

import 'package:indra/indra.dart';

class Pub {
  static Future run(String uri) async {
    await Shell.execute('pub', ['run', uri]);
  }

  static Future getAndUpgrade() async {
    await get();
    await upgrade();
  }

  static Future get() async {
    await Shell.execute('pub', ['get']);
  }

  static Future upgrade() async {
    await Shell.execute('pub', ['upgrade']);
  }
}
