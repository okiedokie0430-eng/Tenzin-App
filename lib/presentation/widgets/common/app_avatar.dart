import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final bool isOnline;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(
                    color: borderColor ?? Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: ClipOval(
            child: _buildImage(context),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }
    return avatar;
  }

  Widget _buildImage(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (name != null && name!.isNotEmpty) {
      final initials = _getInitials(name!);
      return Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.primaryContainer,
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'NotoSansMongolian',
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class AvatarGroup extends StatelessWidget {
  final List<String?> imageUrls;
  final double size;
  final int maxDisplay;
  final double overlap;

  const AvatarGroup({
    super.key,
    required this.imageUrls,
    this.size = 32,
    this.maxDisplay = 3,
    this.overlap = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = imageUrls.length > maxDisplay ? maxDisplay : imageUrls.length;
    final remaining = imageUrls.length - maxDisplay;

    return SizedBox(
      width: size + (displayCount - 1) * size * (1 - overlap) + (remaining > 0 ? size * (1 - overlap) : 0),
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * size * (1 - overlap),
              child: AppAvatar(
                imageUrl: imageUrls[i],
                size: size,
                showBorder: true,
                borderColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: displayCount * size * (1 - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    fontFamily: 'NotoSansMongolian',
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
