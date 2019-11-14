import 'dart:isolate';

import 'package:indra/indra.dart';
import 'package:indra/src/output/console_output.dart';
import 'package:indra/src/output/isolate_output.dart';
import 'package:indra/src/runner.dart';

Map<String, String> params;

Map<String, String> setup(SendPort outputPort, List<String> args, {Map<String, String> defaultParams = const {}}) {
  output = outputPort != null ? IsolateOutput(outputPort) : ConsoleOutput();
  params = defaultParams;
  params.addAll(parseParams(args));
  if (params.containsKey('workingDir')) {
    Context.changeDir(params['workingDir']);
  } else {
    Context.changeDir(Shell.workingDirectory);
  }
  Shell.rootDirectory = Shell.workingDirectory;
  if (params.isNotEmpty) {
    output.showParameters(params);
  }
  return params;
}

Map<String, String> parseParams(List<String> args) {
  String previousParam;
  var params = Map<String, String>();
  args.forEach((a) {
    var keyValue = a.split('=');
    if (keyValue.length != 2) {
      if (previousParam == null) {
        output.showError('$a\nUsage: parameter=value');
        throw ArgumentError('$a\nUsage: parameter=value');
      } else {
        params[previousParam] = '${params[previousParam]} ${keyValue[0]}';
      }
    } else {
      previousParam = keyValue[0];
      params[keyValue[0]] = keyValue[1];
    }
  });
  return params;
}

Runner bootstrap(SendPort outputPort, List<String> args, {Map<String, String> defaultParams = const {}}) =>
    Runner(setup(outputPort, args, defaultParams: defaultParams));

String requiredParam(Map<String, String> params, String name) {
  if (!params.containsKey(name) || params[name].isEmpty) {
    output.showError('Missing required param "$name"');
    throw TaskFailed();
  }
  return params[name];
}

typedef void Script(Map<String, String> params);

class Runner {
  Map<String, String> _params;

  Runner(this._params);

  run(Script script) async {
    try {
      await script(_params);
    } on TaskFailed catch (e) {
      output.showError(e.message);
      rethrow;
    } catch (e, stacktrace) {
      output.showError(e.toString(), stacktrace.toString());
      rethrow;
    }
  }
}

class RestartRequested {}
