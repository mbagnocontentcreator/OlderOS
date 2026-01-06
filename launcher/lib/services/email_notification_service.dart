import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'email_service.dart';

/// Callback per quando arrivano nuove email
typedef OnNewEmailsCallback = void Function(int newCount, List<EmailMessage> newEmails);

/// Servizio per controllare e notificare nuove email
class EmailNotificationService {
  static final EmailNotificationService _instance = EmailNotificationService._internal();
  factory EmailNotificationService() => _instance;
  EmailNotificationService._internal();

  final _emailService = EmailService();
  Timer? _checkTimer;
  bool _isChecking = false;

  // Chiave per salvare l'ultimo timestamp
  static const _keyLastSeenTimestamp = 'email_last_seen_timestamp';

  // Intervallo di controllo (30 secondi)
  static const _checkInterval = Duration(seconds: 30);

  // Callbacks per notifiche
  final List<OnNewEmailsCallback> _callbacks = [];

  /// Ultimo timestamp email visto
  DateTime? _lastSeenTimestamp;

  /// Numero di nuove email dall'ultimo controllo
  int _newEmailCount = 0;
  int get newEmailCount => _newEmailCount;

  /// Inizializza il servizio
  Future<void> initialize() async {
    await _loadLastSeen();
  }

  /// Carica l'ultimo stato salvato
  Future<void> _loadLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastSeenTimestamp);
    if (timestamp != null) {
      _lastSeenTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  /// Salva lo stato corrente
  Future<void> _saveLastSeen(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSeenTimestamp, timestamp.millisecondsSinceEpoch);
    _lastSeenTimestamp = timestamp;
  }

  /// Registra un callback per le notifiche
  void addListener(OnNewEmailsCallback callback) {
    _callbacks.add(callback);
  }

  /// Rimuove un callback
  void removeListener(OnNewEmailsCallback callback) {
    _callbacks.remove(callback);
  }

  /// Avvia il controllo periodico
  void startChecking() {
    if (_checkTimer != null) return;

    _checkTimer = Timer.periodic(_checkInterval, (_) {
      checkForNewEmails();
    });

    // Controlla subito
    checkForNewEmails();
  }

  /// Ferma il controllo periodico
  void stopChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Controlla se ci sono nuove email
  Future<void> checkForNewEmails() async {
    if (_isChecking) return;
    if (!_emailService.isConfigured) return;

    _isChecking = true;

    try {
      final emails = await _emailService.fetchInbox(limit: 10);

      if (emails.isEmpty) {
        _isChecking = false;
        return;
      }

      // Trova le nuove email (non lette e dopo l'ultimo check)
      final newEmails = <EmailMessage>[];

      for (final email in emails) {
        // Se non abbiamo mai visto email, considera tutte come "viste"
        if (_lastSeenTimestamp == null) {
          break;
        }

        // Se l'email e' piu' recente dell'ultimo check e non e' letta
        if (email.date.isAfter(_lastSeenTimestamp!) && !email.isRead) {
          newEmails.add(email);
        }
      }

      if (newEmails.isNotEmpty) {
        _newEmailCount = newEmails.length;

        // Notifica i listener
        for (final callback in _callbacks) {
          callback(_newEmailCount, newEmails);
        }
      }

      // Aggiorna l'ultimo check
      if (emails.isNotEmpty) {
        await _saveLastSeen(DateTime.now());
      }
    } catch (e) {
      // Ignora errori durante il check
    } finally {
      _isChecking = false;
    }
  }

  /// Marca tutte le email come viste (reset del contatore)
  Future<void> markAllAsSeen() async {
    _newEmailCount = 0;
    await _saveLastSeen(DateTime.now());
  }

  /// Reset del contatore nuove email
  void resetNewCount() {
    _newEmailCount = 0;
  }

  /// Dispose del servizio
  void dispose() {
    stopChecking();
    _callbacks.clear();
  }
}

/// Widget per mostrare il badge delle nuove email
class NewEmailBadge extends StatelessWidget {
  final int count;
  final double size;

  const NewEmailBadge({
    super.key,
    required this.count,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(size / 4),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
