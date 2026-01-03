import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../theme/olderos_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/big_button.dart';
import 'app_screen.dart';
import 'browser_screen.dart';
import 'photos_screen.dart';
import 'writer_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Mario';
  late String _formattedDate;
  late String _formattedTime;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('it_IT', null);
    _updateDateTime();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _formattedDate = DateFormat('EEEE d MMMM', 'it_IT').format(now);
    _formattedDate = _formattedDate[0].toUpperCase() + _formattedDate.substring(1);
    _formattedTime = DateFormat('HH:mm').format(now);
  }

  void _openApp(String appName, IconData icon, Color color) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppScreen(
          title: appName,
          icon: icon,
          color: color,
        ),
      ),
    );
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
                'Buona giornata, $_userName!',
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
                        'Buongiorno, $_userName!',
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
                        onTap: () => _openApp('POSTA', Icons.email, OlderOSTheme.emailColor),
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
                        onTap: () => _openApp('VIDEOCHIAMATA', Icons.videocam, OlderOSTheme.videoCallColor),
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
