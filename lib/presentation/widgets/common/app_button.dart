import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final IconData? trailingIcon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final child = _buildChild(context);

    Widget button;
    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        );
        break;
      case ButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        );
        break;
      case ButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        );
        break;
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: child,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: _getLoadingSize(),
        height: _getLoadingSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: variant == ButtonVariant.primary
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (icon != null && trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(text),
          const SizedBox(width: 8),
          Icon(trailingIcon, size: _getIconSize()),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    if (trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 8),
          Icon(trailingIcon, size: _getIconSize()),
        ],
      );
    }

    return Text(text);
  }

  ButtonStyle? _getButtonStyle(BuildContext context) {
    final padding = _getPadding();
    final textStyle = _getTextStyle(context);

    return ButtonStyle(
      padding: WidgetStateProperty.all(padding),
      textStyle: WidgetStateProperty.all(textStyle),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return Theme.of(context).textTheme.labelMedium!;
      case ButtonSize.medium:
        return Theme.of(context).textTheme.labelLarge!;
      case ButtonSize.large:
        return Theme.of(context).textTheme.titleMedium!;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

class SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String iconAsset;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.iconAsset,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconAsset,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(text),
                ],
              ),
      ),
    );
  }
}

class IconOnlyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final String? tooltip;

  const IconOnlyButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            )
          : null,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: size),
        color: color,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
