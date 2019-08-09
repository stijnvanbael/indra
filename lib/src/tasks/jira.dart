import 'dart:convert';

import 'package:http/http.dart';
import 'package:indra/indra.dart';
import 'package:meta/meta.dart';

class Jira {
  final String host;
  final String protocol;
  final int version;
  final Client _client = Client();
  final String userName;
  final String apiKey;

  Jira(
    this.host, {
    @required this.userName,
    @required this.apiKey,
    this.protocol: 'https',
    this.version: 3,
  });

  Future<JiraIssue> getIssue(String issueKey) async {
    var url = '$protocol://$host/rest/api/$version/issue/$issueKey';
    output.showStartStep('GET', [url]);
    var response = await _client.get(url, headers: {
      'Authorization': 'Basic ${base64.encode(utf8.encode('$userName:$apiKey'))}',
    });
    if (response.statusCode == 200) {
      return JiraIssue.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw TaskFailed('Error getting issue with key "$issueKey": ${response.statusCode} ${response.body}');
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
