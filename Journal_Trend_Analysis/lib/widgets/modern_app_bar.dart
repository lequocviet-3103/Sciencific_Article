import 'package:flutter/material.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F0F1A)
            : const Color(0xFFF0F2F8),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withAlpha(20),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                if (showBackButton && Navigator.of(context).canPop())
                  _ModernBackButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),

                if (showBackButton && Navigator.of(context).canPop())
                  const SizedBox(width: 4),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withAlpha(120),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                if (actions != null) ...?actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernBackButton extends StatelessWidget {
  const _ModernBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withAlpha(150),
          border: Border.all(
            color: colorScheme.outline.withAlpha(30),
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
