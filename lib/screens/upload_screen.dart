import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import 'quiz_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickAndProcessPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      final file = File(result.files.single.path!);

      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final rawText = PdfTextExtractor(document).extractText();
      document.dispose();

      final questions = await _apiService.extractQuestionsFromPdfText(rawText);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuizScreen(questions: questions)),
      );
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ أثناء المعالجة: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رفع ورقة الأسئلة')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                'قم برفع ملف PDF يحتوي على الأسئلة والإجابات النموذجية',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _pickAndProcessPdf,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('اختيار ملف PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
