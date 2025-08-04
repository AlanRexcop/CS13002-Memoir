// lib/screens/feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:memoir/providers/app_provider.dart'; // No longer needed here
import 'package:memoir/providers/feedback_provider.dart';
import 'package:memoir/widgets/primary_button.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'feedback', 'label': 'Feedback', 'icon': Icons.feedback},
    {'value': 'bugs', 'label': 'Bugs', 'icon': Icons.bug_report},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    FocusScope.of(context).unfocus();

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a feedback type.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final text = _textController.text;
      final tag = _selectedCategory;

      ref.read(feedbackNotifierProvider.notifier).submitFeedback(
            title: title,
            text: text,
            tag: tag,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // The check for isSignedIn is removed as access to this screen is already gated.

    ref.listen<FeedbackState>(feedbackNotifierProvider, (previous, next) {
      if (next.status == FeedbackStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback has been submitted.'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(feedbackNotifierProvider.notifier).resetState();
        Navigator.of(context).pop();
      }
      if (next.status == FeedbackStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'An unknown error occurred.'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(feedbackNotifierProvider.notifier).resetState();
      }
    });

    final feedbackState = ref.watch(feedbackNotifierProvider);
    final isLoading = feedbackState.status == FeedbackStatus.loading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.chevron_left_outlined, size: 30),
        ),
        leadingWidth: 50,
        backgroundColor: colorScheme.secondary,
        elevation: 0,
        title: Text(
          'Feedbacks & Reports',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Type'),
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: colorScheme.primary),
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['value'],
                              child: Row(
                                children: [
                                  Icon(category['icon'],
                                      color: colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(category['label']),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isLoading
                              ? null
                              : (newValue) {
                                  setState(() {
                                    _selectedCategory = newValue;
                                  });
                                },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colorScheme.primary, width: 1),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            hintText: 'Enter feedback title...',
                            hintStyle: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.nunito(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title.';
                            }
                            return null;
                          },
                        ),
                        const Divider(color: Colors.grey),
                        Expanded(
                          child: TextFormField(
                            controller: _textController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              hintText: 'Enter your problem here...',
                              hintStyle:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                            expands: true,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(color: Colors.black),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please describe your feedback.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // --- SIMPLIFIED BUTTON ---
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  PrimaryButton(
                    text: 'Submit',
                    background: colorScheme.primary,
                    onPress: _submitFeedback, // Unconditional call
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}