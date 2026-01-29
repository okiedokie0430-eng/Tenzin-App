import 'package:flutter/material.dart';
import '../../../core/animations/page_transitions.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Gallery Screen for reference images
/// 
/// Per ARCHITECTURE.md specs:
/// - Display reference images from assets/images
/// - Support pinch-to-zoom and pan gestures
/// - Easy navigation with swipe gestures
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Reference images from assets/images
  final List<GalleryImage> _images = const [
    GalleryImage(
      path: 'assets/images/Гансагийн дагмэдийн задаргаа.png',
      title: 'Гансагийн дагмэдийн задаргаа',
      description: 'Гансагийн дагмэдийн задаргааны схем',
    ),
    GalleryImage(
      path: 'assets/images/Гансагийн дагмэдийн задаргаа (галиг).png',
      title: 'Гансагийн дагмэдийн задаргаа (Галиг)',
      description: 'Гансагийн дагмэдийн задаргааны галиг хувилбар',
    ),
    GalleryImage(
      path: 'assets/images/Xэлцэх дасгал 1.png',
      title: 'Хэлцэх дасгал 1',
      description: 'Эхний хэлцэх дасгал',
    ),
    GalleryImage(
      path: 'assets/images/Xэлцэх дасгал 2.png',
      title: 'Хэлцэх дасгал 2',
      description: 'Хоёрдугаар хэлцэх дасгал',
    ),
    GalleryImage(
      path: 'assets/images/Xэлцэх дасгал 3.png',
      title: 'Хэлцэх дасгал 3',
      description: 'Гуравдугаар хэлцэх дасгал',
    ),
    GalleryImage(
      path: 'assets/images/Хэлцэх дасгал 1-3 эшлэл.png',
      title: 'Хэлцэх дасгал 1-3 эшлэл',
      description: 'Хэлцэх дасгалуудын эшлэл',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Зураг'),
        centerTitle: true,
      ),
      body: _images.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return _GalleryTile(
                  image: _images[index],
                  onTap: () => _openImageViewer(context, index),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Зураг байхгүй',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      ModalPageRoute(
        page: ImageViewerScreen(
          images: _images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Gallery tile widget
class _GalleryTile extends StatelessWidget {
  final GalleryImage image;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                image.path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  );
                },
              ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    image.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen image viewer using `photo_view` package for reliable gestures
class ImageViewerScreen extends StatefulWidget {
  final List<GalleryImage> images;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        builder: (context, index) {
          final img = widget.images[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: AssetImage(img.path),
            heroAttributes: PhotoViewHeroAttributes(tag: img.path),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.contained * 4.0,
            initialScale: PhotoViewComputedScale.contained,
          );
        },
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.images[_currentIndex].title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.images[_currentIndex].description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.images[_currentIndex].description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// The custom InteractiveViewer-based implementation has been removed
// in favor of `photo_view`'s `PhotoViewGallery` for simpler, more
// reliable gestures (pinch, pan, double-tap). The gesture hint and
// model definitions remain below.

// Gesture hints removed — simplified viewer uses native `photo_view` gestures.

/// Gallery image model
class GalleryImage {
  final String path;
  final String title;
  final String description;

  const GalleryImage({
    required this.path,
    required this.title,
    this.description = '',
  });
}
