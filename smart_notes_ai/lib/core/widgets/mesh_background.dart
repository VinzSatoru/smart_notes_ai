import 'package:flutter/material.dart';

class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.6),
          radius: 1.5,
          colors: [
            Color(0xFFF4F7FF), // Sangat soft blue
            Colors.white,
            Color(0xFFFFF0F5), // Sangat soft pink
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
