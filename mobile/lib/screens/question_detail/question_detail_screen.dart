import 'package:flutter/material.dart';

class QuestionDetailScreen extends StatelessWidget {
  const QuestionDetailScreen({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Question $questionId')));
  }
}
