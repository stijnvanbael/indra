import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:indra/src/daemon/worker_pool.dart';
import 'package:indra/src/runner.dart';
import 'package:indra/src/util/pattern_matcher.dart';
import 'package:indra/src/util/string_pattern.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

class Daemon {
  static final contentType = 'Content-Type';
  static final textPlain = 'text/plain';
  static final applicationJson = 'application/json';
  static final transferEncoding = 'Transfer-Encoding';
  static final chunked = 'chunked';
  static final characterEncoding = 'Character-Encoding';
  static final utf8Encoding = 'UTF-8';

  WorkerPool _workerPool;
  String host = '0.0.0.0';
  int port = 8080;
  int numberOfWorkers = 1;
  String workingDir = '${Directory.current.path}/jobs';

  Future run() async {
    var handler = const Pipeline().addMiddleware(logRequests()).addHandler(_handleRequest);
    _workerPool = new WorkerPool(numberOfWorkers, workingDir: workingDir);
    await serve(handler, host, port);
    print('Indra daemon started');
  }

  Future<Response> _handleRequest(Request request) async {
    return matcher<Request, Future<Response>>()
        .when2(matchRequest('GET', '/jobs/:name/:number/output'), (headers, body) async => _output(headers['name'], headers['number']))
        .when2(matchRequest('GET', '/jobs'), (headers, body) async => _jobs())
        .when2(matchRequest('POST', '/jobs/:name/schedule'), (headers, body) async => _schedule(headers['name'], _isNotEmpty(body) ? JSON.decode(body) : {}))
        .when2(matchRequest('DELETE', '/jobs/:name/:number'), (headers, body) async => _cancel(headers['name'], headers['number']))
        .otherwise((r) async => new Response.notFound('Not found'))
        .apply(request);
  }

  Response _schedule(String jobName, Map<String, String> arguments) {
    var argumentsAsList = arguments.keys.map((k) => '$k=${arguments[k]}').toList();
    _workerPool.schedule((RunnerControl control) => runScript('$workingDir/$jobName.dart', argumentsAsList, control), jobName: jobName);
    return new Response.ok('OK');
  }

  Response _jobs() {
    var json = JSON.encode(_workerPool.jobs.map((j) => j.toJson()).toList());
    return new Response.ok(json, headers: {contentType: applicationJson});
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

  TransformingPredicate<Request, Pair<Map, String>> matchRequest(String method, String pathExpression) {
    StringPattern pathPattern = new StringPattern(pathExpression);
    return predicate((Request request) => request.method == method && pathPattern.matches(request.requestedUri.path),
        (Request request) async => new Pair(extractHeaders(request, pathPattern), await request.readAsString()));
  }

  Map<String, String> extractHeaders(Request request, StringPattern pathPattern) {
    var headers = new Map.from(request.headers);
    var pathParams = pathPattern.parse(request.requestedUri.path);
    pathParams.forEach((k, v) => headers[k] = v);
    return headers;
  }

  _isNotEmpty(object) => object != null && object != '';
}
