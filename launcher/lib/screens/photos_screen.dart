import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../widgets/big_button.dart';
import 'photo_viewer_screen.dart';

class Photo {
  final String id;
  final String path; // Percorso locale del file
  final String? description;

  const Photo({
    required this.id,
    required this.path,
    this.description,
  });

  // Per compatibilità con photo_viewer_screen
  String get url => path;
}

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<Photo> _photos = [];
  bool _isLoading = false;
  String? _currentFolder;

  // Estensioni immagini supportate
  static const _imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];

  // Chiave per salvare il percorso della cartella
  static const _folderPathKey = 'photos_folder_path';

  @override
  void initState() {
    super.initState();
    _loadSavedFolder();
  }

  Future<void> _loadSavedFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_folderPathKey);

    if (savedPath != null) {
      final directory = Directory(savedPath);
      if (await directory.exists()) {
        await _loadPhotosFromFolder(savedPath);
      }
    }
  }

  Future<void> _saveFolderPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_folderPathKey, path);
  }

  Future<void> _selectFolder() async {
    setState(() => _isLoading = true);

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleziona cartella foto',
      );

      if (selectedDirectory != null) {
        await _loadPhotosFromFolder(selectedDirectory);
      }
    } catch (e) {
      _showError('Errore nella selezione della cartella');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPhotosFromFolder(String folderPath) async {
    final directory = Directory(folderPath);

    if (!await directory.exists()) {
      _showError('La cartella non esiste');
      return;
    }

    final List<Photo> photos = [];
    int photoIndex = 0;

    try {
      await for (final entity in directory.list()) {
        if (entity is File) {
          final extension = entity.path.toLowerCase();
          if (_imageExtensions.any((ext) => extension.endsWith(ext))) {
            final fileName = entity.path.split('/').last;
            photos.add(Photo(
              id: 'photo_$photoIndex',
              path: entity.path,
              description: fileName,
            ));
            photoIndex++;
          }
        }
      }

      // Ordina per nome file
      photos.sort((a, b) => a.path.compareTo(b.path));

      setState(() {
        _photos = photos;
        _currentFolder = folderPath.split('/').last;
        _currentFolderPath = folderPath;
      });

      // Salva il percorso per persistenza
      await _saveFolderPath(folderPath);

      if (photos.isEmpty) {
        _showMessage('Nessuna foto trovata nella cartella');
      }
    } catch (e) {
      _showError('Errore nel caricamento delle foto');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 18)),
        backgroundColor: OlderOSTheme.danger,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 18)),
        backgroundColor: OlderOSTheme.primary,
      ),
    );
  }

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

          // Barra azioni
          Container(
            padding: const EdgeInsets.symmetric(horizontal: OlderOSTheme.marginScreen, vertical: 16),
            child: Row(
              children: [
                BigButton(
                  label: 'SCEGLI CARTELLA',
                  icon: Icons.folder_open,
                  backgroundColor: _isLoading ? OlderOSTheme.textSecondary : OlderOSTheme.primary,
                  onTap: _isLoading ? () {} : _selectFolder,
                ),
                const SizedBox(width: 24),
                if (_currentFolder != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: OlderOSTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OlderOSTheme.primary.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder, color: OlderOSTheme.photosColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentFolder!,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_photos.length} foto',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: OlderOSTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Griglia foto o stato vuoto
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: OlderOSTheme.primary,
                          strokeWidth: 4,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Caricamento foto...',
                          style: TextStyle(
                            fontSize: 24,
                            color: OlderOSTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _photos.isEmpty
                    ? _EmptyState(onSelectFolder: _selectFolder)
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
  final VoidCallback onSelectFolder;

  const _EmptyState({required this.onSelectFolder});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 120,
            color: OlderOSTheme.textSecondary.withAlpha(128),
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
            'Seleziona una cartella per visualizzare le tue foto',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          BigButton(
            label: 'SCEGLI CARTELLA',
            icon: Icons.folder_open,
            backgroundColor: OlderOSTheme.photosColor,
            onTap: onSelectFolder,
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
                color: Colors.black.withAlpha(_isHovered ? 51 : 25),
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
                Image.file(
                  File(widget.photo.path),
                  fit: BoxFit.cover,
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
                          Colors.black.withAlpha(128),
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
