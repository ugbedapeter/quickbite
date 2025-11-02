import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickbite/services/connectivity_provider.dart';

class OfflineGuard {
  static bool ensureOnline(BuildContext context, {String? message}) {
    final isOnline = context.read<ConnectivityProvider>().isOnline;
    if (!isOnline) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Connect to the internet to continue'),
          ),
        );
      });
      return false;
    }
    return true;
  }
}
