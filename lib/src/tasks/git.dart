import 'dart:async';
import 'dart:io';

import 'package:indra/indra.dart';
import 'package:indra/src/cli.dart';
import 'package:meta/meta.dart';

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

  Future cloneOrPull({String into, bool clean = false}) async {
    if (into == null) {
      into = params['jobName'];
      if (into == null) {
        into = _extractDirFromUri();
      }
    }
    Context.changeDir(Shell.rootDirectory);
    var directory = new Directory('${Shell.workingDirectory}/$into');
    if (clean) {
      await this._clean(directory);
    }
    if (await directory.exists()) {
      await pull(into: into);
    } else {
      await clone(into: into);
    }
    Context.changeDir(into);
  }

  Future pull({String into}) async {
    await Shell.execute('git', ['checkout', _branch], workingDirectory: '${Shell.workingDirectory}/$into');
    await Shell.execute('git', ['pull', 'origin', _branch], workingDirectory: '${Shell.workingDirectory}/$into');
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

  Future<String> verifyBranch({@required String regex}) async {
    var branch = await Shell.execute('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branch.contains('\n')) {
      branch = branch.substring(0, branch.indexOf('\n'));
    }
    if (!RegExp(regex).hasMatch(branch)) {
      output.showError('Branch "$branch" does not match the required pattern "$regex"', '');
      exit(-1);
    } else {
      output.showMessage('On branch "$branch" > OK\n');
    }
    return branch;
  }

  Future rebase({@required String branch}) => Shell.execute('git', ['rebase', branch]);

  Future reset({bool hard: false}) async {
    var params = ['reset'];
    if (hard) {
      params.add('--hard');
    }
    await Shell.execute('git', params);
  }

  Future addAndCommit({@required String message}) async {
    await add('.');
    await commit(message: message);
  }

  Future add(String file) => Shell.execute('git', ['add', file]);

  Future commit({@required String message}) => Shell.execute('git', ['commit', '-m', message]);

  Future _clean(Directory directory) async {
    if (await directory.exists()) {
      output.showMessage(cyan('\$ rm -rf ${directory.path}\n'));
      await directory.delete(recursive: true);
    }
  }
}
