import 'package:flutter/material.dart';

class NewQuestionScreen extends StatelessWidget {
  const NewQuestionScreen({super.key, this.questionId});

  /// If set, the screen edits this existing question instead of
  /// creating a new one (US4: modifier mes questions).
  final String? questionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          questionId == null ? 'Poser une question' : 'Modifier $questionId',
        ),
      ),
    );
  }
}
