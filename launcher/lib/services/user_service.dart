import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modello per un utente di OlderOS
class User {
  final String id;
  final String name;
  final String pinHash;
  final int avatarColorIndex;
  final DateTime createdAt;
  DateTime lastLoginAt;

  User({
    required this.id,
    required this.name,
    required this.pinHash,
    required this.avatarColorIndex,
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// Crea un nuovo utente con PIN
  factory User.create({
    required String name,
    required String pin,
    required int avatarColorIndex,
  }) {
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final pinHash = _hashPin(pin, id);
    final now = DateTime.now();

    return User(
      id: id,
      name: name,
      pinHash: pinHash,
      avatarColorIndex: avatarColorIndex,
      createdAt: now,
      lastLoginAt: now,
    );
  }

  /// Verifica se il PIN inserito e' corretto
  bool verifyPin(String pin) {
    return _hashPin(pin, id) == pinHash;
  }

  /// Iniziali dell'utente per l'avatar
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Serializza l'utente in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pinHash': pinHash,
      'avatarColorIndex': avatarColorIndex,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  /// Deserializza l'utente da JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      pinHash: json['pinHash'] as String,
      avatarColorIndex: json['avatarColorIndex'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
    );
  }

  /// Hash del PIN con SHA-256 e salt basato sull'ID utente
  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Servizio per la gestione degli utenti di OlderOS
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Chiavi SharedPreferences (globali, non prefissate)
  static const _keyUsersList = 'olderos_users_list';
  static const _keyLastActiveUser = 'olderos_last_active_user';
  static const _keyFailedAttempts = 'olderos_failed_attempts';
  static const _keyLockoutUntil = 'olderos_lockout_until';

  // Costanti
  static const int maxUsers = 4;
  static const int minPinLength = 4;
  static const int maxPinLength = 6;
  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  // Stato
  List<User> _users = [];
  User? _currentUser;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  // Notifier per cambio utente
  final ValueNotifier<User?> currentUserNotifier = ValueNotifier(null);

  /// Lista di tutti gli utenti
  List<User> get users => List.unmodifiable(_users);

  /// Utente corrente loggato
  User? get currentUser => _currentUser;

  /// Verifica se ci sono utenti registrati
  bool get hasUsers => _users.isNotEmpty;

  /// Verifica se si possono aggiungere altri utenti
  bool get canAddUser => _users.length < maxUsers;

  /// Numero di utenti registrati
  int get userCount => _users.length;

  /// Verifica se l'accesso e' bloccato per troppi tentativi
  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  /// Tempo rimanente del blocco
  Duration get lockoutRemaining {
    if (_lockoutUntil == null) return Duration.zero;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Tentativi rimanenti prima del blocco
  int get remainingAttempts => maxAttempts - _failedAttempts;

  /// Inizializza il servizio caricando gli utenti salvati
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Carica lista utenti
    final usersJson = prefs.getString(_keyUsersList);
    if (usersJson != null) {
      try {
        final List<dynamic> usersList = jsonDecode(usersJson);
        _users = usersList.map((json) => User.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Errore caricamento utenti: $e');
        _users = [];
      }
    }

    // Carica stato blocco
    _failedAttempts = prefs.getInt(_keyFailedAttempts) ?? 0;
    final lockoutMs = prefs.getInt(_keyLockoutUntil);
    if (lockoutMs != null) {
      _lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutMs);
      if (DateTime.now().isAfter(_lockoutUntil!)) {
        _lockoutUntil = null;
        _failedAttempts = 0;
      }
    }
  }

  /// Crea un nuovo utente
  Future<User> createUser({
    required String name,
    required String pin,
    required int avatarColorIndex,
  }) async {
    if (!canAddUser) {
      throw Exception('Numero massimo di utenti raggiunto ($maxUsers)');
    }

    if (pin.length < minPinLength || pin.length > maxPinLength) {
      throw Exception('Il PIN deve avere tra $minPinLength e $maxPinLength cifre');
    }

    final user = User.create(
      name: name,
      pin: pin,
      avatarColorIndex: avatarColorIndex,
    );

    _users.add(user);
    await _saveUsers();

    return user;
  }

  /// Aggiorna un utente esistente
  Future<void> updateUser(User updatedUser) async {
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index == -1) {
      throw Exception('Utente non trovato');
    }

    _users[index] = updatedUser;
    await _saveUsers();

    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
      currentUserNotifier.value = updatedUser;
    }
  }

  /// Elimina un utente e tutti i suoi dati
  Future<void> deleteUser(String userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) {
      throw Exception('Utente non trovato');
    }

    // Elimina i dati dell'utente
    await _deleteUserData(userId);

    // Rimuovi dalla lista
    _users.removeAt(index);
    await _saveUsers();

    // Se era l'utente corrente, effettua logout
    if (_currentUser?.id == userId) {
      await logout();
    }
  }

  /// Verifica il PIN e effettua il login
  Future<bool> login(String userId, String pin) async {
    if (isLockedOut) {
      return false;
    }

    final user = _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw Exception('Utente non trovato'),
    );

    if (user.verifyPin(pin)) {
      // Login riuscito
      _failedAttempts = 0;
      _lockoutUntil = null;
      await _clearLockoutState();

      user.lastLoginAt = DateTime.now();
      await _saveUsers();
      await _saveLastActiveUser(userId);

      _currentUser = user;
      currentUserNotifier.value = user;

      return true;
    } else {
      // Login fallito
      _failedAttempts++;
      await _saveFailedAttempts();

      if (_failedAttempts >= maxAttempts) {
        _lockoutUntil = DateTime.now().add(lockoutDuration);
        await _saveLockoutState();
      }

      return false;
    }
  }

  /// Effettua il logout dell'utente corrente
  Future<void> logout() async {
    _currentUser = null;
    currentUserNotifier.value = null;
  }

  /// Cambia il PIN di un utente
  Future<void> changePin(String userId, String oldPin, String newPin) async {
    final user = _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw Exception('Utente non trovato'),
    );

    if (!user.verifyPin(oldPin)) {
      throw Exception('PIN attuale non corretto');
    }

    if (newPin.length < minPinLength || newPin.length > maxPinLength) {
      throw Exception('Il nuovo PIN deve avere tra $minPinLength e $maxPinLength cifre');
    }

    final newPinHash = User._hashPin(newPin, userId);
    final updatedUser = User(
      id: user.id,
      name: user.name,
      pinHash: newPinHash,
      avatarColorIndex: user.avatarColorIndex,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );

    await updateUser(updatedUser);
  }

  /// Trova un utente per ID
  User? findById(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// Ottiene l'ultimo utente attivo
  Future<User?> getLastActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUserId = prefs.getString(_keyLastActiveUser);
    if (lastUserId == null) return null;
    return findById(lastUserId);
  }

  /// Migra i dati esistenti (pre-multiutenza) al primo utente
  Future<void> migrateExistingData(String newUserId) async {
    final prefs = await SharedPreferences.getInstance();

    // Lista di tutte le chiavi da migrare
    final keysToMigrate = [
      // FirstRunService
      'first_run_complete',
      'user_name',
      'user_avatar_color',
      // ContactService
      'contacts_list',
      // EmailService
      'email_account_email',
      'email_account_password',
      'email_account_display_name',
      'email_account_auth_type',
      'email_account_imap_host',
      'email_account_imap_port',
      'email_account_smtp_host',
      'email_account_smtp_port',
      // EmailAccountsService
      'email_accounts_list',
      'email_active_account_id',
      // GoogleAuthService
      'google_oauth_client_id',
      'google_oauth_client_secret',
      'google_oauth_access_token',
      'google_oauth_refresh_token',
      'google_oauth_token_expiry',
      'google_oauth_user_email',
      'google_oauth_user_name',
      // DraftService
      'email_drafts',
      // EmailNotificationService
      'email_last_seen_timestamp',
      // PhotosScreen
      'photos_folder_path',
    ];

    for (final key in keysToMigrate) {
      final value = prefs.get(key);
      if (value != null) {
        final newKey = '${newUserId}_$key';

        // Copia al nuovo key in base al tipo
        if (value is String) {
          await prefs.setString(newKey, value);
        } else if (value is int) {
          await prefs.setInt(newKey, value);
        } else if (value is bool) {
          await prefs.setBool(newKey, value);
        } else if (value is double) {
          await prefs.setDouble(newKey, value);
        }

        // Rimuovi vecchia chiave
        await prefs.remove(key);
      }
    }

    debugPrint('Migrazione dati completata per utente $newUserId');
  }

  /// Verifica se esistono dati pre-multiutenza da migrare
  Future<bool> hasLegacyData() async {
    final prefs = await SharedPreferences.getInstance();
    // Controlla se esiste almeno una delle chiavi legacy
    return prefs.containsKey('first_run_complete') ||
        prefs.containsKey('user_name') ||
        prefs.containsKey('contacts_list') ||
        prefs.containsKey('email_account_email');
  }

  // Metodi privati

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = jsonEncode(_users.map((u) => u.toJson()).toList());
    await prefs.setString(_keyUsersList, usersJson);
  }

  Future<void> _saveLastActiveUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastActiveUser, userId);
  }

  Future<void> _saveFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFailedAttempts, _failedAttempts);
  }

  Future<void> _saveLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lockoutUntil != null) {
      await prefs.setInt(_keyLockoutUntil, _lockoutUntil!.millisecondsSinceEpoch);
    }
  }

  Future<void> _clearLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFailedAttempts);
    await prefs.remove(_keyLockoutUntil);
  }

  Future<void> _deleteUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    // Trova tutte le chiavi che appartengono a questo utente
    final userKeys = allKeys.where((key) => key.startsWith('${userId}_'));

    for (final key in userKeys) {
      await prefs.remove(key);
    }

    debugPrint('Eliminati ${userKeys.length} dati per utente $userId');
  }
}
