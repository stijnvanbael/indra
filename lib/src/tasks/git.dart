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
    await _git(args);
  }

  Future cloneOrPull({String into = '', bool clean = false}) async {
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
      await checkout(into: into);
      await pull(into: into);
    } else {
      await clone(into: into);
    }
    Context.changeDir(into);
  }

  Future pull({String branch, String into = ''}) async {
    if (branch == null) {
      branch = _branch;
    }
    await _git(['pull', 'origin', branch], workingDirectory: '${Shell.workingDirectory}/$into');
  }

  Future checkout({String branch, String into = '', bool createBranch = false}) async {
    if (createBranch) {
      try {
        await _checkout(branch, into, createBranch: false, reportFailure: false);
      } on TaskFailed {
        output.showMessage('Branch $branch does not exist yet, creating ...\n');
        await _checkout(branch, into, createBranch: true);
      }
    } else {
      await _checkout(branch, into, createBranch: false);
    }
  }

  Future tag(String tag) => _git(['tag', tag]);

  Future push({
    bool tags = false,
    String remote: 'origin',
    String branch,
  }) async {
    var params = ['push'];
    if (tags) {
      params.add('--tags');
    }
    if (branch != null) {
      params.addAll(['-u', remote, branch]);
    }
    await _git(params);
  }

  Future<String> verifyBranch({@required String regex}) async {
    var branch = await _git(['rev-parse', '--abbrev-ref', 'HEAD']);
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

  Future rebase({String branch, bool abort = false}) {
    var params = ['rebase'];
    if (branch != null) {
      params.add(branch);
    }
    if (abort) {
      params.add('--abort');
    }
    return _git(params);
  }

  Future reset({bool hard: false}) async {
    var params = ['reset'];
    if (hard) {
      params.add('--hard');
    }
    await _git(params);
  }

  Future addAndCommit({@required String message, bool allowClean: false}) async {
    await add('.');
    await commit(message: message, allowClean: allowClean);
  }

  Future add(String file) => _git(['add', file]);

  Future commit({@required String message, bool allowClean: false}) async {
    try {
      await _git(['commit', '-m', message], reportFailure: !allowClean);
    } on TaskFailed catch (e) {
      if (allowClean) {
        if (!e.message.contains('nothing to commit, working tree clean')) {
          output.showError('Process "git" failed');
          throw e;
        }
      } else {
        throw e;
      }
    }
  }

  Future status() => _git(['status']);

  Future _checkout(String branch, String into, {bool createBranch = false, bool reportFailure = true}) async {
    if (branch == null) {
      branch = _branch;
    }
    var params = ['checkout'];
    if (createBranch) {
      params.add('-b');
    }
    params.add(branch);
    await _git(params, workingDirectory: '${Shell.workingDirectory}/$into', reportFailure: reportFailure);
  }

  String _extractDirFromUri() {
    var match = _uriPattern.firstMatch(_uri);
    if (match != null) {
      return match[1];
    }
    return 'build';
  }

  Future _clean(Directory directory) async {
    if (await directory.exists()) {
      output.showMessage(cyan('\$ rm -rf ${directory.path}\n'));
      await directory.delete(recursive: true);
    }
  }

  Future _git(List<String> args, {String workingDirectory, bool reportFailure: true}) =>
      Shell.execute('git', args, workingDirectory: workingDirectory, reportFailure: reportFailure);
}
