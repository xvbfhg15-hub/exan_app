import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/question.dart';

class ApiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  final Dio _dio = Dio();

  Future<List<Question>> extractQuestionsFromPdfText(String rawPdfText) async {
    final prompt = '''
استخرج من النص التالي كل الأسئلة وإجاباتها النموذجية، وأعد النتيجة
بصيغة JSON فقط بدون أي شرح إضافي أو أسوار كود، على الشكل التالي:
[
  {"id": "1", "question": "نص السؤال", "answer": "الإجابة النموذجية", "hint": "تلميح مختصر"}
]

النص:
"""
$rawPdfText
"""
''';

    final response = await _dio.post(
      '$_baseUrl?key=$_apiKey',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'temperature': 0},
      }),
    );

    final content =
        response.data['candidates'][0]['content']['parts'][0]['text'];
    final List<dynamic> jsonList = jsonDecode(_stripCodeFences(content));
    return jsonList.map((e) => Question.fromJson(e)).toList();
  }

  Future<VerificationResult> verifyAnswer({
    required Question question,
    String? typedAnswer,
    File? imageFile,
  }) async {
    final parts = <Map<String, dynamic>>[
      {
        'text': '''
السؤال: ${question.questionText}
الإجابة النموذجية: ${question.modelAnswer}

قارن إجابة الطالب (نصًا أو صورة مرفقة) بالإجابة النموذجية، وتجاهل الفروق
الشكلية البسيطة (مسافات، ترقيم، صياغة مرادفة صحيحة علميًا).
أعد النتيجة بصيغة JSON فقط بدون أي أسوار كود:
{"is_correct": true/false, "extracted_text": "النص المستخرج من إجابة الطالب", "feedback": "ملاحظة قصيرة ومشجعة"}
'''
      }
    ];

    if (typedAnswer != null && typedAnswer.trim().isNotEmpty) {
      parts.add({'text': 'إجابة الطالب المكتوبة: $typedAnswer'});
    }

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      parts.add({
        'inline_data': {'mime_type': 'image/png', 'data': base64Image}
      });
    }

    final response = await _dio.post(
      '$_baseUrl
