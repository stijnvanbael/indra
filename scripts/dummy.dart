import 'dart:isolate';

import 'package:indra/src/cli.dart';

main(List<String> args, SendPort outputPort) async {
  var params = setup(outputPort, args, defaultParams: {'max': '100000000'});

  print('Dummy start');
  for (var i = 1; i < int.parse(params['max']); i++) {
    if(i % 1000000 == 0) {
      print(i);
    }
  }
  print('Dummy end');
}
