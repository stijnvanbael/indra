library indra.daemon;

import 'package:indra/src/daemon/daemon.dart';

main(List<String> arg) {
  new Daemon(workingDir: arg.isNotEmpty ? arg[0] : null).run();
}
