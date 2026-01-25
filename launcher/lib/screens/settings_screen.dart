import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../widgets/user_avatar.dart';
import '../services/email_service.dart';
import '../services/first_run_service.dart';
import '../services/user_service.dart';
import '../services/system_service.dart';
import 'user_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _systemService = SystemService();

  double _brightness = 0.8;
  double _volume = 0.6;
  String _connectedWifi = '';
  String _connectedPrinter = '';
  bool _isWifiConnected = false;
  bool _isPrinterReady = false;
  List<WifiNetwork> _wifiNetworks = [];
  List<Printer> _printers = [];
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSystemSettings();
  }

  Future<void> _loadSystemSettings() async {
    setState(() => _isLoadingSettings = true);

    try {
      // Carica luminosità
      final brightness = await _systemService.getBrightness();
      // Carica volume
      final volume = await _systemService.getVolume();
      // Carica reti WiFi
      final wifiNetworks = await _systemService.getWifiNetworks();
      // Carica stampanti
      final printers = await _systemService.getPrinters();

      if (mounted) {
        setState(() {
          _brightness = brightness;
          _volume = volume;
          _wifiNetworks = wifiNetworks;
          _printers = printers;

          // Trova rete connessa
          final connectedNetwork = wifiNetworks.where((n) => n.isConnected).firstOrNull;
          _connectedWifi = connectedNetwork?.ssid ?? 'Non connesso';
          _isWifiConnected = connectedNetwork != null;

          // Trova stampante predefinita
          final defaultPrinter = printers.where((p) => p.isDefault).firstOrNull;
          _connectedPrinter = defaultPrinter?.name ?? 'Nessuna stampante';
          _isPrinterReady = defaultPrinter != null && defaultPrinter.status == 'Pronta';

          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSettings = false);
      }
    }
  }

  Future<void> _onBrightnessChanged(double value) async {
    setState(() => _brightness = value);
    await _systemService.setBrightness(value);
  }

  Future<void> _onVolumeChanged(double value) async {
    setState(() => _volume = value);
    await _systemService.setVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'IMPOSTAZIONI',
            onGoHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Luminosita
                  _SettingsCard(
                    icon: Icons.brightness_6,
                    iconColor: OlderOSTheme.warning,
                    title: 'LUMINOSITA SCHERMO',
                    child: _BrightnessSlider(
                      value: _brightness,
                      onChanged: _onBrightnessChanged,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Volume
                  _SettingsCard(
                    icon: Icons.volume_up,
                    iconColor: OlderOSTheme.primary,
                    title: 'VOLUME SUONI',
                    child: _VolumeSlider(
                      value: _volume,
                      onChanged: _onVolumeChanged,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // WiFi
                  _SettingsCard(
                    icon: Icons.wifi,
                    iconColor: OlderOSTheme.success,
                    title: 'RETE WIFI',
                    trailing: _StatusBadge(
                      label: _isWifiConnected ? 'Connesso' : 'Non connesso',
                      color: _isWifiConnected ? OlderOSTheme.success : OlderOSTheme.warning,
                    ),
                    child: _WifiSection(
                      connectedNetwork: _connectedWifi,
                      onChangeNetwork: () => _showWifiDialog(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stampante
                  _SettingsCard(
                    icon: Icons.print,
                    iconColor: OlderOSTheme.videoCallColor,
                    title: 'STAMPANTE',
                    trailing: _StatusBadge(
                      label: _isPrinterReady ? 'Pronta' : 'Non disponibile',
                      color: _isPrinterReady ? OlderOSTheme.success : OlderOSTheme.warning,
                    ),
                    child: _PrinterSection(
                      connectedPrinter: _connectedPrinter,
                      onTestPrint: () => _showTestPrintDialog(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Aiuto a distanza
                  _SettingsCard(
                    icon: Icons.support_agent,
                    iconColor: OlderOSTheme.emailColor,
                    title: 'CHIEDI AIUTO A DISTANZA',
                    child: _HelpSection(
                      onRequestHelp: () => _showHelpDialog(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Configurazione Email/OAuth (per sviluppo)
                  _SettingsCard(
                    icon: Icons.settings,
                    iconColor: OlderOSTheme.emailColor,
                    title: 'CONFIGURAZIONE EMAIL',
                    trailing: _StatusBadge(
                      label: EmailService().isGoogleOAuthConfigured ? 'Configurato' : 'Da configurare',
                      color: EmailService().isGoogleOAuthConfigured ? OlderOSTheme.success : OlderOSTheme.warning,
                    ),
                    child: _EmailConfigSection(
                      onConfigure: () => _showOAuthConfigDialog(),
                      onRemoveAccount: () => _showRemoveAccountDialog(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Gestione Utenti
                  _SettingsCard(
                    icon: Icons.people,
                    iconColor: OlderOSTheme.primary,
                    title: 'GESTIONE UTENTI',
                    trailing: _StatusBadge(
                      label: '${UserService().userCount}/${UserService.maxUsers}',
                      color: OlderOSTheme.primary,
                    ),
                    child: _UserManagementSection(
                      onRefresh: () => setState(() {}),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info sistema
                  _SettingsCard(
                    icon: Icons.info_outline,
                    iconColor: OlderOSTheme.textSecondary,
                    title: 'INFORMAZIONI',
                    child: _InfoSection(),
                  ),

                  const SizedBox(height: 20),

                  // Reset Wizard (per testing)
                  _SettingsCard(
                    icon: Icons.restart_alt,
                    iconColor: OlderOSTheme.warning,
                    title: 'CONFIGURAZIONE INIZIALE',
                    child: _ResetWizardSection(
                      onReset: () => _resetWizard(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetWizard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.restart_alt, color: OlderOSTheme.warning, size: 32),
            const SizedBox(width: 12),
            const Text('Rifare configurazione?'),
          ],
        ),
        content: const Text(
          'Al prossimo avvio vedrai di nuovo la configurazione iniziale.\n\nI tuoi dati (contatti, email) non verranno cancellati.',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'ANNULLA',
              style: TextStyle(
                fontSize: 18,
                color: OlderOSTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: OlderOSTheme.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFERMA', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final firstRunService = FirstRunService();
      await firstRunService.resetFirstRun();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Configurazione resettata. Riavvia l\'app per vedere il wizard.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            backgroundColor: OlderOSTheme.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showWifiDialog() {
    showDialog(
      context: context,
      builder: (context) => _WifiDialog(
        currentNetwork: _connectedWifi,
        networks: _wifiNetworks,
        onConnect: (network, password) async {
          Navigator.of(context).pop();

          // Mostra indicatore di connessione
          _showConnectingDialog(network);

          // Tenta la connessione
          final success = await _systemService.connectToWifi(network, password);

          // Chiudi il dialogo di connessione
          if (mounted) Navigator.of(context).pop();

          if (success) {
            await _loadSystemSettings(); // Ricarica le impostazioni
            _showConnectionSuccess(network);
          } else {
            _showConnectionError(network);
          }
        },
        onRefresh: () async {
          final networks = await _systemService.getWifiNetworks();
          setState(() => _wifiNetworks = networks);
        },
      ),
    );
  }

  void _showConnectingDialog(String network) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: OlderOSTheme.primary),
              const SizedBox(height: 24),
              Text(
                'Connessione a $network...',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectionError(String network) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'Impossibile connettersi a $network',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        backgroundColor: OlderOSTheme.danger,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showConnectionSuccess(String network) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'Connesso a $network',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        backgroundColor: OlderOSTheme.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTestPrintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Row(
          children: [
            Icon(Icons.print, size: 32, color: OlderOSTheme.success),
            const SizedBox(width: 12),
            Text(
              'Stampa di prova',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ],
        ),
        content: Text(
          'Pagina di prova inviata alla stampante!',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Row(
          children: [
            Icon(Icons.support_agent, size: 32, color: OlderOSTheme.primary),
            const SizedBox(width: 12),
            Text(
              'Aiuto a distanza',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questa funzione permettera a un familiare di vedere il tuo schermo e aiutarti.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Funzione disponibile prossimamente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  void _showOAuthConfigDialog() {
    final clientIdController = TextEditingController();
    final clientSecretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OlderOSTheme.emailColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.key, size: 28, color: OlderOSTheme.emailColor),
            ),
            const SizedBox(width: 12),
            Text(
              'Credenziali Google OAuth',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inserisci le credenziali da Google Cloud Console:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: clientIdController,
                decoration: InputDecoration(
                  labelText: 'Client ID',
                  hintText: 'xxxxx.apps.googleusercontent.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: clientSecretController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Client Secret',
                  hintText: 'GOCSPX-xxxxx',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (clientIdController.text.isNotEmpty && clientSecretController.text.isNotEmpty) {
                await EmailService().configureGoogleOAuth(
                  clientId: clientIdController.text.trim(),
                  clientSecret: clientSecretController.text.trim(),
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  setState(() {}); // Refresh UI
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text('Credenziali OAuth salvate!', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      backgroundColor: OlderOSTheme.success,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            child: const Text('Salva', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _showRemoveAccountDialog() {
    final emailService = EmailService();

    if (!emailService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nessun account email configurato', style: TextStyle(fontSize: 18)),
          backgroundColor: OlderOSTheme.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, size: 32, color: OlderOSTheme.danger),
            const SizedBox(width: 12),
            Text(
              'Rimuovere account email?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account attuale: ${emailService.userEmail ?? "Sconosciuto"}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Dovrai riconfigurare l\'account per usare la posta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: OlderOSTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: OlderOSTheme.danger),
            onPressed: () async {
              await emailService.removeAccount();
              if (mounted) {
                Navigator.of(context).pop();
                setState(() {});
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text('Account email rimosso', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    backgroundColor: OlderOSTheme.textSecondary,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text('Rimuovi', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: OlderOSTheme.cardBackground,
        borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrightnessSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _BrightnessSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.brightness_low,
          size: 32,
          color: OlderOSTheme.textSecondary,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              activeColor: OlderOSTheme.warning,
              inactiveColor: OlderOSTheme.warning.withOpacity(0.3),
            ),
          ),
        ),
        Icon(
          Icons.brightness_high,
          size: 32,
          color: OlderOSTheme.warning,
        ),
      ],
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.volume_mute,
          size: 32,
          color: OlderOSTheme.textSecondary,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              activeColor: OlderOSTheme.primary,
              inactiveColor: OlderOSTheme.primary.withOpacity(0.3),
            ),
          ),
        ),
        Icon(
          Icons.volume_up,
          size: 32,
          color: OlderOSTheme.primary,
        ),
      ],
    );
  }
}

class _WifiSection extends StatelessWidget {
  final String connectedNetwork;
  final VoidCallback onChangeNetwork;

  const _WifiSection({
    required this.connectedNetwork,
    required this.onChangeNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rete attuale:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                connectedNetwork,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _ActionButton(
          label: 'CAMBIA RETE',
          onTap: onChangeNetwork,
        ),
      ],
    );
  }
}

class _PrinterSection extends StatelessWidget {
  final String connectedPrinter;
  final VoidCallback onTestPrint;

  const _PrinterSection({
    required this.connectedPrinter,
    required this.onTestPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stampante attuale:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                connectedPrinter,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _ActionButton(
          label: 'STAMPA PROVA',
          onTap: onTestPrint,
        ),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  final VoidCallback onRequestHelp;

  const _HelpSection({required this.onRequestHelp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Se hai bisogno di aiuto, un familiare puo vedere il tuo schermo e guidarti.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        _ActionButton(
          label: 'RICHIEDI AIUTO',
          color: OlderOSTheme.emailColor,
          onTap: onRequestHelp,
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(label: 'Versione', value: 'OlderOS 1.0'),
        const SizedBox(height: 12),
        _InfoRow(label: 'Sistema', value: 'Ubuntu 24.04 LTS'),
        const SizedBox(height: 12),
        _InfoRow(label: 'Ultimo aggiornamento', value: 'Oggi'),
      ],
    );
  }
}

class _ResetWizardSection extends StatelessWidget {
  final VoidCallback onReset;

  const _ResetWizardSection({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Puoi rifare la configurazione iniziale per modificare il tuo nome o altre impostazioni.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: OlderOSTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          label: 'RIFAI CONFIGURAZIONE',
          color: OlderOSTheme.warning,
          onTap: onReset,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? OlderOSTheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _isHovered ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

class _WifiDialog extends StatefulWidget {
  final String currentNetwork;
  final List<WifiNetwork> networks;
  final Function(String ssid, String? password) onConnect;
  final Future<void> Function() onRefresh;

  const _WifiDialog({
    required this.currentNetwork,
    required this.networks,
    required this.onConnect,
    required this.onRefresh,
  });

  @override
  State<_WifiDialog> createState() => _WifiDialogState();
}

class _WifiDialogState extends State<_WifiDialog> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await widget.onRefresh();
    setState(() => _isRefreshing = false);
  }

  void _onNetworkTap(WifiNetwork network) {
    if (network.isConnected) {
      // Gia' connesso, non fare nulla
      return;
    }

    if (network.isSecured) {
      // Mostra dialog per password
      _showPasswordDialog(network.ssid);
    } else {
      // Connetti direttamente
      widget.onConnect(network.ssid, null);
    }
  }

  void _showPasswordDialog(String ssid) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock, color: OlderOSTheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Password per $ssid',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            labelText: 'Password WiFi',
            labelStyle: const TextStyle(fontSize: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ANNULLA', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onConnect(ssid, passwordController.text);
            },
            child: const Text('CONNETTI', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
      ),
      title: Row(
        children: [
          Icon(Icons.wifi, size: 32, color: OlderOSTheme.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scegli rete WiFi',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          IconButton(
            onPressed: _isRefreshing ? null : _refresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: widget.networks.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nessuna rete WiFi trovata',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.networks.take(6).map((network) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _WifiNetworkTile(
                      network: network,
                      isConnected: network.isConnected,
                      onTap: () => _onNetworkTap(network),
                    ),
                  );
                }).toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Chiudi',
            style: TextStyle(
              fontSize: 20,
              color: OlderOSTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _WifiNetworkTile extends StatefulWidget {
  final WifiNetwork network;
  final bool isConnected;
  final VoidCallback onTap;

  const _WifiNetworkTile({
    required this.network,
    required this.isConnected,
    required this.onTap,
  });

  @override
  State<_WifiNetworkTile> createState() => _WifiNetworkTileState();
}

class _WifiNetworkTileState extends State<_WifiNetworkTile> {
  bool _isHovered = false;

  IconData _getSignalIcon() {
    final strength = widget.network.signalStrength;
    if (strength >= 75) return Icons.signal_wifi_4_bar;
    if (strength >= 50) return Icons.network_wifi_3_bar;
    if (strength >= 25) return Icons.network_wifi_2_bar;
    return Icons.network_wifi_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isConnected
                ? OlderOSTheme.success.withOpacity(0.1)
                : (_isHovered ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isConnected
                  ? OlderOSTheme.success
                  : (_isHovered ? OlderOSTheme.primary : Colors.grey.shade300),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getSignalIcon(),
                size: 28,
                color: widget.isConnected
                    ? OlderOSTheme.success
                    : OlderOSTheme.textPrimary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.network.ssid,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: widget.isConnected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '${widget.network.signalStrength}% - ${widget.network.isSecured ? "Protetta" : "Aperta"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: OlderOSTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.network.isSecured)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.lock,
                    size: 20,
                    color: OlderOSTheme.textSecondary,
                  ),
                ),
              if (widget.isConnected)
                Icon(
                  Icons.check_circle,
                  size: 28,
                  color: OlderOSTheme.success,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailConfigSection extends StatelessWidget {
  final VoidCallback onConfigure;
  final VoidCallback onRemoveAccount;

  const _EmailConfigSection({
    required this.onConfigure,
    required this.onRemoveAccount,
  });

  @override
  Widget build(BuildContext context) {
    final emailService = EmailService();
    final isOAuthConfigured = emailService.isGoogleOAuthConfigured;
    final isAccountConfigured = emailService.isConfigured;
    final userEmail = emailService.userEmail;
    final isGoogleAuth = emailService.isGoogleAuth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stato OAuth
        _ConfigRow(
          label: 'Credenziali OAuth Google',
          value: isOAuthConfigured ? 'Configurate' : 'Non configurate',
          valueColor: isOAuthConfigured ? OlderOSTheme.success : OlderOSTheme.warning,
        ),
        const SizedBox(height: 12),

        // Stato account email
        if (isAccountConfigured && userEmail != null) ...[
          _ConfigRow(
            label: 'Account email',
            value: userEmail,
            valueColor: OlderOSTheme.success,
          ),
          const SizedBox(height: 8),
          _ConfigRow(
            label: 'Tipo accesso',
            value: isGoogleAuth ? 'Google OAuth' : 'Password',
            valueColor: OlderOSTheme.textSecondary,
          ),
        ] else ...[
          _ConfigRow(
            label: 'Account email',
            value: 'Nessun account configurato',
            valueColor: OlderOSTheme.textSecondary,
          ),
          if (isOAuthConfigured)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Vai su LEGGI per configurare il tuo account Gmail.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: OlderOSTheme.textSecondary,
                ),
              ),
            ),
        ],

        const SizedBox(height: 20),

        // Pulsanti
        Row(
          children: [
            _ActionButton(
              label: 'CONFIGURA OAUTH',
              color: OlderOSTheme.emailColor,
              onTap: onConfigure,
            ),
            if (isAccountConfigured) ...[
              const SizedBox(width: 16),
              _ActionButton(
                label: 'RIMUOVI ACCOUNT',
                color: OlderOSTheme.danger,
                onTap: onRemoveAccount,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _UserManagementSection extends StatelessWidget {
  final VoidCallback onRefresh;

  const _UserManagementSection({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final users = userService.users;
    final currentUser = userService.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista utenti
        ...users.map((user) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _UserTile(
            user: user,
            isCurrentUser: user.id == currentUser?.id,
            onChangePin: () => _showChangePinDialog(context, user),
            onDelete: users.length > 1 ? () => _showDeleteUserDialog(context, user, onRefresh) : null,
          ),
        )),

        const SizedBox(height: 8),

        // Pulsante aggiungi utente
        if (userService.canAddUser)
          _ActionButton(
            label: 'AGGIUNGI UTENTE',
            color: OlderOSTheme.success,
            onTap: () => _showAddUserInfo(context),
          ),
      ],
    );
  }

  void _showChangePinDialog(BuildContext context, User user) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock, color: OlderOSTheme.primary, size: 32),
            const SizedBox(width: 12),
            Text('Cambia PIN di ${user.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'PIN attuale',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Nuovo PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Conferma nuovo PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ANNULLA', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('I PIN non corrispondono')),
                );
                return;
              }
              try {
                await UserService().changePin(
                  user.id,
                  oldPinController.text,
                  newPinController.text,
                );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('PIN cambiato con successo!'),
                    backgroundColor: OlderOSTheme.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: OlderOSTheme.danger,
                  ),
                );
              }
            },
            child: const Text('CAMBIA', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, User user, VoidCallback onRefresh) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: OlderOSTheme.danger, size: 32),
            const SizedBox(width: 12),
            const Text('Eliminare utente?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vuoi eliminare ${user.name}?',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tutti i dati di questo utente verranno cancellati permanentemente.',
              style: TextStyle(fontSize: 16, color: OlderOSTheme.danger),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ANNULLA', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: OlderOSTheme.danger),
            onPressed: () async {
              await UserService().deleteUser(user.id);
              Navigator.of(ctx).pop();
              onRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name} eliminato'),
                  backgroundColor: OlderOSTheme.textSecondary,
                ),
              );
            },
            child: const Text('ELIMINA', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _showAddUserInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserSetupScreen(
          isFirstUser: false,
          autoLogin: false,
          onComplete: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Nuovo utente creato con successo!',
                  style: TextStyle(fontSize: 18),
                ),
                backgroundColor: OlderOSTheme.success,
              ),
            );
            onRefresh();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final bool isCurrentUser;
  final VoidCallback onChangePin;
  final VoidCallback? onDelete;

  const _UserTile({
    required this.user,
    required this.isCurrentUser,
    required this.onChangePin,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? OlderOSTheme.primary.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: OlderOSTheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          UserAvatar(user: user, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: OlderOSTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Tu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onChangePin,
            icon: const Icon(Icons.lock, size: 24),
            tooltip: 'Cambia PIN',
            color: OlderOSTheme.primary,
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, size: 24),
              tooltip: 'Elimina utente',
              color: OlderOSTheme.danger,
            ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ConfigRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
