// C:\dev\memoir\lib\widgets\storage_info.dart
import 'package:flutter/material.dart';

class StorageInfo extends StatelessWidget {
  final int usedStorage;
  final int storageLimit;

  const StorageInfo({
    super.key,
    required this.usedStorage,
    required this.storageLimit,
  });

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    if (decimals < 0) decimals = 0;
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = 0;
    double dBytes = bytes.toDouble();

    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }
    return '${dBytes.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (storageLimit > 0) ? (usedStorage / storageLimit).clamp(0.0, 1.0) : 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    final usedStorageStr = _formatBytes(usedStorage, 2);
    final totalStorageStr = _formatBytes(storageLimit, 0);

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
                  style: const TextStyle(
                      fontSize: 16,
                  )
              ),
              const Spacer(),
              Text(
                  '$usedStorageStr / $totalStorageStr',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary
                  )
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 64.0, top: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
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