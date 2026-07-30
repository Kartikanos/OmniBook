import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? theme.colorScheme.surface
              : AppConstants.primaryColor,
          foregroundColor: isSecondary
              ? theme.textTheme.bodyLarge?.color
              : Colors.white,
          elevation: isSecondary ? 0 : 4,
          shadowColor: AppConstants.primaryColor.withAlpha(80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isSecondary
                ? const BorderSide(color: Color(0xFF334155), width: 1)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSecondary ? AppConstants.primaryColor : Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSecondary
                          ? theme.textTheme.bodyLarge?.color
                          : Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
