// exit_wrapper_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator

class ExitWrapper<T> extends StatefulWidget {
  final Widget child;
  const ExitWrapper({super.key, required this.child});

  @override
  State<ExitWrapper<T>> createState() => _ExitWrapperState<T>();
}

class _ExitWrapperState<T> extends State<ExitWrapper<T>> {
  bool _canPop = false;

  void _onPopAttempted(bool didPop, T? result) {
    if (didPop) {
      // If navigation already happened, nothing more to do
      return;
    }

    // Show confirmation dialog
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit')),
        ],
      ),
    ).then((exitConfirmed) {
      if (exitConfirmed ?? false) {
        setState(() => _canPop = true);
        // Exit the app or pop the route
        SystemNavigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<T>(
      canPop: _canPop,
      onPopInvokedWithResult: _onPopAttempted,
      child: widget.child,
    );
  }
}
