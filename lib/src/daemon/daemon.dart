import 'dart:async';
import 'dart:convert';

import 'package:ansicolor/ansicolor.dart';
import 'package:indra/src/daemon/script.dart';
import 'package:indra/src/daemon/worker_pool.dart';
import 'package:indra/src/util/pattern_matcher.dart';
import 'package:indra/src/util/string_pattern.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

var gray = AnsiPen()..gray();
var red = AnsiPen()..red(bold: true);
var boldGreen = AnsiPen()..green(bold: true);

class Daemon {
  static final contentType = 'Content-Type';
  static final textPlain = 'text/plain';
  static final applicationJson = 'application/json';
  static final transferEncoding = 'Transfer-Encoding';
  static final chunked = 'chunked';
  static final characterEncoding = 'Character-Encoding';
  static final utf8Encoding = 'UTF-8';

  WorkerPool _workerPool;
  ScriptRepository _scriptRepository;
  String host = '0.0.0.0';
  int port = 8080;
  int numberOfWorkers = 1;
  String workingDir;
  AsyncPatternMatcher<Request, Response> requestMatcher;

  Daemon({this.workingDir}) {
    if (workingDir == null) {
      workingDir = '~/indra/scripts';
    }
    requestMatcher = asyncMatcher<Request, Response>()
        .when2(
          _matchRequest('GET', '/jobs/:name/:number/output'),
          (Map<String, String> headers, body) => _output(headers['name'], headers['number']),
        )
        .when2(
          _matchRequest('GET', '/jobs'),
          (headers, body) => _jobs(),
        )
        .when2(
          _matchRequest('POST', '/jobs/:name/schedule'),
          (Map<String, String> headers, String body) => _schedule(headers['name'], _fromJson(body)),
        )
        .when2(
          _matchRequest('DELETE', '/jobs/:name/:number'),
          (Map<String, String> headers, body) => _cancel(headers['name'], headers['number']),
        )
        .otherwise((r) => Response.notFound('Not found'));
  }

  Future run() async {
    var handler = const Pipeline().addMiddleware(logRequests()).addHandler(_handleRequest);
    _workerPool = WorkerPool(numberOfWorkers, workingDir: workingDir);
    _scriptRepository = ScriptRepository(workingDir);
    try {
      await serve(handler, host, port);
      print(gray('Indra daemon started, listening on ') + boldGreen('$host:$port'));
      print(gray('Working directory: ') + boldGreen('$workingDir'));
    } catch (e) {
      print(red('Could not start server, reason:\n$e'));
    }
  }

  Future<Response> _handleRequest(Request request) => requestMatcher.apply(request);

  Response _schedule(String scriptName, Map<String, String> arguments) {
    var argumentsAsList = arguments.keys.map((k) => '$k=${arguments[k]}').toList();
    var script = _scriptRepository.getScript(scriptName);
    _workerPool.schedule(script, argumentsAsList);
    return Response.ok('OK');
  }

  Response _jobs() {
    var jobsJson = json.encode(_workerPool.jobs.map((j) => j.toJson()).toList());
    return Response.ok(jobsJson, headers: {contentType: applicationJson});
  }

  Response _output(String jobName, String number) {
    var job = _workerPool.job('$jobName#$number');
    if (job == null) {
      return Response.notFound(null);
    }
    return Response.ok(job.output.toString(), headers: {
      contentType: textPlain,
      characterEncoding: utf8Encoding,
    });
  }

  Response _cancel(String jobName, String number) {
    var job = _workerPool.cancel('$jobName#$number');
    if (job == null) {
      return Response.notFound(null);
    }
    return Response.ok('OK');
  }

  static TransformingPredicate<Request, Future<Pair<Map<String, String>, String>>> _matchRequest(
      String method, String pathExpression) {
    StringPattern pathPattern = StringPattern(pathExpression);
    return predicate(
      (Request request) => request.method == method && pathPattern.matches(request.requestedUri.path),
      (Request request) async => Pair(_extractHeaders(request, pathPattern), await request.readAsString()),
      '$method $pathExpression',
    );
  }

  static Map<String, String> _extractHeaders(Request request, StringPattern pathPattern) {
    var headers = Map<String, String>.from(request.headers);
    var pathParams = pathPattern.parse(request.requestedUri.path);
    pathParams.forEach((k, v) => headers[k] = v);
    return headers;
  }

  static Map<String, String> _fromJson(String body) =>
      _isNotEmpty(body) ? json.decode(body) as Map<String, String> : <String, String>{};

  static bool _isNotEmpty(object) => object != null && object != '';
}
