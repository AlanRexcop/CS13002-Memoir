import 'package:flutter/material.dart';



class StorageInfo extends StatelessWidget {
  const StorageInfo({super.key});

  @override
  Widget build(BuildContext context) {
    const double totalStorage = 512;
    const double usedStorage = 102;
    final double progress = usedStorage / totalStorage;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    shape: BoxShape.circle
                ),
                child: Icon(
                    Icons.cloud_queue_outlined,
                    color: colorScheme.primary,
                    size: 24
                ),
              ),
              const SizedBox(width: 20),
              Text(
                  'Storage used:', 
                  style: TextStyle(
                      fontSize: 16, 
                      color: colorScheme.primary
                  )
              ),
              const Spacer(),
              Text(
                  '102MB / 512MB',
                  style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: colorScheme.primary
                  )
              ),
            ],
          ),
          // const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 64.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: colorScheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}