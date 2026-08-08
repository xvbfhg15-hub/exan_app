import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/question.dart';

class ApiService {
  static const String _openAiEndpoint =
      'https://api.openai.com/v1/chat/completions';
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');

  final Dio _dio = Dio();

  Future<List<Question>> extractQuestionsFromPdfText(String rawPdfText) async {
    final prompt = '''
استخرج من النص التالي كل الأسئلة وإجاباتها النموذجية، وأعد النتيجة
بصيغة JSON فقط بدون أي شرح إضافي، على الشكل التالي:
[
  {"id": "1", "question": "نص السؤال", "answer": "الإجابة النموذجية", "hint": "تلميح مختصر"}
]

النص:
"""
$rawPdfText
"""
''';

    final response = await _dio.post(
      _openAiEndpoint,
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
      data: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0,
      }),
    );

    final content = response.data['choices'][0]['message']['content'];
    final List<dynamic> jsonList = jsonDecode(_stripCodeFences(content));
    return jsonList.map((e) => Question.fromJson(e)).toList();
  }

  Future<VerificationResult> verifyAnswer({
    required Question question,
    String? typedAnswer,
    File? imageFile,
  }) async {
    final content = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text': '''
السؤال: ${question.questionText}
الإجابة النموذجية: ${question.modelAnswer}

قارن إجابة الطالب (نصًا أو صورة مرفقة) بالإجابة النموذجية، وتجاهل الفروق
الشكلية البسيطة (مسافات، ترقيم، صياغة مرادفة صحيحة علميًا).
أعد النتيجة بصيغة JSON فقط:
{"is_correct": true/false, "extracted_text": "النص المستخرج من إجابة الطالب", "feedback": "ملاحظة قصيرة ومشجعة"}
'''
      }
    ];

    if (typedAnswer != null && typedAnswer.trim().isNotEmpty) {
      content.add({'type': 'text', 'text': 'إجابة الطالب المكتوبة: $typedAnswer'});
    }

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      content.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/png;base64,$base64Image'}
      });
    }

    final response = await _dio.post(
      _openAiEndpoint,
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
      data: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': content}
        ],
        'temperature': 0,
      }),
    );

    final rawContent = response.data['choices'][0]['message']['content'];
    final jsonMap = jsonDecode(_stripCodeFences(rawContent));
    return VerificationResult.fromJson(jsonMap);
  }

  String _stripCodeFences(String text) {
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }
}
