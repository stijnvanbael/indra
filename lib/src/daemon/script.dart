import 'dart:async';

import 'package:indra/src/runner.dart';

typedef Future ScriptFunction(RunnerControl control, List arguments);

class Script {
  final String name;
  final ScriptFunction function;

  Script(this.name, this.function);
}

class ScriptRepository {
  final String workingDir;

  ScriptRepository(this.workingDir);

  Script getScript(String name) {
    return new Script(name, (RunnerControl control, List arguments) => runScript('$workingDir/$name.dart', arguments, control));
  }

}