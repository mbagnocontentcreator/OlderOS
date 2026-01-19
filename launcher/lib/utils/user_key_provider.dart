import '../services/user_service.dart';

/// Mixin per generare chiavi SharedPreferences prefissate per l'utente corrente.
///
/// Ogni servizio che salva dati utente-specifici deve usare questo mixin
/// per garantire la separazione dei dati tra utenti diversi.
mixin UserKeyProvider {
  /// Genera una chiave prefissata con l'ID dell'utente corrente.
  ///
  /// Esempio: se baseKey è 'contacts_list' e l'utente corrente ha id 'user_123',
  /// restituisce 'user_123_contacts_list'
  ///
  /// Se nessun utente e' loggato, restituisce la chiave originale (per retrocompatibilita').
  String getUserKey(String baseKey) {
    final userId = UserService().currentUser?.id;
    if (userId == null) {
      // Nessun utente loggato - usa chiave senza prefisso (retrocompatibilita')
      return baseKey;
    }
    return '${userId}_$baseKey';
  }

  /// Verifica se c'e' un utente loggato
  bool get hasLoggedInUser => UserService().currentUser != null;

  /// ID dell'utente corrente, null se nessuno e' loggato
  String? get currentUserId => UserService().currentUser?.id;
}
