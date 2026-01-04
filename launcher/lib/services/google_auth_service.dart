import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestisce l'autenticazione OAuth2 con Google per Gmail
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Queste credenziali verranno configurate dall'utente su Google Cloud Console
  // Per ora usiamo placeholder che dovranno essere sostituiti
  String? _clientId;
  String? _clientSecret;

  // Token OAuth2
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // Scopes necessari per Gmail IMAP/SMTP
  static const _scopes = [
    'https://mail.google.com/',
    'email',
    'profile',
  ];

  // Chiavi per SharedPreferences
  static const _keyClientId = 'google_oauth_client_id';
  static const _keyClientSecret = 'google_oauth_client_secret';
  static const _keyAccessToken = 'google_oauth_access_token';
  static const _keyRefreshToken = 'google_oauth_refresh_token';
  static const _keyTokenExpiry = 'google_oauth_token_expiry';
  static const _keyUserEmail = 'google_oauth_user_email';
  static const _keyUserName = 'google_oauth_user_name';

  String? _userEmail;
  String? _userName;

  bool get isConfigured => _clientId != null && _clientSecret != null;
  bool get hasValidToken => _accessToken != null &&
      _tokenExpiry != null &&
      _tokenExpiry!.isAfter(DateTime.now());
  String? get accessToken => _accessToken;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  /// Carica le credenziali OAuth salvate
  Future<bool> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    _clientId = prefs.getString(_keyClientId);
    _clientSecret = prefs.getString(_keyClientSecret);
    _accessToken = prefs.getString(_keyAccessToken);
    _refreshToken = prefs.getString(_keyRefreshToken);
    _userEmail = prefs.getString(_keyUserEmail);
    _userName = prefs.getString(_keyUserName);

    final expiryMs = prefs.getInt(_keyTokenExpiry);
    if (expiryMs != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    }

    // Se abbiamo refresh token ma access token scaduto, rinnoviamo
    if (_refreshToken != null && !hasValidToken && isConfigured) {
      await refreshAccessToken();
    }

    return _refreshToken != null;
  }

  /// Configura le credenziali OAuth (client_id e client_secret)
  Future<void> configureOAuthCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    _clientId = clientId;
    _clientSecret = clientSecret;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyClientId, clientId);
    await prefs.setString(_keyClientSecret, clientSecret);
  }

  /// Avvia il flusso OAuth2 per Gmail
  /// Restituisce null se successo, altrimenti messaggio di errore
  Future<String?> signInWithGoogle() async {
    if (!isConfigured) {
      return 'OAuth non configurato. Configura prima le credenziali Google Cloud.';
    }

    try {
      // Porta per il server locale di callback
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://localhost:$port/callback';

      // Genera URL di autorizzazione
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _clientId!,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
      });

      // Apri il browser
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        await server.close();
        return 'Impossibile aprire il browser';
      }

      // Aspetta il callback
      final completer = Completer<String?>();

      server.listen((request) async {
        if (request.uri.path == '/callback') {
          final code = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];

          // Rispondi al browser
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.html
            ..write(_getCallbackHtml(error == null));
          await request.response.close();
          await server.close();

          if (error != null) {
            completer.complete('Accesso negato: $error');
          } else if (code != null) {
            // Scambia il codice per i token
            final tokenError = await _exchangeCodeForTokens(code, redirectUri);
            completer.complete(tokenError);
          } else {
            completer.complete('Risposta non valida da Google');
          }
        }
      });

      // Timeout dopo 5 minuti
      final result = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          server.close();
          return 'Timeout: accesso non completato in tempo';
        },
      );

      return result;
    } catch (e) {
      return 'Errore durante l\'accesso: ${e.toString()}';
    }
  }

  /// Scambia il codice di autorizzazione per access e refresh token
  Future<String?> _exchangeCodeForTokens(String code, String redirectUri) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId!,
          'client_secret': _clientSecret!,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        return 'Errore token: ${error['error_description'] ?? error['error']}';
      }

      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _refreshToken = data['refresh_token'];

      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));

      // Ottieni info utente
      await _fetchUserInfo();

      // Salva i token
      await _saveTokens();

      return null; // Successo
    } catch (e) {
      return 'Errore nello scambio token: ${e.toString()}';
    }
  }

  /// Rinnova l'access token usando il refresh token
  Future<String?> refreshAccessToken() async {
    if (_refreshToken == null || !isConfigured) {
      return 'Refresh token non disponibile';
    }

    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId!,
          'client_secret': _clientSecret!,
          'refresh_token': _refreshToken!,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode != 200) {
        // Refresh token non valido, l'utente deve ri-autenticarsi
        await signOut();
        return 'Sessione scaduta, effettua nuovamente l\'accesso';
      }

      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];

      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));

      await _saveTokens();
      return null;
    } catch (e) {
      return 'Errore nel rinnovo token: ${e.toString()}';
    }
  }

  /// Ottiene un access token valido (rinnovando se necessario)
  Future<String?> getValidAccessToken() async {
    if (hasValidToken) {
      return _accessToken;
    }

    if (_refreshToken != null) {
      final error = await refreshAccessToken();
      if (error == null) {
        return _accessToken;
      }
    }

    return null;
  }

  /// Ottieni informazioni utente da Google
  Future<void> _fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userEmail = data['email'];
        _userName = data['name'] ?? data['email']?.split('@').first;
      }
    } catch (_) {
      // Ignora errori nel recupero info utente
    }
  }

  /// Salva i token
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();

    if (_accessToken != null) {
      await prefs.setString(_keyAccessToken, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_keyRefreshToken, _refreshToken!);
    }
    if (_tokenExpiry != null) {
      await prefs.setInt(_keyTokenExpiry, _tokenExpiry!.millisecondsSinceEpoch);
    }
    if (_userEmail != null) {
      await prefs.setString(_keyUserEmail, _userEmail!);
    }
    if (_userName != null) {
      await prefs.setString(_keyUserName, _userName!);
    }
  }

  /// Disconnetti l'account Google
  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _userEmail = null;
    _userName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyTokenExpiry);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
  }

  /// HTML da mostrare nel browser dopo il callback
  String _getCallbackHtml(bool success) {
    if (success) {
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>OlderOS - Accesso completato</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
    .container {
      text-align: center;
      padding: 40px;
      background: rgba(255,255,255,0.1);
      border-radius: 20px;
      backdrop-filter: blur(10px);
    }
    h1 { font-size: 2.5em; margin-bottom: 10px; }
    p { font-size: 1.3em; opacity: 0.9; }
    .icon { font-size: 4em; margin-bottom: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">✓</div>
    <h1>Accesso completato!</h1>
    <p>Puoi chiudere questa finestra e tornare a OlderOS.</p>
  </div>
</body>
</html>
''';
    } else {
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>OlderOS - Errore</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
      color: white;
    }
    .container {
      text-align: center;
      padding: 40px;
      background: rgba(255,255,255,0.1);
      border-radius: 20px;
    }
    h1 { font-size: 2em; margin-bottom: 10px; }
    p { font-size: 1.2em; opacity: 0.9; }
    .icon { font-size: 4em; margin-bottom: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">✗</div>
    <h1>Accesso non riuscito</h1>
    <p>Torna a OlderOS e riprova.</p>
  </div>
</body>
</html>
''';
    }
  }
}
