import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.chevron_left_outlined, size: 30,),
        ),
        leadingWidth: 50,
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        title: Text(
          'Feedbacks & Reports',
          style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}
