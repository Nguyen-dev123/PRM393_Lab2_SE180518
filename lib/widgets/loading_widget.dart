import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const LoadingList({super.key, this.count = 6, this.itemHeight = 90});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: count,
      itemBuilder: (_, i) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: SizedBox(height: itemHeight),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
