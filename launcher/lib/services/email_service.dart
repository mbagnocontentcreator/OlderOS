import 'dart:async';
import 'package:enough_mail/enough_mail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_auth_service.dart';

/// Tipo di autenticazione email
enum EmailAuthType {
  password,  // Login tradizionale con password
  oauth2,    // OAuth2 (Google, etc.)
}

/// Modello per le credenziali email
class EmailCredentials {
  final String email;
  final String? password;
  final String displayName;
  final EmailAuthType authType;
  final String? imapHost;
  final int? imapPort;
  final String? smtpHost;
  final int? smtpPort;

  const EmailCredentials({
    required this.email,
    this.password,
    required this.displayName,
    required this.authType,
    this.imapHost,
    this.imapPort,
    this.smtpHost,
    this.smtpPort,
  });
}

/// Modello email semplificato per OlderOS
class EmailMessage {
  final String id;
  final String senderName;
  final String senderEmail;
  final String subject;
  final String preview;
  final String body;
  final DateTime date;
  final bool isRead;
  final bool isSent;
  final int? uid;

  const EmailMessage({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.subject,
    required this.preview,
    required this.body,
    required this.date,
    this.isRead = false,
    this.isSent = false,
    this.uid,
  });

  EmailMessage copyWith({bool? isRead}) {
    return EmailMessage(
      id: id,
      senderName: senderName,
      senderEmail: senderEmail,
      subject: subject,
      preview: preview,
      body: body,
      date: date,
      isRead: isRead ?? this.isRead,
      isSent: isSent,
      uid: uid,
    );
  }
}

/// Servizio per gestire email IMAP/SMTP
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  MailClient? _mailClient;
  EmailCredentials? _credentials;
  MailAccount? _mailAccount;
  final _googleAuth = GoogleAuthService();

  bool _isConfigured = false;
  bool _isConnected = false;

  bool get isConfigured => _isConfigured;
  bool get isConnected => _isConnected;
  String? get userEmail => _credentials?.email ?? _googleAuth.userEmail;
  String? get userName => _credentials?.displayName ?? _googleAuth.userName;
  EmailAuthType? get authType => _credentials?.authType;
  bool get isGoogleAuth => _credentials?.authType == EmailAuthType.oauth2;

  // Chiavi per SharedPreferences
  static const _keyEmail = 'email_account_email';
  static const _keyPassword = 'email_account_password';
  static const _keyDisplayName = 'email_account_display_name';
  static const _keyAuthType = 'email_account_auth_type';
  static const _keyImapHost = 'email_account_imap_host';
  static const _keyImapPort = 'email_account_imap_port';
  static const _keySmtpHost = 'email_account_smtp_host';
  static const _keySmtpPort = 'email_account_smtp_port';

  /// Carica credenziali salvate
  Future<bool> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    final displayName = prefs.getString(_keyDisplayName);
    final authTypeStr = prefs.getString(_keyAuthType);

    if (email == null || displayName == null || authTypeStr == null) {
      return false;
    }

    final authType = authTypeStr == 'oauth2' ? EmailAuthType.oauth2 : EmailAuthType.password;

    if (authType == EmailAuthType.oauth2) {
      // Carica anche i token Google
      final hasGoogleAuth = await _googleAuth.loadSavedCredentials();
      if (!hasGoogleAuth) {
        return false;
      }

      _credentials = EmailCredentials(
        email: email,
        displayName: displayName,
        authType: EmailAuthType.oauth2,
      );
      _isConfigured = true;
      return true;
    } else {
      // Autenticazione con password
      final password = prefs.getString(_keyPassword);
      if (password == null) {
        return false;
      }

      _credentials = EmailCredentials(
        email: email,
        password: password,
        displayName: displayName,
        authType: EmailAuthType.password,
        imapHost: prefs.getString(_keyImapHost),
        imapPort: prefs.getInt(_keyImapPort),
        smtpHost: prefs.getString(_keySmtpHost),
        smtpPort: prefs.getInt(_keySmtpPort),
      );
      _isConfigured = true;
      return true;
    }
  }

  /// Salva credenziali
  Future<void> _saveCredentials(EmailCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, credentials.email);
    await prefs.setString(_keyDisplayName, credentials.displayName);
    await prefs.setString(_keyAuthType, credentials.authType == EmailAuthType.oauth2 ? 'oauth2' : 'password');

    if (credentials.password != null) {
      await prefs.setString(_keyPassword, credentials.password!);
    }
    if (credentials.imapHost != null) {
      await prefs.setString(_keyImapHost, credentials.imapHost!);
    }
    if (credentials.imapPort != null) {
      await prefs.setInt(_keyImapPort, credentials.imapPort!);
    }
    if (credentials.smtpHost != null) {
      await prefs.setString(_keySmtpHost, credentials.smtpHost!);
    }
    if (credentials.smtpPort != null) {
      await prefs.setInt(_keySmtpPort, credentials.smtpPort!);
    }
  }

  /// Configura OAuth2 per Google
  Future<void> configureGoogleOAuth({
    required String clientId,
    required String clientSecret,
  }) async {
    await _googleAuth.configureOAuthCredentials(
      clientId: clientId,
      clientSecret: clientSecret,
    );
  }

  /// Verifica se OAuth Google e' configurato
  bool get isGoogleOAuthConfigured => _googleAuth.isConfigured;

  /// Accedi con Google OAuth2
  Future<String?> signInWithGoogle() async {
    final error = await _googleAuth.signInWithGoogle();
    if (error != null) {
      return error;
    }

    // Crea le credenziali
    _credentials = EmailCredentials(
      email: _googleAuth.userEmail!,
      displayName: _googleAuth.userName ?? _googleAuth.userEmail!.split('@').first,
      authType: EmailAuthType.oauth2,
    );

    // Prova a connettersi
    final connectError = await _connectWithOAuth();
    if (connectError != null) {
      _credentials = null;
      return connectError;
    }

    await _saveCredentials(_credentials!);
    _isConfigured = true;

    return null;
  }

  /// Configura account con password (auto-discovery)
  Future<String?> configureAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final config = await Discover.discover(email);

      if (config == null) {
        return 'Non riesco a trovare le impostazioni per questa email. Prova con Gmail, Outlook o Libero.';
      }

      _mailAccount = MailAccount.fromDiscoveredSettings(
        name: displayName,
        userName: displayName,
        email: email,
        password: password,
        config: config,
      );

      _credentials = EmailCredentials(
        email: email,
        password: password,
        displayName: displayName,
        authType: EmailAuthType.password,
      );

      final connectResult = await _connect();
      if (connectResult != null) {
        _mailAccount = null;
        _credentials = null;
        return connectResult;
      }

      await _saveCredentials(_credentials!);
      _isConfigured = true;

      return null;
    } catch (e) {
      return 'Errore di configurazione: ${_simplifyError(e.toString())}';
    }
  }

  /// Connessione con password
  Future<String?> _connect() async {
    if (_mailAccount == null) return 'Account non configurato';

    try {
      _mailClient = MailClient(_mailAccount!, isLogEnabled: false);
      await _mailClient!.connect();
      _isConnected = true;
      return null;
    } catch (e) {
      _mailClient = null;
      return _simplifyError(e.toString());
    }
  }

  /// Connessione con OAuth2
  Future<String?> _connectWithOAuth() async {
    if (_credentials == null || _credentials!.authType != EmailAuthType.oauth2) {
      return 'Credenziali OAuth non disponibili';
    }

    try {
      final accessToken = await _googleAuth.getValidAccessToken();
      if (accessToken == null) {
        return 'Token di accesso non disponibile. Effettua nuovamente l\'accesso.';
      }

      // Crea account con autenticazione OAuth2
      _mailAccount = MailAccount(
        name: _credentials!.displayName,
        email: _credentials!.email,
        userName: _credentials!.displayName,
        incoming: MailServerConfig(
          serverConfig: ServerConfig(
            type: ServerType.imap,
            hostname: 'imap.gmail.com',
            port: 993,
            socketType: SocketType.ssl,
            authentication: Authentication.oauth2,
            usernameType: UsernameType.emailAddress,
          ),
          authentication: PlainAuthentication(_credentials!.email, accessToken),
        ),
        outgoing: MailServerConfig(
          serverConfig: ServerConfig(
            type: ServerType.smtp,
            hostname: 'smtp.gmail.com',
            port: 465,
            socketType: SocketType.ssl,
            authentication: Authentication.oauth2,
            usernameType: UsernameType.emailAddress,
          ),
          authentication: PlainAuthentication(_credentials!.email, accessToken),
        ),
      );

      _mailClient = MailClient(_mailAccount!, isLogEnabled: false);
      await _mailClient!.connect();
      _isConnected = true;
      return null;
    } catch (e) {
      _mailClient = null;
      return _simplifyError(e.toString());
    }
  }

  /// Riconnetti se necessario
  Future<String?> ensureConnected() async {
    if (_isConnected && _mailClient != null) {
      return null;
    }

    if (_credentials?.authType == EmailAuthType.oauth2) {
      return await _connectWithOAuth();
    }

    if (_mailAccount != null) {
      return await _connect();
    }

    // Ricostruisci mailAccount dalle credenziali
    if (_credentials != null && _credentials!.password != null) {
      try {
        final config = await Discover.discover(_credentials!.email);
        if (config != null) {
          _mailAccount = MailAccount.fromDiscoveredSettings(
            name: _credentials!.displayName,
            userName: _credentials!.displayName,
            email: _credentials!.email,
            password: _credentials!.password!,
            config: config,
          );
          return await _connect();
        }
      } catch (e) {
        return _simplifyError(e.toString());
      }
    }

    return 'Account non configurato';
  }

  /// Recupera email dalla inbox
  Future<List<EmailMessage>> fetchInbox({int limit = 50}) async {
    final connectError = await ensureConnected();
    if (connectError != null) {
      throw Exception(connectError);
    }

    try {
      await _mailClient!.selectInbox();

      final messages = await _mailClient!.fetchMessages(count: limit);

      final emails = <EmailMessage>[];
      for (final msg in messages) {
        final from = msg.from?.isNotEmpty == true ? msg.from!.first : null;
        final senderName = from?.personalName ?? from?.email ?? 'Sconosciuto';
        final senderEmail = from?.email ?? '';

        String body = '';
        String preview = '';

        try {
          final fullMsg = await _mailClient!.fetchMessageContents(msg);
          body = fullMsg.decodeTextPlainPart() ?? '';
          if (body.isEmpty) {
            body = _cleanHtml(fullMsg.decodeTextHtmlPart() ?? '');
          }
          preview = body.length > 100 ? '${body.substring(0, 100)}...' : body;
        } catch (_) {
          preview = '(Contenuto non disponibile)';
        }

        final isRead = msg.isSeen;

        emails.add(EmailMessage(
          id: 'inbox_${msg.uid ?? msg.sequenceId}',
          senderName: senderName,
          senderEmail: senderEmail,
          subject: msg.decodeSubject() ?? '(Nessun oggetto)',
          preview: preview.replaceAll('\n', ' ').trim(),
          body: body,
          date: msg.decodeDate() ?? DateTime.now(),
          isRead: isRead,
          isSent: false,
          uid: msg.uid,
        ));
      }

      return emails;
    } catch (e) {
      throw Exception('Errore nel recupero delle email: ${_simplifyError(e.toString())}');
    }
  }

  /// Recupera email inviate
  Future<List<EmailMessage>> fetchSent({int limit = 30}) async {
    final connectError = await ensureConnected();
    if (connectError != null) {
      throw Exception(connectError);
    }

    try {
      final mailboxes = await _mailClient!.listMailboxes();

      Mailbox? sentBox;
      for (final box in mailboxes) {
        final name = box.name.toLowerCase();
        if (name == 'sent' || name == 'sent messages' || name == 'sent mail' ||
            name == 'inviati' || name.contains('sent') ||
            name == '[gmail]/sent mail' || name == '[gmail]/posta inviata') {
          sentBox = box;
          break;
        }
      }

      if (sentBox == null) {
        return [];
      }

      await _mailClient!.selectMailbox(sentBox);

      final messages = await _mailClient!.fetchMessages(count: limit);

      final emails = <EmailMessage>[];
      for (final msg in messages) {
        final to = msg.to?.isNotEmpty == true ? msg.to!.first : null;
        final recipientName = to?.personalName ?? to?.email ?? 'Destinatario';
        final recipientEmail = to?.email ?? '';

        String body = '';
        String preview = '';

        try {
          final fullMsg = await _mailClient!.fetchMessageContents(msg);
          body = fullMsg.decodeTextPlainPart() ?? '';
          if (body.isEmpty) {
            body = _cleanHtml(fullMsg.decodeTextHtmlPart() ?? '');
          }
          preview = body.length > 100 ? '${body.substring(0, 100)}...' : body;
        } catch (_) {
          preview = '(Contenuto non disponibile)';
        }

        emails.add(EmailMessage(
          id: 'sent_${msg.uid ?? msg.sequenceId}',
          senderName: 'A: $recipientName',
          senderEmail: recipientEmail,
          subject: msg.decodeSubject() ?? '(Nessun oggetto)',
          preview: preview.replaceAll('\n', ' ').trim(),
          body: body,
          date: msg.decodeDate() ?? DateTime.now(),
          isRead: true,
          isSent: true,
          uid: msg.uid,
        ));
      }

      return emails;
    } catch (e) {
      return [];
    }
  }

  /// Segna email come letta
  Future<void> markAsRead(EmailMessage email) async {
    if (email.uid == null || email.isSent) return;

    try {
      await ensureConnected();
      await _mailClient!.selectInbox();
      await _mailClient!.flagMessage(
        MimeMessage()..uid = email.uid,
        isSeen: true,
      );
    } catch (_) {}
  }

  /// Elimina email
  Future<void> deleteEmail(EmailMessage email) async {
    if (email.uid == null) return;

    try {
      await ensureConnected();
      if (!email.isSent) {
        await _mailClient!.selectInbox();
      }
      await _mailClient!.deleteMessage(
        MimeMessage()..uid = email.uid,
      );
    } catch (_) {}
  }

  /// Invia email
  Future<String?> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    if (_credentials == null && _mailAccount == null) {
      return 'Account non configurato';
    }

    try {
      await ensureConnected();

      final builder = MessageBuilder.prepareMultipartAlternativeMessage();
      builder.from = [MailAddress(
        _credentials?.displayName ?? '',
        _credentials?.email ?? _mailAccount!.email,
      )];
      builder.to = [MailAddress(null, to)];
      builder.subject = subject;
      builder.addTextPlain(body);

      final message = builder.buildMimeMessage();

      await _mailClient!.sendMessage(message);

      return null;
    } catch (e) {
      return 'Errore nell\'invio: ${_simplifyError(e.toString())}';
    }
  }

  /// Disconnetti
  Future<void> disconnect() async {
    try {
      await _mailClient?.disconnect();
    } catch (_) {}
    _mailClient = null;
    _isConnected = false;
  }

  /// Rimuovi account
  Future<void> removeAccount() async {
    await disconnect();

    // Se era OAuth, disconnetti anche da Google
    if (_credentials?.authType == EmailAuthType.oauth2) {
      await _googleAuth.signOut();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyAuthType);
    await prefs.remove(_keyImapHost);
    await prefs.remove(_keyImapPort);
    await prefs.remove(_keySmtpHost);
    await prefs.remove(_keySmtpPort);

    _credentials = null;
    _mailAccount = null;
    _isConfigured = false;
  }

  String _simplifyError(String error) {
    error = error.toLowerCase();

    if (error.contains('authentication') || error.contains('login') || error.contains('password')) {
      return 'Email o password non corretti';
    }
    if (error.contains('connection') || error.contains('socket') || error.contains('timeout')) {
      return 'Impossibile connettersi. Verifica la connessione internet.';
    }
    if (error.contains('certificate') || error.contains('ssl') || error.contains('tls')) {
      return 'Problema di sicurezza con il server email';
    }
    if (error.contains('mailbox') || error.contains('folder')) {
      return 'Cartella email non trovata';
    }
    if (error.contains('oauth') || error.contains('token')) {
      return 'Problema con l\'autenticazione Google. Riprova ad accedere.';
    }

    return 'Si e verificato un problema. Riprova.';
  }

  String _cleanHtml(String text) {
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'<p[^>]*>'), '\n');
    text = text.replaceAll(RegExp(r'</p>'), '\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}
