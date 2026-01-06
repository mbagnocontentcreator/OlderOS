import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modello per un contatto
class Contact {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? notes;
  final DateTime createdAt;
  final DateTime lastUsed;

  const Contact({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.notes,
    required this.createdAt,
    required this.lastUsed,
  });

  /// Crea un nuovo contatto con ID generato automaticamente
  factory Contact.create({
    required String name,
    required String email,
    String? phone,
    String? notes,
  }) {
    final now = DateTime.now();
    return Contact(
      id: 'contact_${now.millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      notes: notes,
      createdAt: now,
      lastUsed: now,
    );
  }

  /// Crea un contatto da JSON
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  /// Converte il contatto in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  /// Copia il contatto con modifiche
  Contact copyWith({
    String? name,
    String? email,
    String? phone,
    String? notes,
    DateTime? lastUsed,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  /// Restituisce le iniziali del nome
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Servizio per gestire la rubrica contatti
class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  static const _keyContacts = 'contacts_list';

  List<Contact> _contacts = [];
  bool _isLoaded = false;

  /// Lista dei contatti
  List<Contact> get contacts => List.unmodifiable(_contacts);

  /// Carica i contatti salvati
  Future<void> loadContacts() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyContacts);

    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        _contacts = jsonList
            .map((e) => Contact.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _contacts = [];
      }
    }

    _isLoaded = true;
  }

  /// Salva i contatti
  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_keyContacts, jsonString);
  }

  /// Aggiunge un nuovo contatto
  Future<Contact> addContact({
    required String name,
    required String email,
    String? phone,
    String? notes,
  }) async {
    await loadContacts();

    final contact = Contact.create(
      name: name,
      email: email,
      phone: phone,
      notes: notes,
    );

    _contacts.add(contact);
    await _saveContacts();

    return contact;
  }

  /// Aggiorna un contatto esistente
  Future<void> updateContact(Contact contact) async {
    await loadContacts();

    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      await _saveContacts();
    }
  }

  /// Elimina un contatto
  Future<void> deleteContact(String contactId) async {
    await loadContacts();

    _contacts.removeWhere((c) => c.id == contactId);
    await _saveContacts();
  }

  /// Cerca contatti per nome o email
  List<Contact> searchContacts(String query) {
    if (query.isEmpty) return contacts;

    final lowerQuery = query.toLowerCase();
    return _contacts
        .where((c) =>
            c.name.toLowerCase().contains(lowerQuery) ||
            c.email.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Aggiorna la data di ultimo utilizzo di un contatto
  Future<void> markAsUsed(String contactId) async {
    await loadContacts();

    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(lastUsed: DateTime.now());
      await _saveContacts();
    }
  }

  /// Restituisce i contatti ordinati per ultimo utilizzo (i piu recenti prima)
  List<Contact> getRecentContacts({int limit = 5}) {
    final sorted = List<Contact>.from(_contacts)
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return sorted.take(limit).toList();
  }

  /// Restituisce i contatti ordinati alfabeticamente
  List<Contact> getContactsAlphabetically() {
    final sorted = List<Contact>.from(_contacts)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  /// Verifica se esiste gia un contatto con questa email
  bool emailExists(String email, {String? excludeId}) {
    return _contacts.any((c) =>
        c.email.toLowerCase() == email.toLowerCase() && c.id != excludeId);
  }

  /// Trova un contatto per email
  Contact? findByEmail(String email) {
    try {
      return _contacts.firstWhere(
        (c) => c.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Restituisce il numero totale di contatti
  int get count => _contacts.length;

  /// Ricarica forzatamente i contatti
  Future<void> reload() async {
    _isLoaded = false;
    await loadContacts();
  }
}
