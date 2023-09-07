import 'package:indra/src/tasks/kubectl/kubectl.dart';

class Config {
  Future useContext(String context) => _run(['use-context', context]);

  Future _run(List<String> args) => KubeCtl.run(['config', ...args]);
}
