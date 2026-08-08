import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import '../widgets/answer_canvas.dart';

enum AnswerMode { draw, type, photo }

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.questions});
  final List<Question> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _textController = TextEditingController();

  int _currentIndex = 0;
  AnswerMode _mode = AnswerMode.draw;
  File? _capturedImage;
  Uint8List? _drawnImageBytes;
  bool _isChecking = false;
  bool _showHint = false;
  String? _feedback;

  Question get _currentQuestion => widget.questions[_currentIndex];

  Future<File> _bytesToTempFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/answer_${DateTime.now().millisecondsSinceEpoch}.png');
    return file.writeAsBytes(bytes);
  }

  Future<void> _pickImageFromNotebook(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _capturedImage = File(picked.path));
    }
  }

  Future<void> _submitAnswer() async {
    setState(() {
      _isChecking = true;
      _feedback = null;
    });

    try {
      File? imageFile;
      String? typedAnswer;

      if (_mode == AnswerMode.draw && _drawnImageBytes != null) {
        imageFile = await _bytesToTempFile(_drawnImageBytes!);
      } else if (_mode == AnswerMode.photo && _capturedImage != null) {
        imageFile = _capturedImage;
      } else if (_mode == AnswerMode.type) {
        typedAnswer = _textController.text;
      }

      final result = await _apiService.verifyAnswer(
        question: _currentQuestion,
        typedAnswer: typedAnswer,
        imageFile: imageFile,
      );

      if (!mounted) return;

      if (result.isCorrect) {
        _goToNextQuestion();
        _showSnackBar('✅ إجابة صحيحة! ${result.feedback}', Colors.green);
      } else {
        setState(() => _feedback = '❌ ${result.feedback}\nإجابتك المستخرجة: ${result.extractedText}');
      }
    } catch (e) {
      setState(() => _feedback = 'تعذّر التحقق من الإجابة: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _goToNextQuestion() {
    setState(() {
      _showHint = false;
      _feedback = null;
      _capturedImage = null;
      _drawnImageBytes = null;
      _textController.clear();
      if (_currentIndex < widget.questions.length - 1) {
        _currentIndex++;
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('سؤال ${_currentIndex + 1} من ${widget.questions.length}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _currentQuestion.questionText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<AnswerMode>(
              segments: const [
                ButtonSegment(value: AnswerMode.draw, label: Text('رسم'), icon: Icon(Icons.edit)),
                ButtonSegment(value: AnswerMode.type, label: Text('كتابة'), icon: Icon(Icons.keyboard)),
                ButtonSegment(value: AnswerMode.photo, label: Text('صورة'), icon: Icon(Icons.camera_alt)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 16),
            if (_mode == AnswerMode.draw)
              AnswerCanvas(onSave: (bytes) => setState(() => _drawnImageBytes = bytes)),
            if (_mode == AnswerMode.type)
              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'اكتب إجابتك هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_mode == AnswerMode.photo) ...[
              if (_capturedImage != null)
                Image.file(_capturedImage!, height: 200),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImageFromNotebook(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('التقاط صورة'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _pickImageFromNotebook(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('من المعرض'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isChecking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تحقق من الإجابة', style: TextStyle(fontSize: 16)),
              ),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_feedback!),
              ),
              const SizedBox(height: 8),
              if (_currentQuestion.hint != null)
                TextButton.icon(
                  onPressed: () => setState(() => _showHint = !_showHint),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text(_showHint ? 'إخفاء التلميح' : 'عرض التلميح'),
                ),
              if (_showHint) Text(_currentQuestion.hint ?? ''),
            ],
          ],
        ),
      ),
    );
  }
}
