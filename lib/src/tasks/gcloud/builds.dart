import 'dart:convert';

import 'package:http/http.dart';
import 'package:indra/src/runner.dart';
import 'package:indra/src/task.dart';
import 'package:indra/src/tasks/gcloud/gcloud.dart';

class Builds {
  final GCloud gcloud;

  Builds(this.gcloud);

  Triggers get triggers => Triggers(gcloud);

  log(String buildId, {bool stream = false}) {
    var params = ['builds', 'log', buildId];
    if (stream) {
      params.add('--stream');
    }
    return gcloud.run(params);
  }
}

class Triggers {
  final GCloud gcloud;
  final Client _client = Client();
  final String _baseUrl;

  Triggers(this.gcloud) : _baseUrl = 'https://cloudbuild.googleapis.com/v1/projects/${gcloud.project}/triggers';

  Future<Map<String, dynamic>> get(String id) async {
    var headers = await _authorization;
    var url = '$_baseUrl/$id';
    output.showStartStep('GET', [url]);
    var response = await _client.get(url, headers: headers);
    if (response.statusCode == 404) {
      throw TaskFailed('Trigger "$id" not found in project "${gcloud.project}"');
    } else if (response.statusCode >= 400) {
      throw TaskFailed('Failed to update trigger "$id": ${response.body}');
    } else {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  }

  Future update(String id, {Map<String, String> substitutions}) async {
    var trigger = await get(id);
    var url = '$_baseUrl/$id';
    var headers = await _authorization;
    if (substitutions != null) {
      trigger['substitutions'] = substitutions;
    }
    id = trigger.remove('id') as String;
    url = '$_baseUrl/$id';
    trigger.remove('createTime');
    var json = jsonEncode(trigger);
    output.showStartStep('PATCH', [url, json]);
    var response = await _client.patch(url, headers: headers, body: json);
    if (response.statusCode >= 400) {
      throw TaskFailed('Failed to update trigger "$id": ${response.body}');
    } else {
      output.showMessage('Updated build trigger $id\n');
    }
  }

  Future<Map<String, String>> get _authorization async {
    return {
      'Authorization': 'Bearer ${await gcloud.config.accessToken}',
    };
  }

  Future<Map<String, dynamic>> run(String id, {branchName = 'master'}) async {
    var headers = await _authorization;
    var url = '$_baseUrl/$id:run';
    output.showStartStep('POST', [url]);
    var response = await _client.post(url, headers: headers, body: jsonEncode({'branchName': branchName}));
    if (response.statusCode == 404) {
      throw TaskFailed('Trigger "$id" not found in project "${gcloud.project}"');
    } else if (response.statusCode >= 400) {
      throw TaskFailed('Failed to run trigger "$id": ${response.body}');
    } else {
      output.showMessage('Build trigger $id started\n');
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  }
}
