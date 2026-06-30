import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugLabel extends StatelessWidget {
  const DebugLabel(this.name, {required this.child, super.key});

  final String name;
  final Widget child;

  static bool enabled = true;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !enabled) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              color: const Color(0xCCE3002F),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 8,
                  height: 1,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
