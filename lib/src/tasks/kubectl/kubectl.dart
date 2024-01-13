import 'package:indra/indra.dart';
import 'package:indra/src/tasks/kubectl/config.dart';

class KubeCtl {
  static Future apply(String file) async {
    final output = await run(
        ['create', '-f', '"$file"', '-o', 'yaml', '--dry-run=client']);
    return run(['apply', '-f', '-'], stdin: Stream.value(output));
  }

  static Config get config => Config();

  static Future<String> run(
    List<String> args, {
    String? workingDirectory,
    Stream<String>? stdin,
    bool reportFailure = true,
    bool showOutput = true,
  }) =>
      Shell.execute(
        'kubectl',
        args,
        workingDirectory: workingDirectory,
        stdin: stdin,
        reportFailure: reportFailure,
        showOutput: showOutput,
        waitUntilFinished: false,
      );
}
