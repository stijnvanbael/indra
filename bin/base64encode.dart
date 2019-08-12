import 'dart:convert';

main(List<String> args) {
  print(base64Encode(utf8.encode(args[0])));
}
