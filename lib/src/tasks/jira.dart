import 'dart:convert';

import 'package:http/http.dart';
import 'package:indra/indra.dart';
import 'package:meta/meta.dart';

class Jira {
  final String host;
  final String protocol;
  final int version;
  final String authentication;
  final Client _client = Client();

  Jira(
    this.host, {
    @required this.authentication,
    this.protocol: 'https',
    this.version: 3,
  });

  Future<JiraIssue> getIssue(String issueKey) async {
    var url = '$protocol://$host/rest/api/$version/issue/$issueKey';
    output.showStartStep('GET', [url]);
    var response = await _client.get(url, headers: {
      'Authorization': 'Basic $authentication',
    });
    if (response.statusCode == 200) {
      return JiraIssue.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      output.showError('Error getting issue with key "$issueKey": HTTP ${response.statusCode}');
      throw TaskFailed();
    }
  }
}

class JiraIssue {
  final String summary;
  final String key;

  JiraIssue({
    this.key,
    this.summary,
  });

  JiraIssue.fromJson(Map<String, dynamic> json)
      : key = json['key'],
        summary = json['fields']['summary'];
}
