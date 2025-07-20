import 'package:flutter/material.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          'Recycle bin',
          style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}
