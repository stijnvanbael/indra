import 'package:indra/src/tasks/gcloud/gcloud.dart';

class Config {
  final GCloud _gcloud;

  Config(this._gcloud);

  Future<String> get accessToken async {
    var token = await configHelper('value(credential.access_token)');
    return token.substring(0, token.length - 1);
  }

  Future<String> configHelper(String format) => _gcloud
      .run(['config', 'config-helper', '--format=$format'], showOutput: false);
}
