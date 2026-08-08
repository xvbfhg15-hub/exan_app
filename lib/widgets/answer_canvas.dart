import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class AnswerCanvas extends StatefulWidget {
  const AnswerCanvas({super.key, required this.onSave});

  final ValueChanged<Uint8List?> onSave;

  @override
  State<AnswerCanvas> createState() => _AnswerCanvasState();
}

class _AnswerCanvasState extends State<AnswerCanvas> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_controller.isEmpty) {
      widget.onSave(null);
      return;
    }
    final data = await _controller.toPngBytes();
    widget.onSave(data);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Signature(
            controller: _controller,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _controller.clear(),
              icon: const Icon(Icons.refresh),
              label: const Text('مسح'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.check),
              label: const Text('اعتماد الرسم'),
            ),
          ],
        ),
      ],
    );
  }
}
