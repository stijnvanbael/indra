import 'dart:async';

PatternMatcher<I, O> matcher<I, O>() => new PatternMatcher([]);

TransformingPredicate<I, T> predicate<I, T>(bool predicate(I input), [T transformer(I input) = identity]) =>
    new TransformingPredicate<I, T>(predicate, transformer);

identity<T>(input) => input as T;

class PatternMatcher<I, O> implements Function {
  List<_Case> _cases;

  PatternMatcher(this._cases);

  PatternMatcher<I, O> whenIs<T>(Type type, O function(T input)) => when(new TransformingPredicate<I, T>((i) => i?.runtimeType == type, identity), function);

  PatternMatcher<I, O> when<T>(TransformingPredicate<I, T> predicate, O function(T input)) {
    var newCases = new List.from(_cases);
    newCases.add(new _Case(predicate, function));
    return new PatternMatcher(newCases);
  }

  PatternMatcher<I, O> when2<T1, T2>(TransformingPredicate<I, Pair<T1, T2>> predicate, O function(T1 input1, T2 input2)) {
    var newCases = new List.from(_cases);
    newCases.add(new _Case(predicate, (p) async {
      p = await p;
      return function(p.a, p.b);
    }));
    return new PatternMatcher(newCases);
  }

  PatternMatcher<I, O> otherwise(O function(I input)) => when(predicate((i) => true), function);

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

class _Case<I, T, O> {
  TransformingPredicate<I, T> _transformingPredicate;
  Function _function;

  _Case(this._transformingPredicate, this._function);

  bool matches(I input) => _transformingPredicate.test(input);

  O call(I input) => _function(_transformingPredicate.transform(input));
}

class Pair<A, B> {
  final A a;
  final B b;

  Pair(this.a, this.b);
}

class TransformingPredicate<I, T> {
  Function _predicate;
  Function _transformer;

  TransformingPredicate(bool predicate(I input), T transformer(I input))
      : this._predicate = predicate,
        this._transformer = transformer;

  bool test(I input) => _predicate(input);

  Future<T> transform(I input) async {
    if (input is Future) {
      input = await input;
    }
    return _transformer(input);
  }
}
