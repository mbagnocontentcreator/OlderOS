import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../services/contact_service.dart';
import '../services/browser_launcher_service.dart';

/// Tipi di servizio videochiamata supportati
enum VideoService {
  googleMeet,
  jitsiMeet,
  whatsApp,
}

class VideocallScreen extends StatefulWidget {
  const VideocallScreen({super.key});

  @override
  State<VideocallScreen> createState() => _VideocallScreenState();
}

class _VideocallScreenState extends State<VideocallScreen> {
  final _contactService = ContactService();
  final _browserLauncher = BrowserLauncherService();
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    await _contactService.loadContacts();
    setState(() {
      _contacts = _contactService.contacts;
      _isLoading = false;
    });
  }

  /// Apre un URL nel browser esterno (per WebRTC/videochiamate)
  Future<void> _openInBrowser(String url, String title) async {
    // Mostra indicatore di caricamento
    _showLoadingDialog(title);

    final result = await _browserLauncher.launchUrl(
      url,
      title: title,
      forceExternal: true, // Videochiamate sempre nel browser esterno
    );

    // Chiudi il dialog di caricamento
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (!result.success) {
      _showError('Impossibile aprire ${result.browserName ?? "il browser"}: ${result.error}');
    } else {
      // Mostra messaggio di successo
      _showSuccess('Videochiamata aperta in ${result.browserName ?? "browser"}');
    }
  }

  void _showLoadingDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: OlderOSTheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Apertura $title...',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 18))),
          ],
        ),
        backgroundColor: OlderOSTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 18))),
          ],
        ),
        backgroundColor: OlderOSTheme.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Mostra dialog per partecipare a una chiamata esistente
  void _showJoinCallDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Row(
          children: [
            Icon(Icons.link, color: OlderOSTheme.primary, size: 32),
            const SizedBox(width: 12),
            Text(
              'Partecipa a chiamata',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                'Incolla il link che hai ricevuto:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'https://meet.google.com/xxx-xxxx-xxx',
                  hintStyle: TextStyle(
                    color: OlderOSTheme.textSecondary.withAlpha(128),
                    fontSize: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste, size: 28),
                    tooltip: 'Incolla',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        controller.text = data!.text!;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OlderOSTheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: OlderOSTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Funziona con Google Meet, Jitsi, Zoom e altri',
                        style: TextStyle(
                          color: OlderOSTheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'ANNULLA',
              style: TextStyle(
                fontSize: 18,
                color: OlderOSTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              final link = controller.text.trim();
              if (link.isNotEmpty) {
                Navigator.of(ctx).pop();
                String url = link;
                if (!url.startsWith('http')) {
                  url = 'https://$url';
                }
                _openInBrowser(url, 'Videochiamata');
              }
            },
            icon: const Icon(Icons.videocam, size: 24),
            label: const Text('PARTECIPA', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: OlderOSTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Genera una stanza Jitsi e mostra il link da condividere
  void _showCreateJitsiDialog() {
    // Genera un ID stanza casuale
    final random = Random();
    final roomId = 'olderos-${random.nextInt(9999).toString().padLeft(4, '0')}-${random.nextInt(9999).toString().padLeft(4, '0')}';
    final jitsiUrl = 'https://meet.jit.si/$roomId';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF17A9FD).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.video_call, color: Color(0xFF17A9FD), size: 32),
            ),
            const SizedBox(width: 12),
            Text(
              'Nuova videochiamata',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                'Ho creato una stanza per te!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Condividi questo link con chi vuoi chiamare:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: OlderOSTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: OlderOSTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OlderOSTheme.primary),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        jitsiUrl,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jitsiUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                const Text(
                                  'Link copiato!',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            backgroundColor: OlderOSTheme.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('COPIA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OlderOSTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OlderOSTheme.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: OlderOSTheme.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Invia il link via email o messaggio, poi premi AVVIA',
                        style: TextStyle(
                          color: OlderOSTheme.warning,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'ANNULLA',
              style: TextStyle(
                fontSize: 18,
                color: OlderOSTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openInBrowser(jitsiUrl, 'Videochiamata Jitsi');
            },
            icon: const Icon(Icons.videocam, size: 24),
            label: const Text('AVVIA CHIAMATA', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: OlderOSTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Apre WhatsApp Web
  void _openWhatsApp() {
    _openInBrowser('https://web.whatsapp.com', 'WhatsApp');
  }

  /// Apre Google Meet
  void _openGoogleMeet() {
    _openInBrowser('https://meet.google.com', 'Google Meet');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'VIDEOCHIAMATA',
            onGoHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sezione principale - Opzioni
                        Text(
                          'Cosa vuoi fare?',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 24),

                        // Griglia opzioni principali
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: [
                            _ServiceCard(
                              icon: Icons.link,
                              title: 'PARTECIPA',
                              subtitle: 'Ho ricevuto un link',
                              color: OlderOSTheme.primary,
                              onTap: _showJoinCallDialog,
                            ),
                            _ServiceCard(
                              icon: Icons.add_circle_outline,
                              title: 'CREA CHIAMATA',
                              subtitle: 'Genera link da condividere',
                              color: const Color(0xFF17A9FD), // Jitsi blue
                              onTap: _showCreateJitsiDialog,
                            ),
                            _ServiceCard(
                              icon: Icons.videocam,
                              title: 'GOOGLE MEET',
                              subtitle: 'Apri Google Meet',
                              color: const Color(0xFF00897B), // Meet teal
                              onTap: _openGoogleMeet,
                            ),
                            _ServiceCard(
                              icon: Icons.chat,
                              title: 'WHATSAPP',
                              subtitle: 'Videochiama con WhatsApp',
                              color: const Color(0xFF25D366), // WhatsApp green
                              onTap: _openWhatsApp,
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Sezione contatti rapidi
                        if (_contacts.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                'Contatti rapidi',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '(apre Jitsi Meet)',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: OlderOSTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: _contacts.take(6).map((contact) {
                              return _QuickContactCard(
                                contact: contact,
                                onTap: () => _callContact(contact),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Info box
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: OlderOSTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: OlderOSTheme.primary.withAlpha(50),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.help_outline, color: OlderOSTheme.primary, size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Come funziona?',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _HelpItem(
                                number: '1',
                                text: 'PARTECIPA: incolla un link ricevuto da un familiare',
                              ),
                              _HelpItem(
                                number: '2',
                                text: 'CREA CHIAMATA: genera un link da inviare a chi vuoi chiamare',
                              ),
                              _HelpItem(
                                number: '3',
                                text: 'GOOGLE MEET / WHATSAPP: apri direttamente il servizio',
                              ),
                            ],
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

  void _callContact(Contact contact) {
    // Genera stanza Jitsi basata sul nome del contatto
    final roomId = 'olderos-${contact.name.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final jitsiUrl = 'https://meet.jit.si/$roomId';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _getAvatarColor(contact.name),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Chiamare ${contact.name}?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Si aprira una stanza Jitsi Meet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: OlderOSTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OlderOSTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        jitsiUrl,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jitsiUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copiato!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'ANNULLA',
                      style: TextStyle(
                        fontSize: 18,
                        color: OlderOSTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _openInBrowser(jitsiUrl, 'Chiamata con ${contact.name}');
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('CHIAMA', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OlderOSTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFF00BCD4),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

/// Card per i servizi principali
class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0)),
          transformAlignment: Alignment.center,
          width: 260,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? widget.color : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.color.withAlpha(40)
                    : Colors.black.withAlpha(20),
                blurRadius: _isHovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: widget.color.withAlpha(_isHovered ? 255 : 40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  widget.icon,
                  size: 44,
                  color: _isHovered ? Colors.white : widget.color,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: OlderOSTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 16,
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
}

/// Card per contatti rapidi
class _QuickContactCard extends StatefulWidget {
  final Contact contact;
  final VoidCallback onTap;

  const _QuickContactCard({
    required this.contact,
    required this.onTap,
  });

  @override
  State<_QuickContactCard> createState() => _QuickContactCardState();
}

class _QuickContactCardState extends State<_QuickContactCard> {
  bool _isHovered = false;

  Color get _avatarColor {
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFF00BCD4),
    ];
    return colors[widget.contact.name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? _avatarColor.withAlpha(25) : OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? _avatarColor : OlderOSTheme.textSecondary.withAlpha(50),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.contact.name.isNotEmpty
                        ? widget.contact.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.videocam,
                        size: 16,
                        color: _isHovered ? _avatarColor : OlderOSTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chiama',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isHovered ? _avatarColor : OlderOSTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item di aiuto
class _HelpItem extends StatelessWidget {
  final String number;
  final String text;

  const _HelpItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: OlderOSTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}
