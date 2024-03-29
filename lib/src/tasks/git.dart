import 'dart:async';
import 'dart:io';

import 'package:indra/indra.dart';

class GitRepo {
  late String _uri;
  late String _branch;

  GitRepo(String uri, {String? branch}) {
    _uri = uri;
    _branch = branch ?? 'master';
  }

  Future clone({String? into, String? branch}) async {
    List<String> args = ['clone'];
    args.addAll(['-b', branch ?? _branch]);
    args.add(_uri);
    if (into != null) args.add(into);
    await _git(args);
  }

  Future cloneOrPull({
    String into = '.',
    bool clean = false,
    String? branch,
  }) async {
    branch = branch ?? _branch;
    Context.changeDir(Shell.rootDirectory);
    var directory = Directory('${Shell.workingDirectory}/$into');
    if (clean) {
      await this._clean(directory);
    }
    if (await directory.exists()) {
      await checkout(into: into, branch: branch);
      await pull(into: into, branch: branch);
    } else {
      await clone(into: into, branch: branch);
    }
    Context.changeDir(into);
  }

  Future<bool> pull({String? branch, String into = ''}) async {
    var output = await _git(['pull', 'origin', branch ?? _branch],
        workingDirectory:
            into.startsWith('/') ? into : '${Shell.workingDirectory}/$into');
    return output.startsWith('Updating');
  }

  Future checkout({
    String? branch,
    String into = '',
    bool createBranch = false,
  }) async {
    if (createBranch) {
      try {
        await _checkout(branch, into,
            createBranch: false, reportFailure: false);
      } on TaskFailed {
        output.showMessage('Branch $branch does not exist yet, creating ...\n');
        await _checkout(branch, into, createBranch: true);
      }
    } else {
      await _checkout(branch, into, createBranch: false);
    }
  }

  Future tag(String tag) => _git(['tag', tag]);

  Future<List<String>> get tags async {
    var tags = await _git(['tag']);
    return tags.split('\n').where((tag) => tag.isNotEmpty).toList();
  }

  Future<String?> latestTag() async => (await tags).lastOrNull;

  Future push({
    bool tags = false,
    String remote = 'origin',
    String? branch,
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

  Future<String> verifyBranch({required String regex}) async {
    var branch = await _git(['rev-parse', '--abbrev-ref', 'HEAD']);
    if (branch.contains('\n')) {
      branch = branch.substring(0, branch.indexOf('\n'));
    }
    if (!RegExp(regex).hasMatch(branch)) {
      output.showError(
          'Branch "$branch" does not match the required pattern "$regex"', '');
      exit(-1);
    } else {
      output.showMessage('On branch "$branch" > OK\n');
    }
    return branch;
  }

  Future rebase({String? branch, bool abort = false}) {
    var params = ['rebase'];
    if (branch != null) {
      params.add(branch);
    }
    if (abort) {
      params.add('--abort');
    }
    return _git(params);
  }

  Future reset({bool hard = false}) async {
    var params = ['reset'];
    if (hard) {
      params.add('--hard');
    }
    await _git(params);
  }

  Future addAndCommit(
      {required String message,
      bool allowClean = false,
      bool noVerify = false}) async {
    await add('.');
    await commit(message: message, allowClean: allowClean, noVerify: noVerify);
  }

  Future add(String file) => _git(['add', file]);

  Future commit(
      {required String message,
      bool allowClean = false,
      bool noVerify = false}) async {
    try {
      var params = ['commit', '-m', message];
      if (noVerify) {
        params.add('--no-verify');
      }
      await _git(params, reportFailure: !allowClean);
    } on TaskFailed catch (e) {
      if (allowClean) {
        if (!e.message.contains('nothing to commit, working tree clean')) {
          output.showError('Process "git" failed');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Future<List<Change>> status({bool showOutput = true}) async {
    var output = (await _git(['status'], showOutput: showOutput));
    return output
        .split('\n')
        .where((line) => line.startsWith('\t'))
        .map(Change.parse)
        .toList();
  }

  Future stash({bool apply = false}) =>
      _git(_args({'stash': true, 'apply': apply}));

  Future fetch({bool prune = false}) =>
      _git(_args({'fetch': true, '--prune': prune}));

  Future<List<Branch>> branch({bool verbose = false, String? delete}) async {
    var output = await _git(
        _args({
          'branch': true,
          '-v': verbose,
          '-D': delete != null,
          delete ?? '': delete != null,
        }),
        showOutput: delete != null);
    return output
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map(Branch.parse)
        .toList();
  }

  Future<String> get currentCommit async {
    var hash = await _git(['rev-parse', 'HEAD']);
    return hash.trim().substring(0, 8);
  }

  List<String> _args(Map<String, bool> args) =>
      args.entries.where((e) => e.value).map((e) => e.key).toList();

  Future _checkout(
    String? branch,
    String into, {
    bool createBranch = false,
    bool reportFailure = true,
  }) async {
    if (branch == null) {
      branch = _branch;
    }
    var params = ['checkout'];
    if (createBranch) {
      params.add('-b');
    }
    params.add(branch);
    await _git(params,
        workingDirectory: '${Shell.workingDirectory}/$into',
        reportFailure: reportFailure);
  }

  Future _clean(Directory directory) async {
    if (await directory.exists()) {
      output.showMessage(cyan('\$ rm -rf ${directory.path}\n'));
      await directory.delete(recursive: true);
    }
  }

  Future<String> _git(
    List<String> args, {
    String? workingDirectory,
    bool reportFailure = true,
    bool showOutput = true,
  }) =>
      Shell.execute('git', args,
          workingDirectory: workingDirectory,
          reportFailure: reportFailure,
          showOutput: showOutput);
}

class Change {
  final String file;
  final ChangeStatus status;

  Change(this.file, this.status);

  static Change parse(String fileLine) {
    var modified = fileLine.startsWith('\tmodified:');
    var deleted = fileLine.startsWith('\tdeleted:');
    var added = fileLine.startsWith('\tnew file:');
    var name = modified || deleted || added
        ? fileLine.substring(fileLine.indexOf(':') + 1).trim()
        : fileLine.trim();
    return Change(
        name,
        added
            ? ChangeStatus.added
            : (deleted ? ChangeStatus.deleted : ChangeStatus.modified));
  }
}

enum ChangeStatus { added, modified, deleted }

class Branch {
  final String name;
  final String lastCommit;
  final bool current;
  final bool hasRemote;
  final bool merged;

  Branch(this.name, this.lastCommit, this.current, this.hasRemote, this.merged);

  static Branch parse(String line) {
    var current = line.startsWith('*');
    var parts = line.split(RegExp(r'[\s\t*]+'));
    var name = parts[1];
    var lastCommit = parts[2];
    var hasRemote = parts[3] != '[gone]';
    var merged = parts[3] == 'Merged';
    return Branch(name, lastCommit, current, hasRemote, merged);
  }
}
