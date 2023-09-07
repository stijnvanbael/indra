class StringPattern {
  final String pattern;
  late RegExp _regExp;
  List<String> _parameters = [];

  StringPattern(this.pattern) {
    _createRegExp(pattern);
  }

  bool matches(String string) => _regExp.hasMatch(string);

  Map<String, String> parse(String string) {
    var match = _regExp.firstMatch(string);
    if (match == null) {
      return {};
    }
    var result = <String, String>{};
    _parameters.forEach((param) {
      result[param] = match[_parameters.indexOf(param) + 1]!;
    });
    return result;
  }

  void _createRegExp(String pattern) {
    _regExp = new RegExp(r'^' +
        pattern.replaceAllMapped(
            new RegExp(r'(:\w+)|([^:]+)', caseSensitive: false), (Match m) {
          if (m[1] != null) {
            _parameters.add(m[1]!.substring(1));
            return r'(.+)';
          } else {
            return _quote(m[2]!);
          }
        }) +
        r'$');
  }

  String _quote(String string) => string.replaceAllMapped(
      new RegExp(r'([.?\\\[\]{\}\-*$^+<>|])|(.)'),
      (m) => m[1] != null ? r'\' + m[1]! : m[2]!);
}
