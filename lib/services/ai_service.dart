import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey =
      'zpmiOdkNFNy2gkFKiv43P7hor9yLNEkO';
  static const String _url = 'https://api.mistral.ai/v1/chat/completions';

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: utf8.encode(
          jsonEncode({
            'model': 'mistral-medium-latest',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a basketball coach AI. Reply in the same language as the user message. Keep answers short and helpful. You ONLY answer questions about: basketball (techniques, tactics, rules, training, equipment, history, etc.) and physical training/fitness (workouts, exercises, nutrition for athletes, injury prevention, rehabilitation, etc.). If user asks about topics outside these areas (politics, weather, other sports, entertainment, general knowledge, etc.), politely decline to answer and explain that you only discuss basketball and physical training topics. NEVER respond to profanity, vulgar language, or obscene words. If user uses such language, politely decline to answer and remind about respectful communication.',
              },
              {'role': 'user', 'content': message},
            ],
            'max_tokens': 512,
            'temperature': 0.7,
          }),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'];
          return content?.toString().trim() ?? 'Извините, не удалось получить ответ';
        }
        return 'Извините, не удалось получить ответ. Попробуйте позже.';
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['error']?['message'] ?? error['message'] ?? response.body;
        return 'Ошибка: $errorMsg';
      }
    } catch (e) {
      return 'Ошибка соединения: $e';
    }
  }

  Future<String> sendMessageWithHistory(List<Map<String, dynamic>> messages) async {
    try {
      final fullMessages = [
        {'role': 'system', 'content': 'You are a basketball coach AI. Reply in the same language as the user message. Keep answers short and helpful. You ONLY answer questions about: basketball (techniques, tactics, rules, training, equipment, history, etc.) and physical training/fitness (workouts, exercises, nutrition for athletes, injury prevention, rehabilitation, etc.). If user asks about topics outside these areas (politics, weather, other sports, entertainment, general knowledge, etc.), politely decline to answer and explain that you only discuss basketball and physical training topics. NEVER respond to profanity, vulgar language, or obscene words. If user uses such language, politely decline to answer and remind about respectful communication.'},
        ...messages,
      ];

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: utf8.encode(
          jsonEncode({
            'model': 'mistral-medium-latest',
            'messages': fullMessages,
            'max_tokens': 512,
            'temperature': 0.7,
          }),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'];
          return content?.toString().trim() ?? 'Извините, не удалось получить ответ';
        }
        return 'Извините, не удалось получить ответ. Попробуйте позже.';
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['error']?['message'] ?? error['message'] ?? response.body;
        return 'Ошибка: $errorMsg';
      }
    } catch (e) {
      return 'Ошибка соединения: $e';
    }
  }
}
