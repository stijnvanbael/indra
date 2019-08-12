import 'dart:convert';

import 'package:http/http.dart';
import 'package:indra/indra.dart';
import 'package:meta/meta.dart';

class Bitbucket {
  final String authentication;
  final String baseUrl;
  final String project;
  final String repository;
  final Client _client = Client();

  Bitbucket({
    String host = 'api.bitbucket.org',
    String protocol = 'https',
    num version = 2.0,
    @required this.project,
    @required this.repository,
    @required this.authentication,
  }) : baseUrl = '$protocol://$host/$version/repositories/$project/$repository';

  Future createPullRequest({@required String branch, @required String title, bool closeBranch: false}) async {
    var url = '$baseUrl/pullrequests';
    output.showStartStep('POST', [url]);
    var response = await _client.post(
      url,
      body: jsonEncode(_createPullRequestBody(title, branch, closeBranch)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $authentication',
      },
    );
    if (response.statusCode == 201) {
      output.showMessage('Created pull request for branch "$branch"');
    } else {
      output
          .showError('Error creating pull request for branch "$branch": HTTP ${response.statusCode}\n${response.body}');
      throw TaskFailed();
    }
  }

  Map<String, Object> _createPullRequestBody(String title, String branch, bool closeBranch) {
    return {
      'title': title,
      'source': {
        'branch': {
          'name': branch,
        },
      },
      'close_source_branch': closeBranch,
    };
  }
}
