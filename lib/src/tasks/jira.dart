import 'dart:convert';

import 'package:http/http.dart';
import 'package:indra/indra.dart';
import 'package:meta/meta.dart';

class Jira {
  final String authentication;
  final String _baseUrl;
  final Client _client = Client();

  Jira(
    String host, {
    @required this.authentication,
    String protocol: 'https',
    int version: 3,
  }) : _baseUrl = '$protocol://$host/rest/api/$version';

  Future<JiraIssue> getIssue(String issueKey) async {
    var url = '$_baseUrl/issue/$issueKey';
    output.showStartStep('GET', [url]);
    var response = await _client.get(url, headers: {
      'Authorization': 'Basic $authentication',
    });
    if (response.statusCode == 200) {
      return JiraIssue.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw TaskFailed('Error getting issue with key "$issueKey": HTTP ${response.statusCode}');
    }
  }

  Future transitionIssue(String issueKey, {@required int transitionId}) async {
    var url = '$_baseUrl/issue/$issueKey/transitions';
    output.showStartStep('POST', [url]);
    var response = await _client.post(
      url,
      body: jsonEncode({
        'transition': {'id': '$transitionId'}
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $authentication',
      },
    );
    if (response.statusCode == 204) {
      output.showMessage('Transitioned issue "$issueKey"\n');
    } else {
      throw TaskFailed('Error transitioning issue "$issueKey": HTTP ${response.statusCode}');
    }
  }

  Future commentIssue(String issueKey, String comment) async {
    var url = '$_baseUrl/issue/$issueKey/comment';
    output.showStartStep('POST', [url]);
    var response = await _client.post(
      url,
      body: jsonEncode({'body': comment}),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $authentication',
      },
    );
    if (response.statusCode == 201) {
      output.showMessage('Commented issue "$issueKey"\n');
    } else {
      throw TaskFailed('Error commenting issue "$issueKey": HTTP ${response.statusCode}');
    }
  }
}

class JiraIssue {
  final String summary;
  final String key;
  final String type;

  JiraIssue({
    this.key,
    this.summary,
    this.type,
  });

  JiraIssue.fromJson(Map<String, dynamic> json)
      : key = json['key'],
        summary = json['fields']['summary'],
        type = json['fields']['issuetype']['name'];
}
