import 'package:indra/indra.dart';
import 'package:indra/src/tasks/kubectl/config.dart';

class KubeCtl {
  static Future createAndApply(String file) async {
    var output = await run(
      ['create', '-f', '"$file"', '-o', 'yaml', '--dry-run=client'],
    );
    return await run(['apply', '-f', '-'], stdin: output);
  }

  static Config get config => Config();

  static Future<String> run(
    List<String> args, {
    String? workingDirectory,
    String? stdin,
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
      );
}
