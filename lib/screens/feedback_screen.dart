import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:memoir/widgets/primary_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}


class _FeedbackScreenState extends State<FeedbackScreen> {
  String? _selectedCategory;
  DateTime? _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _categories = [
    {'value': 'feedback', 'label': 'Feedback', 'icon': Icons.feedback},
    {'value': 'bugs', 'label': 'Bugs', 'icon': Icons.bug_report},
  ];

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedDate = 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}';
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 50,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _presentDatePicker,
                    borderRadius: BorderRadius.circular(8), // Hiệu ứng gợn sóng đẹp hơn
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
                      child: Row(
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today,
                              color: Colors.black54, size: 20),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      // border: Border.all(color: colorScheme.primary, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        hint: const Text('Type'),
                        icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.primary),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['value'],
                            child: Row(
                              children: [
                                Icon(category['icon'], color: colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(category['label']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
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
                  side: BorderSide(
                      color: colorScheme.primary,
                      width: 1
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter feedback title...',
                          hintStyle: TextStyle(
                              fontSize: 25,
                              fontWeight:
                              FontWeight.bold,
                              color: Colors.grey
                          ),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.nunito(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter your problem here...',
                            hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                            border: InputBorder.none, // Giữ nguyên
                          ),
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                              color: Colors.black
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              PrimaryButton(
                  text: 'Submit',
                  background: colorScheme.primary,
                  onPress: () => {

                  }
              )
            ],
          ),
        ),
      ),
    );
  }
}