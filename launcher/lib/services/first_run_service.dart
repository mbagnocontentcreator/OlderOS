import 'package:shared_preferences/shared_preferences.dart';
import '../utils/user_key_provider.dart';

/// Servizio per gestire il primo avvio e le impostazioni utente
class FirstRunService with UserKeyProvider {
  static final FirstRunService _instance = FirstRunService._internal();
  factory FirstRunService() => _instance;
  FirstRunService._internal();

  // Chiavi base per SharedPreferences (verranno prefissate con user_id)
  static const _baseKeyFirstRunComplete = 'first_run_complete';
  static const _baseKeyUserName = 'user_name';
  static const _baseKeyUserAvatar = 'user_avatar_color';

  // Getter per chiavi prefissate
  String get _keyFirstRunComplete => getUserKey(_baseKeyFirstRunComplete);
  String get _keyUserName => getUserKey(_baseKeyUserName);
  String get _keyUserAvatar => getUserKey(_baseKeyUserAvatar);

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

  /// Ricarica i dati per l'utente corrente (chiamare dopo cambio utente)
  Future<void> reload() async {
    _isFirstRun = true;
    _userName = '';
    _avatarColorIndex = 0;
    await initialize();
  }

  /// Resetta lo stato interno (usato al logout)
  void resetState() {
    _isFirstRun = true;
    _userName = '';
    _avatarColorIndex = 0;
  }
}
