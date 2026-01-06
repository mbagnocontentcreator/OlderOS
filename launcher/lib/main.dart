import 'package:flutter/material.dart';
import 'theme/olderos_theme.dart';
import 'screens/home_screen.dart';
import 'screens/setup_wizard_screen.dart';
import 'services/first_run_service.dart';

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

/// Widget che gestisce l'avvio dell'app e verifica il primo avvio
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  final _firstRunService = FirstRunService();
  bool _isLoading = true;
  bool _showWizard = false;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    await _firstRunService.initialize();

    setState(() {
      _showWizard = _firstRunService.isFirstRun;
      _isLoading = false;
    });
  }

  void _onWizardComplete() {
    setState(() {
      _showWizard = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: OlderOSTheme.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.sentiment_very_satisfied,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'OlderOS',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  color: OlderOSTheme.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_showWizard) {
      return SetupWizardScreen(
        onComplete: _onWizardComplete,
      );
    }

    return const HomeScreen();
  }
}
