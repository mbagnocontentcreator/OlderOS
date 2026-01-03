import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import 'email_view_screen.dart';
import 'compose_email_screen.dart';

class Email {
  final String id;
  final String senderName;
  final String senderEmail;
  final String subject;
  final String preview;
  final String body;
  final DateTime date;
  final bool isRead;
  final bool isSent;

  Email({
    required this.id,
    required this.senderName,
    required this.senderEmail,
    required this.subject,
    required this.preview,
    required this.body,
    required this.date,
    this.isRead = false,
    this.isSent = false,
  });

  Email copyWith({bool? isRead}) {
    return Email(
      id: id,
      senderName: senderName,
      senderEmail: senderEmail,
      subject: subject,
      preview: preview,
      body: body,
      date: date,
      isRead: isRead ?? this.isRead,
      isSent: isSent,
    );
  }
}

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  bool _showInbox = true;

  final List<Email> _inbox = [
    Email(
      id: '1',
      senderName: 'Maria (figlia)',
      senderEmail: 'maria@email.com',
      subject: 'Foto del compleanno di Luca',
      preview: 'Ciao papa! Ti mando le foto della festa di compleanno...',
      body: '''Ciao papa!

Ti mando le foto della festa di compleanno di Luca. E stato bellissimo, peccato che non sei potuto venire!

La prossima volta ti vengo a prendere io cosi puoi stare con noi.

Un abbraccio grande,
Maria''',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    Email(
      id: '2',
      senderName: 'Farmacia San Marco',
      senderEmail: 'farmacia@sanmarco.it',
      subject: 'Ricetta pronta per il ritiro',
      preview: 'Gentile cliente, la informiamo che la sua ricetta...',
      body: '''Gentile cliente,

La informiamo che la sua ricetta medica e pronta per il ritiro.

Puo passare in farmacia negli orari di apertura:
- Lunedi-Venerdi: 8:30-12:30 e 15:30-19:30
- Sabato: 8:30-12:30

Cordiali saluti,
Farmacia San Marco''',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    Email(
      id: '3',
      senderName: 'Luca (nipote)',
      senderEmail: 'luca@email.com',
      subject: 'Grazie per il regalo nonno!',
      preview: 'Ciao nonno! Grazie mille per il regalo di compleanno...',
      body: '''Ciao nonno!

Grazie mille per il regalo di compleanno! Mi e piaciuto tantissimo!

Quando vieni a trovarci? Mi manchi!

Un bacio grande,
Luca''',
      date: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    Email(
      id: '4',
      senderName: 'Comune di Milano',
      senderEmail: 'info@comune.milano.it',
      subject: 'Avviso scadenza carta identita',
      preview: 'Gentile cittadino, la sua carta di identita scadra...',
      body: '''Gentile cittadino,

La sua carta di identita scadra tra 90 giorni.

Per rinnovarla, puo prenotare un appuntamento presso l'anagrafe del suo municipio.

Cordiali saluti,
Comune di Milano''',
      date: DateTime.now().subtract(const Duration(days: 5)),
      isRead: false,
    ),
  ];

  final List<Email> _sent = [
    Email(
      id: 's1',
      senderName: 'Tu',
      senderEmail: 'mario@email.com',
      subject: 'Re: Foto del compleanno di Luca',
      preview: 'Grazie Maria! Che belle foto...',
      body: '''Grazie Maria! Che belle foto!

Luca e cresciuto tantissimo. La prossima volta vengo sicuramente!

Baci,
Papa''',
      date: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
      isSent: true,
    ),
  ];

  void _openEmail(Email email) async {
    // Segna come letto
    if (!email.isRead && !email.isSent) {
      setState(() {
        final index = _inbox.indexWhere((e) => e.id == email.id);
        if (index != -1) {
          _inbox[index] = email.copyWith(isRead: true);
        }
      });
    }

    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EmailViewScreen(email: email),
      ),
    );

    if (deleted == true) {
      _deleteEmail(email);
    }
  }

  void _deleteEmail(Email email) {
    setState(() {
      if (email.isSent) {
        _sent.removeWhere((e) => e.id == email.id);
      } else {
        _inbox.removeWhere((e) => e.id == email.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'Messaggio eliminato',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: OlderOSTheme.textSecondary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _composeEmail() async {
    final newEmail = await Navigator.of(context).push<Email>(
      MaterialPageRoute(
        builder: (context) => const ComposeEmailScreen(),
      ),
    );

    if (newEmail != null) {
      setState(() {
        _sent.insert(0, newEmail);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Messaggio inviato!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
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
  }

  @override
  Widget build(BuildContext context) {
    final emails = _showInbox ? _inbox : _sent;
    final unreadCount = _inbox.where((e) => !e.isRead).length;

    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'POSTA',
            onGoHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
              child: Column(
                children: [
                  // Pulsante nuovo messaggio
                  _ComposeButton(onTap: _composeEmail),

                  const SizedBox(height: 24),

                  // Tab Ricevuti / Inviati
                  Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Ricevuti',
                          icon: Icons.inbox,
                          badge: unreadCount > 0 ? unreadCount : null,
                          isActive: _showInbox,
                          onTap: () => setState(() => _showInbox = true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TabButton(
                          label: 'Inviati',
                          icon: Icons.send,
                          isActive: !_showInbox,
                          onTap: () => setState(() => _showInbox = false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Lista email
                  Expanded(
                    child: emails.isEmpty
                        ? _EmptyState(isSent: !_showInbox)
                        : ListView.separated(
                            itemCount: emails.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _EmailCard(
                                email: emails[index],
                                onTap: () => _openEmail(emails[index]),
                              );
                            },
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

class _ComposeButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ComposeButton({required this.onTap});

  @override
  State<_ComposeButton> createState() => _ComposeButtonState();
}

class _ComposeButtonState extends State<_ComposeButton> {
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
            ..scale(_isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0)),
          transformAlignment: Alignment.center,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: _isHovered
                ? OlderOSTheme.primary.withOpacity(0.9)
                : OlderOSTheme.primary,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            boxShadow: [
              BoxShadow(
                color: OlderOSTheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Text(
                'SCRIVI NUOVO MESSAGGIO',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final int? badge;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    this.badge,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.isActive
                ? OlderOSTheme.primary.withOpacity(0.1)
                : (_isHovered ? Colors.grey.shade100 : OlderOSTheme.cardBackground),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive ? OlderOSTheme.primary : Colors.grey.shade300,
              width: widget.isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 28,
                color: widget.isActive
                    ? OlderOSTheme.primary
                    : OlderOSTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: widget.isActive ? FontWeight.bold : FontWeight.normal,
                  color: widget.isActive
                      ? OlderOSTheme.primary
                      : OlderOSTheme.textPrimary,
                ),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: OlderOSTheme.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSent;

  const _EmptyState({required this.isSent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSent ? Icons.send : Icons.inbox,
            size: 100,
            color: OlderOSTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            isSent ? 'Nessun messaggio inviato' : 'Nessun messaggio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailCard extends StatefulWidget {
  final Email email;
  final VoidCallback onTap;

  const _EmailCard({
    required this.email,
    required this.onTap,
  });

  @override
  State<_EmailCard> createState() => _EmailCardState();
}

class _EmailCardState extends State<_EmailCard> {
  bool _isHovered = false;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min fa';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ore fa';
    } else if (diff.inDays == 1) {
      return 'Ieri';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} giorni fa';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !widget.email.isRead && !widget.email.isSent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isUnread
                ? OlderOSTheme.primary.withOpacity(0.05)
                : OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            border: Border.all(
              color: _isHovered
                  ? OlderOSTheme.primary
                  : (isUnread ? OlderOSTheme.primary.withOpacity(0.3) : Colors.transparent),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.06),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getAvatarColor(widget.email.senderName),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(widget.email.senderName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Contenuto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.email.senderName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(widget.email.date),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email.subject,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email.preview,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Indicatore non letto
              if (isUnread)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: OlderOSTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),

              Icon(
                Icons.chevron_right,
                size: 32,
                color: _isHovered ? OlderOSTheme.primary : OlderOSTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      OlderOSTheme.primary,
      OlderOSTheme.success,
      OlderOSTheme.warning,
      OlderOSTheme.videoCallColor,
      OlderOSTheme.emailColor,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
