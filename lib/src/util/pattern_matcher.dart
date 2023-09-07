import 'dart:async';

PatternMatcher<I, O> matcher<I, O>() => PatternMatcher([]);

AsyncPatternMatcher<I, O> asyncMatcher<I, O>() => AsyncPatternMatcher([]);

TransformingPredicate<I, T> predicate<I, T>(
  bool Function(I input) predicate, [
  T Function(I input)? transformer,
  String? description,
]) =>
    TransformingPredicate<I, T>(
        predicate, transformer ?? identity, description);

T identity<T>(dynamic input) => input as T;

class PatternMatcher<I, O> {
  final List<_Case<I, dynamic, O>> _cases;

  PatternMatcher(this._cases);

  PatternMatcher<I, O> whenIs<T>(Type type, O Function(T input) function) =>
      when(TransformingPredicate<I, T>((i) => i?.runtimeType == type, identity),
          function);

  PatternMatcher<I, O> when<T>(
      TransformingPredicate<I, T> predicate, O Function(T input) function) {
    var newCases = List<_Case<I, T, O>>.from(_cases);
    newCases.add(_Case(predicate, function));
    return PatternMatcher(newCases);
  }

  PatternMatcher<I, O> when2<T1, T2>(
      TransformingPredicate<I, Pair<T1, T2>> predicate,
      O Function(T1 input1, T2 input2) function) {
    var newCases = List<_Case<I, Pair<T1, T2>, O>>.from(_cases);
    newCases.add(_Case(predicate, (Pair<T1, T2> p) => function(p.a, p.b)));
    return PatternMatcher(newCases);
  }

  ClosedPatternMatcher<I, O> otherwise(O Function(I input) function) {
    var newCases = List<_Case<I, dynamic, O>>.from(_cases);
    newCases.add(
        _Case(predicate((i) => true, (i) async => i, 'Otherwise'), identity));
    return ClosedPatternMatcher(newCases);
  }

  O? apply(I input) => call(input);

  O? call(I input) {
    for (var c in _cases) {
      if (c.matches(input)) {
        return c(input) as O;
      }
    }
    return null;
  }
}

class ClosedPatternMatcher<I, O> {
  final List<_Case<I, dynamic, O>> _cases;

  ClosedPatternMatcher(this._cases);

  O apply(I input) => call(input);

  O call(I input) {
    for (var c in _cases) {
      if (c.matches(input)) {
        return c(input) as O;
      }
    }
    throw "Last case didn't match";
  }
}

class AsyncPatternMatcher<I, O> {
  final List<_Case<I, dynamic, Future<O>>> _cases;

  AsyncPatternMatcher(this._cases);

  AsyncPatternMatcher<I, O?> whenIs<T>(
          Type type, O Function(T input) function) =>
      when(
          TransformingPredicate<I, Future<T>>(
              (i) => i?.runtimeType == type, identity),
          function);

  AsyncPatternMatcher<I, O> when<T>(
      TransformingPredicate<I, Future<T>> predicate,
      O Function(T input) function) {
    var newCases = List<_Case<I, Future<T>, Future<O>>>.from(_cases);
    newCases.add(_Case(predicate, (Future<FutureOr<T>> i) async {
      return function(await (await i));
    }));
    return AsyncPatternMatcher(newCases);
  }

  AsyncPatternMatcher<I, O> when2<T1, T2>(
      TransformingPredicate<I, Future<Pair<T1, T2>>> predicate,
      FutureOr<O> Function(T1 input1, T2 input2) function) {
    var newCases = List<_Case<I, Future<Pair<T1, T2>>, Future<O>>>.from(_cases);
    newCases.add(_Case(predicate, (Future<FutureOr<Pair<T1, T2>>> p) async {
      var p2 = await (await p);
      return function(p2.a, p2.b);
    }));
    return AsyncPatternMatcher(newCases);
  }

  ClosedAsyncPatternMatcher<I, O> otherwise(
      FutureOr<O> Function(I input) function) {
    var newCases = List<_Case<I, dynamic, Future<O>>>.from(_cases);
    newCases.add(_Case(predicate((i) => true, (i) async => i, 'Otherwise'),
        (dynamic i) async {
      return function(await (await i) as I);
    }));
    return ClosedAsyncPatternMatcher(newCases);
  }

  FutureOr<O?> apply(I input) => call(input);

  FutureOr<O?> call(I input) async {
    for (var c in _cases) {
      if (c.matches(input)) {
        return await c(input);
      }
    }
    return null;
  }
}

class ClosedAsyncPatternMatcher<I, O> {
  final List<_Case<I, dynamic, Future<O>>> _cases;

  ClosedAsyncPatternMatcher(this._cases);

  Future<O> apply(I input) => call(input);

  Future<O> call(I input) async {
    for (var c in _cases) {
      if (c.matches(input)) {
        return await c(input);
      }
    }
    throw "Last case didn't match";
  }
}

typedef Transformation<I, O> = O Function(I input);
typedef Predicate<I> = bool Function(I input);

class _Case<I, T, O> {
  final TransformingPredicate<I, T> _transformingPredicate;
  final Transformation<T, O> _function;

  _Case(this._transformingPredicate, this._function);

  bool matches(I input) => _transformingPredicate.test(input);

  FutureOr<O> call(I input) async {
    var transformed = await _transformingPredicate.transform(input);
    var applied = _function(transformed);
    return applied;
  }
}

class Pair<A, B> {
  final A a;
  final B b;

  Pair(this.a, this.b);
}

class TransformingPredicate<I, T> {
  final Predicate<I> _predicate;
  final Transformation<I, FutureOr<T>> _transformer;
  final String? _description;

  TransformingPredicate(
      Predicate<I> predicate, Transformation<I, FutureOr<T>> transformer,
      [String? description])
      : _predicate = predicate,
        _transformer = transformer,
        _description = description;

  bool test(I input) => _predicate(input);

  FutureOr<T> transform(FutureOr<I> input) async {
    while (input is Future) {
      input = await input;
    }
    return _transformer(input);
  }

  @override
  String toString() {
    return _description ?? 'TransformingPredicate';
  }
}
