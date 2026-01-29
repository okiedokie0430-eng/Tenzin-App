import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Heart display widget for app bar - now supports dropdown instead of dialog
class HeartDisplay extends StatefulWidget {
  final int currentHearts;
  final int maxHearts;
  final Duration? timeToNextHeart;
  final VoidCallback? onTap;
  final double size;

  const HeartDisplay({
    super.key,
    required this.currentHearts,
    this.maxHearts = 5,
    this.timeToNextHeart,
    this.onTap,
    this.size = 24,
  });

  @override
  State<HeartDisplay> createState() => HeartDisplayState();
}

class HeartDisplayState extends State<HeartDisplay> with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: -10, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownVisible) {
      _hideDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    if (_isDropdownVisible) return;

    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    const dropdownWidth = 280.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeLeft = MediaQuery.of(context).padding.left;
    final safeRight = MediaQuery.of(context).padding.right;
    const horizontalMargin = 12.0;

    var left = offset.dx;
    final maxLeft = screenWidth - safeRight - horizontalMargin - dropdownWidth;
    final minLeft = safeLeft + horizontalMargin;
    if (left > maxLeft) left = maxLeft;
    if (left < minLeft) left = minLeft;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent backdrop to close dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown content
          Positioned(
            top: offset.dy + size.height + 8,
            left: left,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                ),
              ),
              child: _HeartDropdownContent(
                currentHearts: widget.currentHearts,
                maxHearts: widget.maxHearts,
                timeToNextHeart: widget.timeToNextHeart,
                onClose: _hideDropdown,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isDropdownVisible = true;
    _animationController.forward();
  }

  void _hideDropdown() {
    if (!_isDropdownVisible) return;
    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineBase = theme.colorScheme.outline;

    return GestureDetector(
      key: _key,
      onTap: widget.onTap ?? _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: outlineBase.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: outlineBase.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.currentHearts > 0 ? Icons.favorite : Icons.favorite_border,
              color: widget.currentHearts > 0 ? AppColors.heartRed : Colors.grey,
              size: widget.size,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.currentHearts}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.currentHearts > 0 ? AppColors.heartRed : Colors.grey,
                  ),
            ),
            if (widget.currentHearts < widget.maxHearts && widget.timeToNextHeart != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(widget.timeToNextHeart!),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Heart dropdown content widget
class _HeartDropdownContent extends StatelessWidget {
  final int currentHearts;
  final int maxHearts;
  final Duration? timeToNextHeart;
  final VoidCallback onClose;

  const _HeartDropdownContent({
    required this.currentHearts,
    required this.maxHearts,
    required this.timeToNextHeart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with hearts icon and count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.heartRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.heartRed,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Зүрх',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '$currentHearts / $maxHearts',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.heartRed,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Heart row visualization
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                maxHearts,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < currentHearts ? Icons.favorite : Icons.favorite_border,
                    color: index < currentHearts ? AppColors.heartRed : Colors.grey.shade300,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Time to next heart
            if (currentHearts < maxHearts && timeToNextHeart != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Дараагийн зүрх: ${_formatDuration(timeToNextHeart!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Info text
            Text(
              'Зүрх нь хичээл дээр алдаа гаргахад хасагдана. 20 минут тутамд 1 зүрх нөхөгдөнө.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutesм $secondsс';
  }
}

class HeartRow extends StatelessWidget {
  final int currentHearts;
  final int maxHearts;
  final double size;
  final bool animated;

  const HeartRow({
    super.key,
    required this.currentHearts,
    this.maxHearts = 5,
    this.size = 32,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        maxHearts,
        (index) {
          final isFilled = index < currentHearts;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: animated
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: isFilled ? 1.0 : 0.8),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: _buildHeart(context, isFilled),
                  )
                : _buildHeart(context, isFilled),
          );
        },
      ),
    );
  }

  Widget _buildHeart(BuildContext context, bool isFilled) {
    return Icon(
      isFilled ? Icons.favorite : Icons.favorite_border,
      color: isFilled ? AppColors.heartRed : Colors.grey.shade400,
      size: size,
    );
  }
}

class HeartLossAnimation extends StatefulWidget {
  final int heartsLost;
  final VoidCallback? onComplete;

  const HeartLossAnimation({
    super.key,
    this.heartsLost = 1,
    this.onComplete,
  });

  @override
  State<HeartLossAnimation> createState() => _HeartLossAnimationState();
}

class _HeartLossAnimationState extends State<HeartLossAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite,
                  color: AppColors.heartRed,
                  size: 48,
                ),
                const SizedBox(width: 8),
                Text(
                  '-${widget.heartsLost}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.heartRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NoHeartsDialog extends StatelessWidget {
  final Duration? timeToNextHeart;
  final VoidCallback? onWatchAd;
  final VoidCallback? onClose;

  const NoHeartsDialog({
    super.key,
    this.timeToNextHeart,
    this.onWatchAd,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border,
            color: AppColors.heartRed,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Зүрх дууслаа!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Дараагийн зүрх ${timeToNextHeart != null ? _formatDuration(timeToNextHeart!) : '20 минут'}-ийн дараа нөхөгдөнө.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (onWatchAd != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onWatchAd,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Зар үзэж зүрх авах'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.heartRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              child: const Text('Хүлээх'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutesм $secondsс';
  }
}
