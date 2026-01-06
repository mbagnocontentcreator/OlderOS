import 'package:shared_preferences/shared_preferences.dart';

/// Servizio per gestire il primo avvio e le impostazioni utente
class FirstRunService {
  static final FirstRunService _instance = FirstRunService._internal();
  factory FirstRunService() => _instance;
  FirstRunService._internal();

  // Chiavi per SharedPreferences
  static const _keyFirstRunComplete = 'first_run_complete';
  static const _keyUserName = 'user_name';
  static const _keyUserAvatar = 'user_avatar_color';

  bool _isFirstRun = true;
  String _userName = '';
  int _avatarColorIndex = 0;

  /// Indica se il setup iniziale e' stato completato
  bool get isFirstRun => _isFirstRun;

  /// Nome dell'utente
  String get userName => _userName;

  /// Indice del colore avatar
  int get avatarColorIndex => _avatarColorIndex;

  /// Inizializza il servizio caricando lo stato salvato
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _isFirstRun = !(prefs.getBool(_keyFirstRunComplete) ?? false);
    _userName = prefs.getString(_keyUserName) ?? '';
    _avatarColorIndex = prefs.getInt(_keyUserAvatar) ?? 0;
  }

  /// Salva il nome utente
  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    _userName = name;
  }

  /// Salva il colore avatar
  Future<void> setAvatarColor(int colorIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserAvatar, colorIndex);
    _avatarColorIndex = colorIndex;
  }

  /// Marca il setup come completato
  Future<void> completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstRunComplete, true);
    _isFirstRun = false;
  }

  /// Reset del primo avvio (per testing)
  Future<void> resetFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstRunComplete, false);
    _isFirstRun = true;
  }
}
