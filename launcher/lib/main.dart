import 'package:flutter/material.dart';
import 'theme/olderos_theme.dart';
import 'screens/home_screen.dart';
import 'screens/setup_wizard_screen.dart';
import 'screens/user_selection_screen.dart';
import 'screens/user_setup_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'services/first_run_service.dart';
import 'services/user_service.dart';
import 'services/contact_service.dart';
import 'services/email_service.dart';
import 'services/email_accounts_service.dart';
import 'services/draft_service.dart';
import 'services/email_notification_service.dart';

void main() {
  runApp(const OlderOSApp());
}

class OlderOSApp extends StatelessWidget {
  const OlderOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OlderOS',
      debugShowCheckedModeBanner: false,
      theme: OlderOSTheme.theme,
      home: const _AppStartup(),
    );
  }
}

/// Stati possibili dell'app all'avvio
enum AppStartupState {
  loading,
  noUsers,        // Nessun utente, mostra creazione primo utente
  userSelection,  // Selezione utente
  pinEntry,       // Inserimento PIN
  setupWizard,    // Setup wizard per nuovo utente
  home,           // Home screen
}

/// Widget che gestisce l'avvio dell'app con supporto multi-utente
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  final _userService = UserService();
  final _firstRunService = FirstRunService();

  AppStartupState _state = AppStartupState.loading;
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Inizializza il servizio utenti
    await _userService.initialize();

    if (!_userService.hasUsers) {
      // Nessun utente registrato
      setState(() {
        _state = AppStartupState.noUsers;
      });
    } else if (_userService.userCount == 1) {
      // Un solo utente - vai direttamente al PIN
      setState(() {
        _selectedUser = _userService.users.first;
        _state = AppStartupState.pinEntry;
      });
    } else {
      // Piu' utenti - mostra selezione
      setState(() {
        _state = AppStartupState.userSelection;
      });
    }
  }

  /// Chiamato quando viene creato il primo utente
  Future<void> _onFirstUserCreated() async {
    // Ricarica tutti i servizi per il nuovo utente
    await _reloadAllServices();

    // Controlla se deve mostrare il wizard
    await _firstRunService.initialize();

    if (_firstRunService.isFirstRun) {
      setState(() {
        _state = AppStartupState.setupWizard;
      });
    } else {
      setState(() {
        _state = AppStartupState.home;
      });
    }
  }

  /// Chiamato quando un utente viene selezionato
  void _onUserSelected(User user) {
    setState(() {
      _selectedUser = user;
      _state = AppStartupState.pinEntry;
    });
  }

  /// Chiamato quando viene aggiunto un nuovo utente
  void _onAddUser() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserSetupScreen(
          isFirstUser: false,
          onComplete: () {
            Navigator.of(context).pop();
            // Vai direttamente alla home per il nuovo utente
            _afterLogin();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// Chiamato quando il PIN e' corretto
  Future<void> _onPinSuccess() async {
    await _afterLogin();
  }

  /// Chiamato per tornare alla selezione utente
  void _onPinCancel() {
    setState(() {
      _selectedUser = null;
      _state = AppStartupState.userSelection;
    });
  }

  /// Chiamato dopo un login riuscito
  Future<void> _afterLogin() async {
    // Ricarica tutti i servizi per l'utente corrente
    await _reloadAllServices();

    // Controlla se deve mostrare il wizard
    await _firstRunService.initialize();

    if (_firstRunService.isFirstRun) {
      setState(() {
        _state = AppStartupState.setupWizard;
      });
    } else {
      setState(() {
        _state = AppStartupState.home;
      });
    }
  }

  /// Ricarica tutti i servizi per l'utente corrente
  Future<void> _reloadAllServices() async {
    // Reset di tutti i servizi singleton
    ContactService().resetState();
    EmailService().resetState();
    EmailAccountsService().resetState();
    DraftService().resetState();
    EmailNotificationService().resetState();
    _firstRunService.resetState();
  }

  /// Chiamato quando il wizard e' completato
  void _onWizardComplete() {
    setState(() {
      _state = AppStartupState.home;
    });
  }

  /// Chiamato quando si vuole cambiare utente dalla home
  void _onSwitchUser() async {
    // Logout dell'utente corrente
    await _userService.logout();

    // Reset di tutti i servizi
    await _reloadAllServices();

    setState(() {
      _selectedUser = null;
      _state = _userService.userCount == 1
          ? AppStartupState.pinEntry
          : AppStartupState.userSelection;
      if (_state == AppStartupState.pinEntry) {
        _selectedUser = _userService.users.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case AppStartupState.loading:
        return _buildLoadingScreen();

      case AppStartupState.noUsers:
        return UserSetupScreen(
          isFirstUser: true,
          onComplete: _onFirstUserCreated,
        );

      case AppStartupState.userSelection:
        return UserSelectionScreen(
          onUserSelected: _onUserSelected,
          onAddUser: _onAddUser,
        );

      case AppStartupState.pinEntry:
        return PinEntryScreen(
          user: _selectedUser!,
          onSuccess: _onPinSuccess,
          onCancel: _userService.userCount > 1 ? _onPinCancel : () {},
        );

      case AppStartupState.setupWizard:
        return SetupWizardScreen(
          onComplete: _onWizardComplete,
        );

      case AppStartupState.home:
        return HomeScreen(
          key: ValueKey(_userService.currentUser?.id),
          onSwitchUser: _onSwitchUser,
        );
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              OlderOSTheme.primary.withAlpha(25),
              OlderOSTheme.background,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '👴🏻',
                style: TextStyle(fontSize: 100),
              ),
              SizedBox(height: 32),
              Text(
                'OlderOS',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                color: OlderOSTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
