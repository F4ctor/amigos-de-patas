import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Carregando...'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(label),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 50),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 54, color: Colors.grey), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center)],
        ),
      ),
    );
  }
}

Widget networkImage(String? url, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
  if (url == null || url.trim().isEmpty) {
    return Container(
      height: height,
      width: width,
      color: const Color(0xFFE8F5EE),
      alignment: Alignment.center,
      child: const Icon(Icons.pets, size: 54, color: Color(0xFF146C43)),
    );
  }
  return Image.network(
    url,
    height: height,
    width: width,
    fit: fit,
    errorBuilder: (_, __, ___) => Container(
      height: height,
      width: width,
      color: const Color(0xFFE8F5EE),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, size: 42),
    ),
  );
}
