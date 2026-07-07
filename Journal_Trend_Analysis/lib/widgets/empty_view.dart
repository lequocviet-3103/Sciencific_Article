import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.search_off,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withAlpha(20),
                    colorScheme.secondary.withAlpha(20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.primary.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface.withAlpha(160),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
