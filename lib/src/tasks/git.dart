import 'dart:async';
import 'dart:io';

import 'package:indra/indra.dart';
import 'package:indra/src/cli.dart';

class GitRepo {
  String _uri;
  String _branch;
  final RegExp _uriPattern = new RegExp(r'.+?([^/]+)\.git');

  GitRepo(String uri, {String branch: 'master'}) {
    _uri = uri;
    _branch = branch;
  }

  Future clone({String into}) async {
    List<String> args = ['clone'];
    if (_branch != null) args.addAll(['-b', _branch]);
    args.add(_uri);
    if (into != null) args.add(into);
    await Shell.execute('git', args);
  }

  Future cloneOrPull({String into}) async {
    if (into == null) {
      into = params['jobName'];
      if (into == null) {
        into = _extractDirFromUri();
      }
    }
    Context.changeDir(Shell.rootDirectory);
    var directory = new Directory('${Shell.workingDirectory}/$into');
    if (await directory.exists()) {
      await pull(into: into);
    } else {
      await clone(into: into);
    }
    Context.changeDir(into);
  }

  Future pull({String into}) async {
    List<String> args = ['pull', 'origin', _branch];
    await Shell.execute('git', args,
        workingDirectory: '${Shell.workingDirectory}/$into');
  }

  String _extractDirFromUri() {
    var match = _uriPattern.firstMatch(_uri);
    if (match != null) {
      return match[1];
    }
    return 'build';
  }

  Future tag(String tag) => Shell.execute('git', ['tag', tag]);

  Future push({bool tags = false}) async {
    var params = ['push'];
    if (tags) {
      params.add('--tags');
    }
    await Shell.execute('git', params);
  }
}
