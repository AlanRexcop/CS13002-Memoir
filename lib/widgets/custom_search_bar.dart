import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final ValueChanged<String> onChange;
  final String hintText;
  final FocusNode? focusNode;

  const CustomSearchBar({
    super.key,
    required this.onChange,
    required this.hintText,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      child: TextField(
        onChanged: onChange,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 24,),
          filled: true,
          fillColor: Colors.deepPurple[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          constraints: BoxConstraints(maxHeight: 40),
        ),
      ),
    );
  }
}
