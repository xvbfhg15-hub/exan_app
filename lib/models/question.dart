/// نموذج السؤال المستخرج من ملف الـ PDF
class Question {
  final String id;
  final String questionText;
  final String modelAnswer;
  final String? hint;

  Question({
    required this.id,
    required this.questionText,
    required this.modelAnswer,
    this.hint,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      questionText: json['question'] ?? '',
      modelAnswer: json['answer'] ?? '',
      hint: json['hint'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': questionText,
        'answer': modelAnswer,
        'hint': hint,
      };
}

/// نتيجة عملية التحقق القادمة من واجهة الذكاء الاصطناعي
class VerificationResult {
  final bool isCorrect;
  final String extractedText;
  final String feedback;

  VerificationResult({
    required this.isCorrect,
    required this.extractedText,
    required this.feedback,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      isCorrect: json['is_correct'] ?? false,
      extractedText: json['extracted_text'] ?? '',
      feedback: json['feedback'] ?? '',
    );
  }
}
