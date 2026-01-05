import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../services/email_service.dart';
import '../services/draft_service.dart';
import 'email_view_screen.dart';
import 'compose_email_screen.dart';
import 'email_setup_screen.dart';

// Re-export per compatibilita
typedef Email = EmailMessage;

/// Tab attiva nella schermata email
enum EmailTab { inbox, sent, drafts }

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  EmailTab _currentTab = EmailTab.inbox;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  List<EmailMessage> _inbox = [];
  List<EmailMessage> _sent = [];
  List<EmailDraft> _drafts = [];

  final _emailService = EmailService();
  final _draftService = DraftService();

  @override
  void initState() {
    super.initState();
    _initializeEmail();
  }

  Future<void> _initializeEmail() async {
    setState(() => _isLoading = true);

    // Carica credenziali salvate
    final hasCredentials = await _emailService.loadSavedCredentials();

    if (!hasCredentials) {
      // Mostra setup
      if (mounted) {
        final configured = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const EmailSetupScreen(),
          ),
        );

        if (configured != true) {
          // L'utente ha annullato, torna alla home
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
      }
    }

    await _loadEmails();
  }

  Future<void> _loadEmails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inbox = await _emailService.fetchInbox();
      final sent = await _emailService.fetchSent();
      final drafts = await _draftService.getAllDrafts();

      if (mounted) {
        setState(() {
          _inbox = inbox;
          _sent = sent;
          _drafts = drafts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEmails() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final inbox = await _emailService.fetchInbox();
      final sent = await _emailService.fetchSent();
      final drafts = await _draftService.getAllDrafts();

      if (mounted) {
        setState(() {
          _inbox = inbox;
          _sent = sent;
          _drafts = drafts;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Errore nell\'aggiornamento');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _reloadDrafts() async {
    final drafts = await _draftService.getAllDrafts();
    if (mounted) {
      setState(() => _drafts = drafts);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
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

  void _openEmail(EmailMessage email) async {
    // Segna come letto
    if (!email.isRead && !email.isSent) {
      await _emailService.markAsRead(email);
      setState(() {
        final index = _inbox.indexWhere((e) => e.id == email.id);
        if (index != -1) {
          _inbox[index] = email.copyWith(isRead: true);
        }
      });
    }

    if (!mounted) return;

    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EmailViewScreen(email: email),
      ),
    );

    if (deleted == true) {
      _deleteEmail(email);
    }
  }

  Future<void> _deleteEmail(EmailMessage email) async {
    await _emailService.deleteEmail(email);

    setState(() {
      if (email.isSent) {
        _sent.removeWhere((e) => e.id == email.id);
      } else {
        _inbox.removeWhere((e) => e.id == email.id);
      }
    });

    if (mounted) {
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
  }

  void _composeEmail() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const ComposeEmailScreen(),
      ),
    );

    if (result != null && result['sent'] == true) {
      // Aggiorna la lista
      await _refreshEmails();

      if (mounted) {
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
  }

  Widget _buildEmailList() {
    switch (_currentTab) {
      case EmailTab.inbox:
        if (_inbox.isEmpty) {
          return const _EmptyState(type: EmailTab.inbox);
        }
        return ListView.separated(
          itemCount: _inbox.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _EmailCard(
              email: _inbox[index],
              onTap: () => _openEmail(_inbox[index]),
            );
          },
        );

      case EmailTab.sent:
        if (_sent.isEmpty) {
          return const _EmptyState(type: EmailTab.sent);
        }
        return ListView.separated(
          itemCount: _sent.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _EmailCard(
              email: _sent[index],
              onTap: () => _openEmail(_sent[index]),
            );
          },
        );

      case EmailTab.drafts:
        if (_drafts.isEmpty) {
          return const _EmptyState(type: EmailTab.drafts);
        }
        return ListView.separated(
          itemCount: _drafts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _DraftCard(
              draft: _drafts[index],
              onTap: () => _openDraft(_drafts[index]),
              onDelete: () => _deleteDraft(_drafts[index]),
            );
          },
        );
    }
  }

  void _openDraft(EmailDraft draft) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => ComposeEmailScreen(
          draftId: draft.id,
          initialTo: draft.to,
          initialSubject: draft.subject,
          initialBody: draft.body,
        ),
      ),
    );

    // Ricarica le bozze dopo la modifica
    await _reloadDrafts();

    if (result != null && result['sent'] == true) {
      await _refreshEmails();
      if (mounted) {
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
  }

  Future<void> _deleteDraft(EmailDraft draft) async {
    await _draftService.deleteDraft(draft.id);
    await _reloadDrafts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'Bozza eliminata',
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
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _inbox.where((e) => !e.isRead).length;
    final draftCount = _drafts.length;

    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'POSTA',
            onGoHome: () => Navigator.of(context).pop(),
          ),

          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: OlderOSTheme.primary,
                      strokeWidth: 4,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Caricamento messaggi...',
                      style: TextStyle(
                        fontSize: 22,
                        color: OlderOSTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 80,
                        color: OlderOSTheme.textSecondary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Problema di connessione',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: OlderOSTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _ActionButton(
                        label: 'RIPROVA',
                        icon: Icons.refresh,
                        onTap: _loadEmails,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
                child: Column(
                  children: [
                    // Pulsante nuovo messaggio
                    _ComposeButton(onTap: _composeEmail),

                    const SizedBox(height: 24),

                    // Tab Ricevuti / Inviati / Bozze + Aggiorna
                    Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: 'Ricevuti',
                            icon: Icons.inbox,
                            badge: unreadCount > 0 ? unreadCount : null,
                            isActive: _currentTab == EmailTab.inbox,
                            onTap: () => setState(() => _currentTab = EmailTab.inbox),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TabButton(
                            label: 'Inviati',
                            icon: Icons.send,
                            isActive: _currentTab == EmailTab.sent,
                            onTap: () => setState(() => _currentTab = EmailTab.sent),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TabButton(
                            label: 'Bozze',
                            icon: Icons.drafts,
                            badge: draftCount > 0 ? draftCount : null,
                            isActive: _currentTab == EmailTab.drafts,
                            onTap: () async {
                              await _reloadDrafts();
                              setState(() => _currentTab = EmailTab.drafts);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        _RefreshButton(
                          isRefreshing: _isRefreshing,
                          onTap: _refreshEmails,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Lista email o bozze
                    Expanded(
                      child: _buildEmailList(),
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
                ? OlderOSTheme.primary.withAlpha(230)
                : OlderOSTheme.primary,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            boxShadow: [
              BoxShadow(
                color: OlderOSTheme.primary.withAlpha(77),
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

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered ? OlderOSTheme.primary : OlderOSTheme.primary.withAlpha(230),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatefulWidget {
  final bool isRefreshing;
  final VoidCallback onTap;

  const _RefreshButton({
    required this.isRefreshing,
    required this.onTap,
  });

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isRefreshing ? null : widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered && !widget.isRefreshing
                ? Colors.grey.shade200
                : OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: widget.isRefreshing
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: OlderOSTheme.primary,
                  ),
                )
              : Icon(
                  Icons.refresh,
                  size: 28,
                  color: _isHovered ? OlderOSTheme.primary : OlderOSTheme.textSecondary,
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
                ? OlderOSTheme.primary.withAlpha(26)
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
  final EmailTab type;

  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String message;

    switch (type) {
      case EmailTab.inbox:
        icon = Icons.inbox;
        message = 'Nessun messaggio';
        break;
      case EmailTab.sent:
        icon = Icons.send;
        message = 'Nessun messaggio inviato';
        break;
      case EmailTab.drafts:
        icon = Icons.drafts;
        message = 'Nessuna bozza';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: OlderOSTheme.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: 20),
          Text(
            message,
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
  final EmailMessage email;
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
                ? OlderOSTheme.primary.withAlpha(13)
                : OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            border: Border.all(
              color: _isHovered
                  ? OlderOSTheme.primary
                  : (isUnread ? OlderOSTheme.primary.withAlpha(77) : Colors.transparent),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_isHovered ? 31 : 15),
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
    // Rimuovi "A: " per email inviate
    if (name.startsWith('A: ')) {
      name = name.substring(3);
    }

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
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

/// Card per visualizzare una bozza
class _DraftCard extends StatefulWidget {
  final EmailDraft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DraftCard({
    required this.draft,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            border: Border.all(
              color: _isHovered ? OlderOSTheme.warning : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_isHovered ? 31 : 15),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icona bozza
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: OlderOSTheme.warning.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.edit_note,
                    color: OlderOSTheme.warning,
                    size: 32,
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
                            widget.draft.to.isNotEmpty
                                ? 'A: ${widget.draft.to}'
                                : 'Nessun destinatario',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.draft.to.isEmpty
                                  ? OlderOSTheme.textSecondary
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(widget.draft.lastModified),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.draft.subject.isNotEmpty
                          ? widget.draft.subject
                          : '(Nessun oggetto)',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontStyle: widget.draft.subject.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: widget.draft.subject.isEmpty
                            ? OlderOSTheme.textSecondary
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.draft.body.isNotEmpty
                          ? widget.draft.body.replaceAll('\n', ' ')
                          : '(Nessun contenuto)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: OlderOSTheme.textSecondary,
                        fontStyle: widget.draft.body.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Pulsante elimina
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 28,
                  color: OlderOSTheme.danger,
                ),
                tooltip: 'Elimina bozza',
              ),

              Icon(
                Icons.chevron_right,
                size: 32,
                color: _isHovered ? OlderOSTheme.warning : OlderOSTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
