import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class GPT3 {
  static const String _baseUrl = 'https://api.openai.com/v1/';

  final String apiKey;

  GPT3({required this.apiKey});

  Future<String> generateText(String input) async {
    final Map<String, dynamic> data = {
      "model": "text-davinci-003",
      'prompt': input,
      //'temperature': 0.5,
      'max_tokens': 2000,
      //'n': 1,
      //'stop': '\n',
    };

    print("test: $apiKey  ");
    //print(Uri.parse(_baseUrl + 'engines/davinci-codex/completions'));
    final response = await http.post(
      //Uri.parse(_baseUrl + 'engines/davinci-codex/completions'),
      Uri.parse(_baseUrl + 'completions'),
      headers: {
        "Content-Type": "application/json; charset=utf-8", // add charset
        'Authorization': 'Bearer $apiKey'
      },
      body: json.encode(data),
    );

    try {
      // Code to execute if the key exists and the value can be converted to a string
      final responseData = json.decode(utf8.decode(response.bodyBytes));
//    final responseData = json.decode(response.body);

      print(responseData);

      final responseText = responseData['choices'][0]['text'].toString();

      //두번째 줄 까지는 질문에 대한 대답이나오니 무시
      final lines = responseText.split('\n');
      final generatedText = lines.sublist(1).join('\n');
      return generatedText;
    } catch (e) {
      // Code to execute if an exception is thrown
      print('Error: $e');
      return "";
    }
  }

  Stream<String> generateTextStream(String input) async* {
    final Map<String, dynamic> data = {
      "model": "text-davinci-003",
      'prompt': input,
      'max_tokens': 2000,
    };

    while (true) {
      final response = await http.post(
        Uri.parse(_baseUrl + 'completions'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer $apiKey'
        },
        body: json.encode(data),
      );

      try {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final responseText = responseData['choices'][0]['text'].toString();

        final lines = responseText.split('\n');
        final generatedText = lines.sublist(1).join('\n');
        yield generatedText;
      } catch (e) {
        print('Error: $e');
        yield '';
      }
    }
  }
}
