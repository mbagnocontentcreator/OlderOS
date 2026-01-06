import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'email_service.dart';

/// Modello per un account email salvato
class SavedEmailAccount {
  final String id;
  final String email;
  final String displayName;
  final EmailAuthType authType;
  final String? password;
  final String? imapHost;
  final int? imapPort;
  final String? smtpHost;
  final int? smtpPort;
  final DateTime addedAt;

  const SavedEmailAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.authType,
    this.password,
    this.imapHost,
    this.imapPort,
    this.smtpHost,
    this.smtpPort,
    required this.addedAt,
  });

  factory SavedEmailAccount.fromJson(Map<String, dynamic> json) {
    return SavedEmailAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      authType: json['authType'] == 'oauth2' ? EmailAuthType.oauth2 : EmailAuthType.password,
      password: json['password'] as String?,
      imapHost: json['imapHost'] as String?,
      imapPort: json['imapPort'] as int?,
      smtpHost: json['smtpHost'] as String?,
      smtpPort: json['smtpPort'] as int?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'authType': authType == EmailAuthType.oauth2 ? 'oauth2' : 'password',
      'password': password,
      'imapHost': imapHost,
      'imapPort': imapPort,
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  /// Crea un account dalla email corrente del servizio
  static SavedEmailAccount fromEmailService(EmailService service) {
    return SavedEmailAccount(
      id: 'account_${DateTime.now().millisecondsSinceEpoch}',
      email: service.userEmail ?? '',
      displayName: service.userName ?? '',
      authType: service.authType ?? EmailAuthType.password,
      addedAt: DateTime.now(),
    );
  }

  /// Iniziali per l'avatar
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }
}

/// Servizio per gestire piu account email
class EmailAccountsService {
  static final EmailAccountsService _instance = EmailAccountsService._internal();
  factory EmailAccountsService() => _instance;
  EmailAccountsService._internal();

  static const _keyAccounts = 'email_accounts_list';
  static const _keyActiveAccount = 'email_active_account_id';

  List<SavedEmailAccount> _accounts = [];
  String? _activeAccountId;
  bool _isLoaded = false;

  /// Lista degli account
  List<SavedEmailAccount> get accounts => List.unmodifiable(_accounts);

  /// Numero di account
  int get count => _accounts.length;

  /// Account attivo corrente
  SavedEmailAccount? get activeAccount {
    if (_activeAccountId == null || _accounts.isEmpty) return null;
    try {
      return _accounts.firstWhere((a) => a.id == _activeAccountId);
    } catch (_) {
      return _accounts.isNotEmpty ? _accounts.first : null;
    }
  }

  /// Carica gli account salvati
  Future<void> loadAccounts() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();

    // Carica lista account
    final jsonString = prefs.getString(_keyAccounts);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        _accounts = jsonList
            .map((e) => SavedEmailAccount.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _accounts = [];
      }
    }

    // Carica account attivo
    _activeAccountId = prefs.getString(_keyActiveAccount);

    _isLoaded = true;
  }

  /// Salva gli account
  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_keyAccounts, jsonString);
  }

  /// Aggiunge un nuovo account
  Future<void> addAccount(SavedEmailAccount account) async {
    await loadAccounts();

    // Verifica se l'account esiste gia
    final existingIndex = _accounts.indexWhere((a) => a.email == account.email);
    if (existingIndex != -1) {
      // Aggiorna l'account esistente
      _accounts[existingIndex] = account;
    } else {
      _accounts.add(account);
    }

    // Se e' il primo account, impostalo come attivo
    if (_accounts.length == 1) {
      _activeAccountId = account.id;
      await _setActiveAccountId(account.id);
    }

    await _saveAccounts();
  }

  /// Rimuove un account
  Future<void> removeAccount(String accountId) async {
    await loadAccounts();

    _accounts.removeWhere((a) => a.id == accountId);

    // Se abbiamo rimosso l'account attivo, seleziona il primo disponibile
    if (_activeAccountId == accountId) {
      _activeAccountId = _accounts.isNotEmpty ? _accounts.first.id : null;
      if (_activeAccountId != null) {
        await _setActiveAccountId(_activeAccountId!);
      }
    }

    await _saveAccounts();
  }

  /// Imposta l'account attivo
  Future<void> setActiveAccount(String accountId) async {
    await loadAccounts();

    final account = _accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => throw Exception('Account non trovato'),
    );

    _activeAccountId = account.id;
    await _setActiveAccountId(account.id);
  }

  Future<void> _setActiveAccountId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveAccount, id);
    _activeAccountId = id;
  }

  /// Verifica se l'email esiste gia
  bool emailExists(String email) {
    return _accounts.any((a) => a.email.toLowerCase() == email.toLowerCase());
  }

  /// Trova un account per email
  SavedEmailAccount? findByEmail(String email) {
    try {
      return _accounts.firstWhere(
        (a) => a.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Ricarica forzatamente
  Future<void> reload() async {
    _isLoaded = false;
    await loadAccounts();
  }
}
