import 'package:ansicolor/ansicolor.dart';
import 'package:indra/src/runner.dart';

typedef String Formatter<T>(T value);

var blue = new AnsiPen()..blue(bold: true);
var highlight = new AnsiPen()..gray(level: 1.0)..gray(level: 0.5, bg: true);

String toStringFormat(dynamic value) => value != null ? value.toString() : 'null';

class Prompt {
  static T select<T>(
    String message,
    List<T> values, {
    T defaultValue = null,
    String format(T value): toStringFormat,
  }) {
    int choice = _selectMenu(message, values, format, defaultValue);
    return values[choice - 1];
  }

  static bool confirm(String message, {bool defaultChoice: false}) {
    output.showMessage(blue(
        '$message (${defaultChoice ? highlight('y') : 'y'}/${!defaultChoice ? highlight('n') : 'n'}${blue('): ')}'));
    return _promptConfirm(defaultChoice);
  }

  static String input(String message, {bool required: false}) {
    output.showMessage(blue('$message: '));
    return _promptInput(required);
  }

  static int _selectMenu<T>(String message, List<T> values, Formatter<T> format, defaultValue) {
    output.showMessage('\n$message:\n\n');
    var index = 1;
    values.forEach((value) {
      print('$index.  ${format(value)}');
      index++;
    });
    var defaultChoice = defaultValue != null ? values.indexOf(defaultValue) + 1 : null;
    output.showMessage(
        blue('\nYour choice${defaultChoice != null ? ' (default: ${highlight(defaultChoice.toString())})' : ''}: '));
    var choice = _promptChoice(values, defaultChoice);
    return choice;
  }

  static int _promptChoice(List values, int defaultChoice) {
    var line = output.readInput().trim();
    var choice = null;
    try {
      if (line == "" && defaultChoice != null) {
        choice = defaultChoice;
      } else {
        choice = int.parse(line);
      }
    } on FormatException {}
    if (choice == null || choice <= 0 || choice > values.length) {
      output.showMessage('Invalid choice "$line", valid values are 1-${values.length}, please try again: ');
      choice = _promptChoice(values, defaultChoice);
    }
    return choice;
  }

  static bool _promptConfirm(bool defaultChoice) {
    var line = output.readInput().trim().toLowerCase();
    var choice = null;
    try {
      if (line == "" && defaultChoice != null) {
        choice = defaultChoice;
      } else {
        choice = line == 'y' ? true : line == 'n' ? false : null;
      }
    } on FormatException {}
    if (choice == null) {
      output.showMessage('Invalid choice "$line", valid values are y or n, please try again: ');
      choice = _promptConfirm(defaultChoice);
    }
    return choice;
  }

  static String _promptInput(bool required) {
    var input = output.readInput().trim();
    if (input == "" && required) {
      output.showMessage('Input is required, please try again: ');
      input = _promptInput(required);
    }
    return input;
  }
}

class Invokable {
  final String description;
  final Function function;

  Invokable(this.description, this.function);

  Future apply() => function();

  String toString() => description;
}
