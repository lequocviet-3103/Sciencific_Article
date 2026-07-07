import 'package:flutter/material.dart';

class ModernButton extends StatelessWidget {
  const ModernButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withAlpha(220),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                ),
              )
            else
              Icon(icon, color: colorScheme.onPrimary, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
