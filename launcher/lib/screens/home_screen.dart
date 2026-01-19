import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../theme/olderos_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/big_button.dart';
import '../widgets/user_avatar.dart';
import '../services/first_run_service.dart';
import '../services/user_service.dart';
import 'browser_screen.dart';
import 'photos_screen.dart';
import 'writer_screen.dart';
import 'settings_screen.dart';
import 'email_screen.dart';
import 'videocall_screen.dart';
import 'calculator_screen.dart';
import 'calendar_screen.dart';
import 'table_screen.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSwitchUser;

  const HomeScreen({super.key, this.onSwitchUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firstRunService = FirstRunService();
  final _userService = UserService();
  String _userName = '';
  late String _formattedDate;
  late String _formattedTime;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('it_IT', null);
    _updateDateTime();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    // Usa il nome dal servizio utenti (multi-utente) se disponibile
    final currentUser = _userService.currentUser;
    if (currentUser != null) {
      setState(() {
        _userName = currentUser.name;
      });
    } else {
      // Fallback al FirstRunService per compatibilità
      await _firstRunService.initialize();
      setState(() {
        _userName = _firstRunService.userName;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour >= 5 && hour < 12) {
      greeting = 'Buongiorno';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Buon pomeriggio';
    } else {
      greeting = 'Buonasera';
    }

    if (_userName.isNotEmpty) {
      return '$greeting, $_userName!';
    }
    return '$greeting!';
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _formattedDate = DateFormat('EEEE d MMMM', 'it_IT').format(now);
    _formattedDate = _formattedDate[0].toUpperCase() + _formattedDate.substring(1);
    _formattedTime = DateFormat('HH:mm').format(now);
  }

  void _openBrowser() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BrowserScreen(),
      ),
    );
  }

  void _openPhotos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PhotosScreen(),
      ),
    );
  }

  void _openWriter() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WriterScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _openEmail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailScreen(),
      ),
    );
  }

  void _openVideocall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VideocallScreen(),
      ),
    );
  }

  void _openCalculator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CalculatorScreen(),
      ),
    );
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CalendarScreen(),
      ),
    );
  }

  void _openTable() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TableScreen(),
      ),
    );
  }

  void _openContacts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContactsScreen(),
      ),
    );
  }

  void _showShutdownDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Text(
          'Vuoi spegnere il computer?',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BigButton(
                  label: 'No, torna indietro',
                  backgroundColor: OlderOSTheme.textSecondary,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 24),
                BigButton(
                  label: 'Si, spegni',
                  icon: Icons.power_settings_new,
                  backgroundColor: OlderOSTheme.danger,
                  onTap: () {
                    Navigator.of(context).pop();
                    _showShuttingDown();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatarButton() {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showSwitchUserDialog,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: UserAvatarColors.getColor(currentUser.avatarColorIndex),
              width: 3,
            ),
          ),
          child: UserAvatar(
            user: currentUser,
            size: 48,
            showName: false,
          ),
        ),
      ),
    );
  }

  void _showSwitchUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Text(
          'Cambiare utente?',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Verrai disconnesso e potrai scegliere un altro utente.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BigButton(
                  label: 'No, resta',
                  backgroundColor: OlderOSTheme.textSecondary,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 24),
                BigButton(
                  label: 'Si, cambia',
                  icon: Icons.person,
                  backgroundColor: OlderOSTheme.primary,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSwitchUser?.call();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showShuttingDown() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        content: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: OlderOSTheme.primary,
                strokeWidth: 4,
              ),
              const SizedBox(height: 32),
              Text(
                'Il computer si sta spegnendo...',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _userName.isNotEmpty ? 'Buona giornata, $_userName!' : 'Buona giornata!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: OlderOSTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateDateTime();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con saluto e data/ora
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 4,
                        width: 200,
                        decoration: BoxDecoration(
                          color: OlderOSTheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formattedDate,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'ore $_formattedTime',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: OlderOSTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (widget.onSwitchUser != null) ...[
                        const SizedBox(width: 24),
                        _buildUserAvatarButton(),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Griglia delle app
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: OlderOSTheme.gapElements * 2,
                    runSpacing: OlderOSTheme.gapElements * 2,
                    alignment: WrapAlignment.center,
                    children: [
                      AppCard(
                        label: 'INTERNET',
                        icon: Icons.language,
                        iconColor: OlderOSTheme.internetColor,
                        onTap: _openBrowser,
                      ),
                      AppCard(
                        label: 'POSTA',
                        icon: Icons.email,
                        iconColor: OlderOSTheme.emailColor,
                        onTap: _openEmail,
                      ),
                      AppCard(
                        label: 'RUBRICA',
                        icon: Icons.contacts,
                        iconColor: OlderOSTheme.contactsColor,
                        onTap: _openContacts,
                      ),
                      AppCard(
                        label: 'SCRIVERE',
                        icon: Icons.edit_document,
                        iconColor: OlderOSTheme.writerColor,
                        onTap: _openWriter,
                      ),
                      AppCard(
                        label: 'FOTO',
                        icon: Icons.photo_library,
                        iconColor: OlderOSTheme.photosColor,
                        onTap: _openPhotos,
                      ),
                      AppCard(
                        label: 'VIDEOCHIAMATA',
                        icon: Icons.videocam,
                        iconColor: OlderOSTheme.videoCallColor,
                        onTap: _openVideocall,
                      ),
                      AppCard(
                        label: 'CALCOLA',
                        icon: Icons.calculate,
                        iconColor: OlderOSTheme.calculatorColor,
                        onTap: _openCalculator,
                      ),
                      AppCard(
                        label: 'TABELLA',
                        icon: Icons.grid_on,
                        iconColor: OlderOSTheme.tableColor,
                        onTap: _openTable,
                      ),
                      AppCard(
                        label: 'CALENDARIO',
                        icon: Icons.calendar_month,
                        iconColor: OlderOSTheme.calendarColor,
                        onTap: _openCalendar,
                      ),
                      AppCard(
                        label: 'IMPOSTAZIONI',
                        icon: Icons.settings,
                        iconColor: OlderOSTheme.settingsColor,
                        onTap: _openSettings,
                      ),
                    ],
                  ),
                ),
              ),

              // Pulsante spegnimento
              Center(
                child: BigButton(
                  label: 'SPEGNI COMPUTER',
                  icon: Icons.power_settings_new,
                  backgroundColor: OlderOSTheme.danger,
                  onTap: _showShutdownDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
