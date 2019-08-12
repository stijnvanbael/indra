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
      output.showError('Error getting issue with key "$issueKey": HTTP ${response.statusCode}');
      throw TaskFailed();
    }
  }

  Future transitionIssue(String issueKey, {@required int transitionId}) async {
    var url = '$_baseUrl/issue/$issueKey/transitions';
    output.showStartStep('POST', [url]);
    var response = await _client.post(
      url,
      body: jsonEncode(_createTransitionBody(transitionId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $authentication',
      },
    );
    if (response.statusCode == 204) {
      output.showMessage('Transitioned issue "$issueKey"\n');
    } else {
      output
          .showError('Error transitioning issue "$issueKey": HTTP ${response.statusCode}');
      throw TaskFailed();
    }
  }

  Map<String, dynamic> _createTransitionBody(int transitionId) => {
        'transition': {'id': '$transitionId'}
      };
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
