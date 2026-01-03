import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';

class VideoContact {
  final String name;
  final String relation;
  final String roomId;
  final Color avatarColor;

  const VideoContact({
    required this.name,
    required this.relation,
    required this.roomId,
    required this.avatarColor,
  });
}

class VideocallScreen extends StatefulWidget {
  const VideocallScreen({super.key});

  @override
  State<VideocallScreen> createState() => _VideocallScreenState();
}

class _VideocallScreenState extends State<VideocallScreen> {
  final List<VideoContact> _contacts = const [
    VideoContact(
      name: 'Maria',
      relation: 'figlia',
      roomId: 'olderos-maria-famiglia',
      avatarColor: Color(0xFFE91E63),
    ),
    VideoContact(
      name: 'Luca',
      relation: 'figlio',
      roomId: 'olderos-luca-famiglia',
      avatarColor: Color(0xFF2196F3),
    ),
    VideoContact(
      name: 'Anna',
      relation: 'nipote',
      roomId: 'olderos-anna-famiglia',
      avatarColor: Color(0xFF9C27B0),
    ),
    VideoContact(
      name: 'Paolo',
      relation: 'fratello',
      roomId: 'olderos-paolo-famiglia',
      avatarColor: Color(0xFF4CAF50),
    ),
  ];

  bool _isCallInProgress = false;
  VideoContact? _currentContact;

  Future<void> _startCall(VideoContact contact) async {
    setState(() {
      _isCallInProgress = true;
      _currentContact = contact;
    });

    // Apri Jitsi Meet nel browser
    final jitsiUrl = Uri.parse('https://meet.jit.si/${contact.roomId}');

    try {
      if (await canLaunchUrl(jitsiUrl)) {
        await launchUrl(jitsiUrl, mode: LaunchMode.externalApplication);
      } else {
        _showError('Impossibile aprire la videochiamata');
      }
    } catch (e) {
      _showError('Errore durante l\'avvio della chiamata');
    }

    // Dopo un breve ritardo, mostra il dialogo di fine chiamata
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isCallInProgress = false;
        _currentContact = null;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontSize: 18)),
          ],
        ),
        backgroundColor: OlderOSTheme.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCallDialog(VideoContact contact) {
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
              // Avatar grande
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: contact.avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contact.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chiamare ${contact.name}?',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '(${contact.relation})',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: OlderOSTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DialogButton(
                    icon: Icons.close,
                    label: 'ANNULLA',
                    color: OlderOSTheme.textSecondary,
                    onTap: () => Navigator.of(ctx).pop(),
                  ),
                  const SizedBox(width: 24),
                  _DialogButton(
                    icon: Icons.videocam,
                    label: 'CHIAMA',
                    color: OlderOSTheme.success,
                    filled: true,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _startCall(contact);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
            child: _isCallInProgress
                ? _CallingScreen(contact: _currentContact!)
                : _buildContactList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    return Padding(
      padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi vuoi chiamare?',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: _contacts.map((contact) {
                  return _ContactCard(
                    contact: contact,
                    onTap: () => _showCallDialog(contact),
                  );
                }).toList(),
              ),
            ),
          ),
          // Info
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OlderOSTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: OlderOSTheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'La videochiamata si aprira nel browser',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: OlderOSTheme.primary,
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
}

class _ContactCard extends StatefulWidget {
  final VideoContact contact;
  final VoidCallback onTap;

  const _ContactCard({
    required this.contact,
    required this.onTap,
  });

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
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
            ..scale(_isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0)),
          transformAlignment: Alignment.center,
          width: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            border: Border.all(
              color: _isHovered ? widget.contact.avatarColor : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: widget.contact.avatarColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.contact.avatarColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.contact.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Nome
              Text(
                widget.contact.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '(${widget.contact.relation})',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // Pulsante chiama
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? OlderOSTheme.success
                      : OlderOSTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: OlderOSTheme.success,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 24,
                      color: _isHovered ? Colors.white : OlderOSTheme.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CHIAMA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isHovered ? Colors.white : OlderOSTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallingScreen extends StatelessWidget {
  final VideoContact contact;

  const _CallingScreen({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: contact.avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Connessione a ${contact.name}...',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 32),
            Text(
              'La videochiamata si aprira nel browser',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _DialogButton({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
    required this.onTap,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
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
          transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: widget.filled
                ? (_isHovered ? widget.color.withOpacity(0.9) : widget.color)
                : (_isHovered ? widget.color.withOpacity(0.1) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 28,
                color: widget.filled ? Colors.white : widget.color,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.filled ? Colors.white : widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
