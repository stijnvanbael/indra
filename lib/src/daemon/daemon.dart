import 'dart:async';
import 'dart:convert';

import 'package:ansicolor/ansicolor.dart';
import 'package:indra/src/daemon/script.dart';
import 'package:indra/src/daemon/worker_pool.dart';
import 'package:indra/src/util/pattern_matcher.dart';
import 'package:indra/src/util/string_pattern.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

var gray = new AnsiPen()..gray();
var red = new AnsiPen()..red(bold: true);
var boldGreen = new AnsiPen()..green(bold: true);

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
          (headers, body) => _output(headers['name'], headers['number']),
        )
        .when2(
          _matchRequest('GET', '/jobs'),
          (headers, body) => _jobs(),
        )
        .when2(
          _matchRequest('POST', '/jobs/:name/schedule'),
          (headers, body) => _schedule(headers['name'], _fromJson(body)),
        )
        .when2(
          _matchRequest('DELETE', '/jobs/:name/:number'),
          (headers, body) => _cancel(headers['name'], headers['number']),
        )
        .otherwise((r) => new Response.notFound('Not found'));
  }

  Future run() async {
    var handler = const Pipeline().addMiddleware(logRequests()).addHandler(_handleRequest);
    _workerPool = new WorkerPool(numberOfWorkers, workingDir: workingDir);
    _scriptRepository = new ScriptRepository(workingDir);
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
    return new Response.ok('OK');
  }

  Response _jobs() {
    var jobsJson = json.encode(_workerPool.jobs.map((j) => j.toJson()).toList());
    return new Response.ok(jobsJson, headers: {contentType: applicationJson});
  }

  Response _output(String jobName, String number) {
    var job = _workerPool.job('$jobName#$number');
    if (job == null) {
      return new Response.notFound(null);
    }
    return new Response.ok(job.output.toString(), headers: {
      contentType: textPlain,
      characterEncoding: utf8Encoding,
    });
  }

  Response _cancel(String jobName, String number) {
    var job = _workerPool.cancel('$jobName#$number');
    if (job == null) {
      return new Response.notFound(null);
    }
    return new Response.ok('OK');
  }

  static TransformingPredicate<Request, Future<Pair<Map, String>>> _matchRequest(String method, String pathExpression) {
    StringPattern pathPattern = new StringPattern(pathExpression);
    return predicate(
      (Request request) => request.method == method && pathPattern.matches(request.requestedUri.path),
      (Request request) async => new Pair(_extractHeaders(request, pathPattern), await request.readAsString()),
      '$method $pathExpression',
    );
  }

  static Map<String, String> _extractHeaders(Request request, StringPattern pathPattern) {
    var headers = new Map<String, String>.from(request.headers);
    var pathParams = pathPattern.parse(request.requestedUri.path);
    pathParams.forEach((k, v) => headers[k] = v);
    return headers;
  }

  static _fromJson(String body) => _isNotEmpty(body) ? json.decode(body) : {};

  static _isNotEmpty(object) => object != null && object != '';
}
