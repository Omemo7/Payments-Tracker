import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final bool isLoading;
  final bool canGoToOlder;
  final bool canGoToNewer;
  final bool isCurrent;
  final VoidCallback? onOlderPressed;
  final VoidCallback? onCurrentPressed;
  final VoidCallback? onNewerPressed;

  const NavigationButtons({
    Key? key,
    required this.isLoading,
    required this.canGoToOlder,
    required this.canGoToNewer,
    required this.isCurrent,
    this.onOlderPressed,
    this.onCurrentPressed,
    this.onNewerPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      disabledBackgroundColor: Colors.grey[300],
      disabledForegroundColor: Colors.grey[700],
    );

    return Container(
      color: Colors.transparent, // Keeps the background transparent
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0), // Padding for the button row
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: isLoading || !canGoToOlder ? null : onOlderPressed,
                child: const Text('Older'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: isLoading || isCurrent ? null : onCurrentPressed,
                child: const Text('Current'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: isLoading || !canGoToNewer ? null : onNewerPressed,
                child: const Text('Newer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

