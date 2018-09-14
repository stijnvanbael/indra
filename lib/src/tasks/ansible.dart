import 'dart:async';

import 'package:indra/indra.dart';

class Ansible {
  static Future playbook({
    String playbook,
    String inventory,
  }) async {
    var params = [playbook];
    if (inventory != null) {
      params.addAll(['-i', inventory]);
    }
    await Shell.execute('ansible-playbook', params);
  }
}
