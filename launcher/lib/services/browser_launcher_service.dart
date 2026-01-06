import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Servizio per lanciare URL nel browser appropriato per la piattaforma
///
/// Su macOS (sviluppo/test): usa il browser di sistema
/// Su Linux (produzione): lancia Firefox in modalità kiosk
class BrowserLauncherService {
  static final BrowserLauncherService _instance = BrowserLauncherService._internal();
  factory BrowserLauncherService() => _instance;
  BrowserLauncherService._internal();

  /// Tipi di contenuto che richiedono browser completo (WebRTC)
  static const _webRtcDomains = [
    'meet.google.com',
    'meet.jit.si',
    'zoom.us',
    'teams.microsoft.com',
    'web.whatsapp.com',
    'discord.com',
    'whereby.com',
    'gather.town',
  ];

  /// Verifica se l'URL richiede WebRTC (videochiamate)
  bool requiresWebRTC(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return _webRtcDomains.any((domain) =>
      uri.host.contains(domain) || url.contains(domain)
    );
  }

  /// Lancia un URL nel browser appropriato
  ///
  /// [url] - L'URL da aprire
  /// [title] - Titolo per la finestra (usato su Linux kiosk)
  /// [forceExternal] - Forza l'apertura nel browser esterno
  Future<BrowserLaunchResult> launchUrl(
    String url, {
    String? title,
    bool forceExternal = false,
  }) async {
    // Normalizza l'URL
    String normalizedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      normalizedUrl = 'https://$url';
    }

    final uri = Uri.parse(normalizedUrl);

    // Se richiede WebRTC o è forzato esterno, usa il browser di sistema
    if (forceExternal || requiresWebRTC(normalizedUrl)) {
      return await _launchExternalBrowser(uri, title: title);
    }

    // Altrimenti indica che può usare la WebView interna
    return BrowserLaunchResult(
      success: true,
      useInternalWebView: true,
      url: normalizedUrl,
    );
  }

  /// Lancia il browser esterno appropriato per la piattaforma
  Future<BrowserLaunchResult> _launchExternalBrowser(
    Uri uri, {
    String? title,
  }) async {
    try {
      if (Platform.isLinux) {
        return await _launchLinuxBrowser(uri, title: title);
      } else if (Platform.isMacOS) {
        return await _launchMacOSBrowser(uri);
      } else if (Platform.isWindows) {
        return await _launchWindowsBrowser(uri);
      } else {
        // Fallback generico
        return await _launchGenericBrowser(uri);
      }
    } catch (e) {
      debugPrint('Errore lancio browser: $e');
      return BrowserLaunchResult(
        success: false,
        error: 'Impossibile aprire il browser: $e',
      );
    }
  }

  /// Lancia Firefox in modalità kiosk su Linux (produzione OlderOS)
  Future<BrowserLaunchResult> _launchLinuxBrowser(
    Uri uri, {
    String? title,
  }) async {
    // Prova prima Firefox (preferito per WebRTC)
    final firefoxResult = await _tryLaunchLinuxFirefox(uri, title: title);
    if (firefoxResult.success) return firefoxResult;

    // Fallback a Chromium
    final chromiumResult = await _tryLaunchLinuxChromium(uri, title: title);
    if (chromiumResult.success) return chromiumResult;

    // Fallback generico
    return await _launchGenericBrowser(uri);
  }

  /// Prova a lanciare Firefox su Linux in modalità kiosk
  Future<BrowserLaunchResult> _tryLaunchLinuxFirefox(
    Uri uri, {
    String? title,
  }) async {
    try {
      // Verifica se Firefox è installato
      final whichResult = await Process.run('which', ['firefox']);
      if (whichResult.exitCode != 0) {
        return BrowserLaunchResult(success: false, error: 'Firefox non trovato');
      }

      // Lancia Firefox in modalità kiosk
      // --kiosk: modalità schermo intero senza UI
      // --new-window: apre in una nuova finestra
      final process = await Process.start(
        'firefox',
        [
          '--kiosk',
          '--new-window',
          uri.toString(),
        ],
        mode: ProcessStartMode.detached,
      );

      debugPrint('Firefox lanciato con PID: ${process.pid}');

      return BrowserLaunchResult(
        success: true,
        useInternalWebView: false,
        browserName: 'Firefox',
        processId: process.pid,
      );
    } catch (e) {
      return BrowserLaunchResult(success: false, error: e.toString());
    }
  }

  /// Prova a lanciare Chromium su Linux
  Future<BrowserLaunchResult> _tryLaunchLinuxChromium(
    Uri uri, {
    String? title,
  }) async {
    try {
      // Prova chromium-browser o chromium
      String? browserPath;

      for (final browser in ['chromium-browser', 'chromium', 'google-chrome']) {
        final result = await Process.run('which', [browser]);
        if (result.exitCode == 0) {
          browserPath = browser;
          break;
        }
      }

      if (browserPath == null) {
        return BrowserLaunchResult(success: false, error: 'Chromium non trovato');
      }

      // Lancia Chromium in modalità kiosk
      final process = await Process.start(
        browserPath,
        [
          '--kiosk',
          '--no-first-run',
          '--disable-translate',
          '--disable-infobars',
          uri.toString(),
        ],
        mode: ProcessStartMode.detached,
      );

      return BrowserLaunchResult(
        success: true,
        useInternalWebView: false,
        browserName: 'Chromium',
        processId: process.pid,
      );
    } catch (e) {
      return BrowserLaunchResult(success: false, error: e.toString());
    }
  }

  /// Lancia il browser di default su macOS
  Future<BrowserLaunchResult> _launchMacOSBrowser(Uri uri) async {
    try {
      // Usa il comando open che apre nel browser di default
      final result = await Process.run('open', [uri.toString()]);

      if (result.exitCode == 0) {
        return BrowserLaunchResult(
          success: true,
          useInternalWebView: false,
          browserName: 'Browser di sistema',
        );
      } else {
        // Fallback a url_launcher
        return await _launchGenericBrowser(uri);
      }
    } catch (e) {
      return await _launchGenericBrowser(uri);
    }
  }

  /// Lancia il browser di default su Windows
  Future<BrowserLaunchResult> _launchWindowsBrowser(Uri uri) async {
    try {
      final result = await Process.run('start', [uri.toString()], runInShell: true);

      if (result.exitCode == 0) {
        return BrowserLaunchResult(
          success: true,
          useInternalWebView: false,
          browserName: 'Browser di sistema',
        );
      } else {
        return await _launchGenericBrowser(uri);
      }
    } catch (e) {
      return await _launchGenericBrowser(uri);
    }
  }

  /// Fallback generico usando url_launcher
  Future<BrowserLaunchResult> _launchGenericBrowser(Uri uri) async {
    try {
      final launched = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );

      return BrowserLaunchResult(
        success: launched,
        useInternalWebView: false,
        browserName: 'Browser di sistema',
        error: launched ? null : 'Impossibile aprire il browser',
      );
    } catch (e) {
      return BrowserLaunchResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Verifica quali browser sono disponibili su Linux
  Future<List<String>> getAvailableLinuxBrowsers() async {
    if (!Platform.isLinux) return [];

    final browsers = <String>[];
    final browserCommands = [
      'firefox',
      'chromium-browser',
      'chromium',
      'google-chrome',
      'brave-browser',
    ];

    for (final browser in browserCommands) {
      try {
        final result = await Process.run('which', [browser]);
        if (result.exitCode == 0) {
          browsers.add(browser);
        }
      } catch (_) {}
    }

    return browsers;
  }
}

/// Risultato del lancio del browser
class BrowserLaunchResult {
  final bool success;
  final bool useInternalWebView;
  final String? browserName;
  final String? url;
  final String? error;
  final int? processId;

  BrowserLaunchResult({
    required this.success,
    this.useInternalWebView = false,
    this.browserName,
    this.url,
    this.error,
    this.processId,
  });

  @override
  String toString() {
    if (success) {
      if (useInternalWebView) {
        return 'Usa WebView interna per: $url';
      } else {
        return 'Aperto in $browserName';
      }
    } else {
      return 'Errore: $error';
    }
  }
}
