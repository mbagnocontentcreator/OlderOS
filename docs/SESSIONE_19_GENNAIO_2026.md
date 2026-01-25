# Sessione 19 Gennaio 2026

## Obiettivo della sessione
Correzione bug nel sistema multi-utente implementato nella sessione precedente.

## Bug segnalati e risolti

### 1. PIN non digitabile da tastiera fisica
**Problema**: Il PIN poteva essere inserito solo cliccando i numeri con il mouse, non dalla tastiera.

**Soluzione**: Aggiunto `KeyboardListener` in:
- `lib/screens/pin_entry_screen.dart`
- `lib/screens/user_setup_screen.dart`

Ora supporta:
- Tasti numerici 0-9 (riga superiore e tastierino numerico)
- Backspace per cancellare
- Enter/Invio per confermare

### 2. Saluto con nome utente sbagliato
**Problema**: Dopo aver creato un nuovo utente, il saluto nella home mostrava il nome della configurazione iniziale precedente invece del nome dell'utente loggato.

**Soluzione**: Modificato `lib/screens/home_screen.dart` - metodo `_loadUserName()` per usare `UserService().currentUser?.name` come fonte primaria, con fallback a `FirstRunService` per compatibilità.

### 3. Cambio utente non funzionante
**Problema**: Cliccando l'avatar per cambiare utente, dopo l'inserimento del PIN il sistema tornava alla home dell'utente precedente.

**Soluzione**: Aggiunta `ValueKey` basata sull'ID utente al widget `HomeScreen` in `lib/main.dart` per forzare la ricreazione del widget quando cambia l'utente:
```dart
return HomeScreen(
  key: ValueKey(_userService.currentUser?.id),
  onSwitchUser: _onSwitchUser,
);
```

### 4. Impossibile creare utente dalle Impostazioni
**Problema**: Il pulsante "AGGIUNGI UTENTE" nelle impostazioni mostrava solo un messaggio informativo che rimandava alla home.

**Soluzione**:
- Aggiunto parametro `autoLogin` a `UserSetupScreen` (default `true`)
- Modificato `_showAddUserInfo()` in `lib/screens/settings_screen.dart` per navigare direttamente a `UserSetupScreen` con `autoLogin: false`
- Dopo la creazione, l'utente resta loggato come prima e vede un messaggio di conferma
- Il nuovo utente viene mostrato nella lista e potrà fare login separatamente

## File modificati

| File | Modifiche |
|------|-----------|
| `lib/screens/pin_entry_screen.dart` | Aggiunto KeyboardListener per input da tastiera |
| `lib/screens/user_setup_screen.dart` | Aggiunto KeyboardListener + parametro autoLogin |
| `lib/screens/home_screen.dart` | Corretto _loadUserName() per usare UserService |
| `lib/screens/settings_screen.dart` | Navigazione diretta a UserSetupScreen |
| `lib/main.dart` | Aggiunta ValueKey a HomeScreen |

## Test effettuati
- Inserimento PIN da tastiera fisica (numeri, backspace, invio)
- Verifica saluto corretto dopo login
- Cambio utente con verifica dati separati
- Creazione nuovo utente da Impostazioni con avvio Setup Wizard

## Stato del progetto

### Funzionalità completate
- Sistema multi-utente completo (max 4 utenti)
- Autenticazione PIN (4-6 cifre) con hash SHA-256
- Dati separati per ogni utente
- Gestione utenti da Impostazioni (aggiungi, elimina, cambia PIN)
- Cambio utente dalla home
- Migrazione dati legacy al primo utente
- Blocco dopo 5 tentativi errati (5 minuti)

### Prossima sessione
**Test su Linux** - Priorità per la prossima sessione di lavoro:
- Build dell'app per Linux
- Verifica compatibilità e funzionamento
- Propedeutico a Kiosk mode e creazione ISO

### Roadmap rimanente
1. ~~Test su Linux~~ (prossima sessione)
2. Configurazione Kiosk mode
3. Rifinitura UI
4. Creazione ISO
5. Test con utenti reali

## Note
Il sistema multi-utente avvia automaticamente il Setup Wizard per ogni nuovo utente, permettendo una configurazione personalizzata (nome, preferenze, ecc.) indipendente dagli altri profili.
