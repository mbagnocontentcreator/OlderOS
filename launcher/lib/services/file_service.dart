import 'dart:io';
import 'package:path/path.dart' as path;

/// Servizio per la gestione dei file e delle cartelle di sistema.
/// Crea e gestisce le cartelle ~/Documenti, ~/Immagini, ecc.
class FileService {
  // Singleton
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  bool _initialized = false;

  /// Directory home dell'utente
  String get homeDirectory {
    final home = Platform.environment['HOME'];
    if (home != null) return home;

    // Fallback per Linux
    if (Platform.isLinux) {
      return '/home/${Platform.environment['USER'] ?? 'user'}';
    }

    return '.';
  }

  /// Directory dei documenti dell'utente
  String get documentsDirectory => path.join(homeDirectory, 'Documenti');

  /// Directory delle immagini dell'utente
  String get picturesDirectory => path.join(homeDirectory, 'Immagini');

  /// Directory dei download dell'utente
  String get downloadsDirectory => path.join(homeDirectory, 'Scaricati');

  /// Directory dell'app OlderOS per configurazioni
  String get appDataDirectory => path.join(homeDirectory, '.olderos');

  /// Inizializza il servizio file creando le cartelle necessarie
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Crea le cartelle di sistema se non esistono
      await _ensureDirectoryExists(documentsDirectory);
      await _ensureDirectoryExists(picturesDirectory);
      await _ensureDirectoryExists(downloadsDirectory);
      await _ensureDirectoryExists(appDataDirectory);

      _initialized = true;
      print('[FileService] Cartelle di sistema inizializzate');
    } catch (e) {
      print('[FileService] Errore inizializzazione: $e');
    }
  }

  /// Crea una directory se non esiste
  Future<void> _ensureDirectoryExists(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('[FileService] Creata cartella: $dirPath');
    }
  }

  /// Salva un documento di testo nella cartella Documenti
  Future<String?> saveDocument(String fileName, String content) async {
    try {
      await initialize();

      // Assicurati che il nome file abbia l'estensione .txt
      if (!fileName.toLowerCase().endsWith('.txt')) {
        fileName = '$fileName.txt';
      }

      // Sanifica il nome file
      fileName = _sanitizeFileName(fileName);

      final filePath = path.join(documentsDirectory, fileName);
      final file = File(filePath);

      await file.writeAsString(content);
      print('[FileService] Documento salvato: $filePath');

      return filePath;
    } catch (e) {
      print('[FileService] Errore salvataggio documento: $e');
      return null;
    }
  }

  /// Carica un documento di testo
  Future<String?> loadDocument(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('[FileService] Errore lettura documento: $e');
    }
    return null;
  }

  /// Elenca i documenti nella cartella Documenti
  Future<List<FileInfo>> listDocuments() async {
    try {
      await initialize();

      final dir = Directory(documentsDirectory);
      if (!await dir.exists()) return [];

      final files = <FileInfo>[];
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          final name = path.basename(entity.path);
          if (name.toLowerCase().endsWith('.txt')) {
            files.add(FileInfo(
              name: name.replaceAll('.txt', ''),
              path: entity.path,
              size: stat.size,
              lastModified: stat.modified,
            ));
          }
        }
      }

      // Ordina per data di modifica (piu' recenti prima)
      files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return files;
    } catch (e) {
      print('[FileService] Errore elencamento documenti: $e');
      return [];
    }
  }

  /// Copia un'immagine nella cartella Immagini
  Future<String?> saveImage(String sourcePath, {String? fileName}) async {
    try {
      await initialize();

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      // Usa il nome originale se non specificato
      fileName ??= path.basename(sourcePath);
      fileName = _sanitizeFileName(fileName);

      // Se il file esiste gia', aggiungi un numero
      var destPath = path.join(picturesDirectory, fileName);
      var counter = 1;
      while (await File(destPath).exists()) {
        final ext = path.extension(fileName);
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        destPath = path.join(picturesDirectory, '${nameWithoutExt}_$counter$ext');
        counter++;
      }

      await sourceFile.copy(destPath);
      print('[FileService] Immagine salvata: $destPath');

      return destPath;
    } catch (e) {
      print('[FileService] Errore salvataggio immagine: $e');
      return null;
    }
  }

  /// Elenca le immagini nella cartella Immagini
  Future<List<FileInfo>> listImages() async {
    try {
      await initialize();

      final dir = Directory(picturesDirectory);
      if (!await dir.exists()) return [];

      final files = <FileInfo>[];
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];

      await for (final entity in dir.list()) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (imageExtensions.contains(ext)) {
            final stat = await entity.stat();
            files.add(FileInfo(
              name: path.basename(entity.path),
              path: entity.path,
              size: stat.size,
              lastModified: stat.modified,
            ));
          }
        }
      }

      // Ordina per data di modifica (piu' recenti prima)
      files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return files;
    } catch (e) {
      print('[FileService] Errore elencamento immagini: $e');
      return [];
    }
  }

  /// Elimina un file
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('[FileService] File eliminato: $filePath');
        return true;
      }
    } catch (e) {
      print('[FileService] Errore eliminazione file: $e');
    }
    return false;
  }

  /// Sanifica il nome di un file rimuovendo caratteri non validi
  String _sanitizeFileName(String fileName) {
    // Rimuovi caratteri non validi per i nomi file
    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // Limita la lunghezza
    if (fileName.length > 200) {
      final ext = path.extension(fileName);
      fileName = fileName.substring(0, 200 - ext.length) + ext;
    }
    return fileName;
  }

  /// Verifica se una cartella esiste
  Future<bool> directoryExists(String dirPath) async {
    return await Directory(dirPath).exists();
  }

  /// Verifica se un file esiste
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Ottiene la dimensione formattata di un file
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Informazioni su un file
class FileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;

  FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
  });
}
