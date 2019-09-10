import 'dart:async';

PatternMatcher<I, O> matcher<I, O>() => PatternMatcher([]);

AsyncPatternMatcher<I, O> asyncMatcher<I, O>() => AsyncPatternMatcher([]);

TransformingPredicate<I, T> predicate<I, T>(bool predicate(I input),
        [T transformer(I input), String description]) =>
    TransformingPredicate<I, T>(predicate, transformer != null ? transformer : identity, description);

T identity<T>(dynamic input) => input as T;

class PatternMatcher<I, O> implements Function {
  List<_Case> _cases;

  PatternMatcher(this._cases);

  PatternMatcher<I, O> whenIs<T>(Type type, O function(T input)) =>
      when(TransformingPredicate<I, T>((i) => i?.runtimeType == type, identity), function);

  PatternMatcher<I, O> when<T>(TransformingPredicate<I, T> predicate, O function(T input)) {
    List<_Case<dynamic, dynamic, dynamic>> newCases = List.from(_cases);
    newCases.add(_Case(predicate, function));
    return PatternMatcher(newCases);
  }

  PatternMatcher<I, O> when2<T1, T2>(
      TransformingPredicate<I, Pair<T1, T2>> predicate, O function(T1 input1, T2 input2)) {
    List<_Case<dynamic, dynamic, dynamic>> newCases = List.from(_cases);
    newCases.add(_Case(predicate, (p) => function(p.a, p.b)));
    return PatternMatcher(newCases);
  }

  PatternMatcher<I, O> otherwise(O function(I input)) =>
      when<I>(predicate((i) => true, identity, 'Otherwise'), function);

  O apply(I input) => call(input);

  O call(I input) {
    for (var c in _cases) {
      if (c.matches(input)) {
        return c(input);
      }
    }
    return null;
  }
}

class AsyncPatternMatcher<I, O> implements Function {
  List<_Case<I, dynamic, Future<O>>> _cases;

  AsyncPatternMatcher(this._cases);

  AsyncPatternMatcher<I, O> whenIs<T>(Type type, O function(T input)) =>
      when(TransformingPredicate<I, Future<T>>((i) => i?.runtimeType == type, identity), function);

  AsyncPatternMatcher<I, O> when<T>(TransformingPredicate<I, Future<T>> predicate, O function(T input)) {
    List<_Case<I, dynamic, Future<O>>> newCases = List.from(_cases);
    newCases.add(_Case(predicate, (i) async {
      i = await (await i);
      return function(i);
    }));
    return AsyncPatternMatcher(newCases);
  }

  AsyncPatternMatcher<I, O> when2<T1, T2>(
      TransformingPredicate<I, Future<Pair<T1, T2>>> predicate, O function(T1 input1, T2 input2)) {
    List<_Case<I, dynamic, Future<O>>> newCases = List.from(_cases);
    newCases.add(_Case(predicate, (p) async {
      p = await (await p);
      return function(p.a, p.b);
    }));
    return AsyncPatternMatcher(newCases);
  }

  AsyncPatternMatcher<I, O> otherwise(O function(I input)) =>
      when<I>(predicate((i) => true, (i) async => i, 'Otherwise'), function);

  Future<O> apply(I input) => call(input);

  Future<O> call(I input) {
    for (var c in _cases) {
      if (c.matches(input)) {
        return c(input);
      }
    }
    return null;
  }
}

class _Case<I, T, O> {
  TransformingPredicate<I, T> _transformingPredicate;
  Function _function;

  _Case(this._transformingPredicate, this._function);

  bool matches(I input) => _transformingPredicate.test(input);

  O call(I input) {
    var transformed = _transformingPredicate.transform(input);
    var applied = _function(transformed);
    print(applied);
    return applied;
  }
}

class Pair<A, B> {
  final A a;
  final B b;

  Pair(this.a, this.b);
}

class TransformingPredicate<I, T> {
  Function _predicate;
  Function _transformer;
  String _description;

  TransformingPredicate(bool predicate(I input), T transformer(I input), [String description])
      : this._predicate = predicate,
        this._transformer = transformer,
        this._description = description;

  bool test(I input) => _predicate(input);

  Future<T> transform(I input) async {
    while (input is Future) {
      input = await input;
    }
    return _transformer(input);
  }

  @override
  String toString() {
    return _description != null ? _description : 'TransformingPredicate';
  }
}
