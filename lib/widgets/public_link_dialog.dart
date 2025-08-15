// C:\dev\memoir\lib\widgets\public_link_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PublicLinkDialog extends StatelessWidget {
  final String url;
  const PublicLinkDialog({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Public Link'),
      // --- THE FIX ---
      // We wrap the content in a SizedBox to give the AlertDialog a constrained
      // width. This resolves the layout error caused by using an Expanded
      // widget inside the dialog's content.
      content: SizedBox(
        width: 300, // A reasonable fixed width for a dialog
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The QR code
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false, // Makes the QR code have a small border
              ),
              const SizedBox(height: 16),
              // The link and copy button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_all_outlined),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Link copied to clipboard!')),
                        );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}