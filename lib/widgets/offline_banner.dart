import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOnline;
  const OfflineBanner({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOnline ? 0 : 32,
      width: double.infinity,
      color: Colors.redAccent,
      alignment: Alignment.center,
      child: isOnline
          ? const SizedBox.shrink()
          : const Text(
              'You are offline. Some actions need internet.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
    );
  }
}
