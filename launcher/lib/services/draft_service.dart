import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modello per una bozza email
class EmailDraft {
  final String id;
  final String to;
  final String subject;
  final String body;
  final DateTime lastModified;

  const EmailDraft({
    required this.id,
    required this.to,
    required this.subject,
    required this.body,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'to': to,
    'subject': subject,
    'body': body,
    'lastModified': lastModified.millisecondsSinceEpoch,
  };

  factory EmailDraft.fromJson(Map<String, dynamic> json) => EmailDraft(
    id: json['id'] as String,
    to: json['to'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    body: json['body'] as String? ?? '',
    lastModified: DateTime.fromMillisecondsSinceEpoch(json['lastModified'] as int),
  );

  bool get isEmpty => to.isEmpty && subject.isEmpty && body.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Servizio per gestire le bozze email localmente
class DraftService {
  static final DraftService _instance = DraftService._internal();
  factory DraftService() => _instance;
  DraftService._internal();

  static const _keyDrafts = 'email_drafts';

  List<EmailDraft> _drafts = [];
  bool _isLoaded = false;

  List<EmailDraft> get drafts => List.unmodifiable(_drafts);

  /// Carica le bozze salvate
  Future<void> loadDrafts() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final draftsJson = prefs.getString(_keyDrafts);

    if (draftsJson != null) {
      try {
        final List<dynamic> list = jsonDecode(draftsJson);
        _drafts = list.map((e) => EmailDraft.fromJson(e as Map<String, dynamic>)).toList();
        // Ordina per data più recente
        _drafts.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      } catch (_) {
        _drafts = [];
      }
    }

    _isLoaded = true;
  }

  /// Salva le bozze
  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_drafts.map((d) => d.toJson()).toList());
    await prefs.setString(_keyDrafts, json);
  }

  /// Crea una nuova bozza o aggiorna una esistente
  Future<String> saveDraft({
    String? id,
    required String to,
    required String subject,
    required String body,
  }) async {
    await loadDrafts();

    final draftId = id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final draft = EmailDraft(
      id: draftId,
      to: to,
      subject: subject,
      body: body,
      lastModified: DateTime.now(),
    );

    // Se la bozza è vuota, non salvare
    if (draft.isEmpty) {
      return draftId;
    }

    // Rimuovi bozza esistente con stesso ID
    _drafts.removeWhere((d) => d.id == draftId);

    // Aggiungi la nuova bozza all'inizio
    _drafts.insert(0, draft);

    await _saveDrafts();

    return draftId;
  }

  /// Ottiene una bozza per ID
  Future<EmailDraft?> getDraft(String id) async {
    await loadDrafts();
    try {
      return _drafts.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Elimina una bozza
  Future<void> deleteDraft(String id) async {
    await loadDrafts();
    _drafts.removeWhere((d) => d.id == id);
    await _saveDrafts();
  }

  /// Ottiene tutte le bozze
  Future<List<EmailDraft>> getAllDrafts() async {
    await loadDrafts();
    return List.unmodifiable(_drafts);
  }

  /// Conta le bozze
  Future<int> getDraftCount() async {
    await loadDrafts();
    return _drafts.length;
  }
}
