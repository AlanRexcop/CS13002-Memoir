// C:\dev\memoir\lib\widgets\image_viewer.dart
import 'package:flutter/material.dart';

class ImageViewer extends StatelessWidget {
  final Widget child;
  final Object? heroTag;

  const ImageViewer({super.key, required this.child, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                    child: Hero(
                        tag: heroTag ?? child.hashCode,
                        child: child
                    )
                )
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5)
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}