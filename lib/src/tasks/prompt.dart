import 'package:indra/src/runner.dart';

typedef String Formatter(dynamic value);

String toStringFormat(dynamic value) => value != null ? value.toString() : 'null';

class Prompt {
  static T select<T>(
    String message,
    List<T> values, {
    T defaultValue = null,
    Formatter format: toStringFormat,
  }) {
    int choice = _selectMenu(message, values, format, defaultValue);
    return values[choice - 1];
  }

  static int _selectMenu(String message, List values, Formatter format, defaultValue) {
    output.showMessage('\n$message:\n\n');
    var index = 1;
    values.forEach((value) {
      print('$index.  ${format(value)}');
      index++;
    });
    var defaultChoice = defaultValue != null ? values.indexOf(defaultValue) + 1 : null;
    output.showMessage('\nYour choice${defaultChoice != null ? ' (default: $defaultChoice)' : ''}: ');
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

  static confirm(String message, {bool defaultChoice: false}) {
    output.showMessage('$message (${defaultChoice ? 'Y' : 'y'}/${!defaultChoice ? 'N' : 'n'}): ');
    return _promptConfirm(defaultChoice);
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
}
