import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import 'photo_viewer_screen.dart';

class Photo {
  final String id;
  final String url;
  final String? description;

  const Photo({
    required this.id,
    required this.url,
    this.description,
  });
}

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  // Foto di esempio per l'MVP (usando picsum.photos per placeholder)
  final List<Photo> _photos = List.generate(
    12,
    (index) => Photo(
      id: 'photo_$index',
      url: 'https://picsum.photos/seed/${index + 1}/800/600',
      description: 'Foto ${index + 1}',
    ),
  );

  void _openPhotoViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: _photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'FOTO',
            onGoHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _photos.isEmpty
                ? _EmptyState()
                : Padding(
                    padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        return _PhotoThumbnail(
                          photo: _photos[index],
                          onTap: () => _openPhotoViewer(index),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 120,
            color: OlderOSTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessuna foto',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Le foto ricevute via email appariranno qui',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatefulWidget {
  final Photo photo;
  final VoidCallback onTap;

  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
  });

  @override
  State<_PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<_PhotoThumbnail> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0)),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? OlderOSTheme.primary : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.photo.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      if (_isLoading) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _isLoading = false);
                        });
                      }
                      return child;
                    }
                    return Container(
                      color: OlderOSTheme.background,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: OlderOSTheme.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: OlderOSTheme.background,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: OlderOSTheme.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
                if (_isHovered)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
