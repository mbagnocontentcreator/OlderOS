import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../services/email_service.dart';

class Contact {
  final String name;
  final String email;

  const Contact({required this.name, required this.email});
}

class ComposeEmailScreen extends StatefulWidget {
  const ComposeEmailScreen({super.key});

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  Contact? _selectedContact;
  bool _showContacts = false;
  bool _isSending = false;

  final _emailService = EmailService();

  // TODO: In futuro, caricare i contatti da rubrica salvata
  final List<Contact> _contacts = const [
    Contact(name: 'Maria (figlia)', email: 'maria@email.com'),
    Contact(name: 'Luca (nipote)', email: 'luca@email.com'),
    Contact(name: 'Paolo (figlio)', email: 'paolo@email.com'),
    Contact(name: 'Anna (sorella)', email: 'anna@email.com'),
    Contact(name: 'Dott. Rossi', email: 'rossi@studio.it'),
  ];

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _selectContact(Contact contact) {
    setState(() {
      _selectedContact = contact;
      _toController.text = contact.email;
      _showContacts = false;
    });
  }

  Future<void> _send() async {
    // Ottieni l'indirizzo email
    String toEmail = _toController.text.trim();

    // Se e' stato selezionato un contatto, usa la sua email
    if (_selectedContact != null) {
      toEmail = _selectedContact!.email;
    }

    if (toEmail.isEmpty) {
      _showError('Inserisci un destinatario');
      return;
    }
    if (!toEmail.contains('@') || !toEmail.contains('.')) {
      _showError('Inserisci un indirizzo email valido');
      return;
    }
    if (_subjectController.text.isEmpty) {
      _showError('Inserisci un oggetto');
      return;
    }
    if (_bodyController.text.isEmpty) {
      _showError('Scrivi un messaggio');
      return;
    }

    setState(() => _isSending = true);

    final error = await _emailService.sendEmail(
      to: toEmail,
      subject: _subjectController.text,
      body: _bodyController.text,
    );

    setState(() => _isSending = false);

    if (error == null) {
      // Successo
      if (mounted) {
        Navigator.of(context).pop({'sent': true});
      }
    } else {
      _showError(error);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontSize: 18)),
          ],
        ),
        backgroundColor: OlderOSTheme.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmDiscard() {
    if (_toController.text.isEmpty &&
        _subjectController.text.isEmpty &&
        _bodyController.text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Text(
          'Annullare il messaggio?',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Il messaggio non sara salvato.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Continua a scrivere',
              style: TextStyle(fontSize: 18, color: OlderOSTheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: OlderOSTheme.danger,
            ),
            child: const Text('Annulla messaggio', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'NUOVO MESSAGGIO',
            onGoHome: _confirmDiscard,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
              child: Column(
                children: [
                  // Barra azioni
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.close,
                        label: 'ANNULLA',
                        color: OlderOSTheme.textSecondary,
                        onTap: _isSending ? () {} : _confirmDiscard,
                      ),
                      const Spacer(),
                      _isSending
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              decoration: BoxDecoration(
                                color: OlderOSTheme.success.withAlpha(180),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'INVIO IN CORSO...',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _SendButton(onTap: _send),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Form email
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: OlderOSTheme.cardBackground,
                        borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Destinatario
                          _FormField(
                            label: 'A:',
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _toController,
                                    style: Theme.of(context).textTheme.titleMedium,
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !_isSending,
                                    decoration: InputDecoration(
                                      hintText: 'Scrivi email o scegli contatto...',
                                      hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: OlderOSTheme.textSecondary,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      // Se l'utente modifica il testo, deseleziona il contatto
                                      if (_selectedContact != null && value != _selectedContact!.email) {
                                        setState(() => _selectedContact = null);
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _showContacts ? Icons.expand_less : Icons.contacts,
                                    size: 32,
                                    color: OlderOSTheme.primary,
                                  ),
                                  onPressed: _isSending ? null : () => setState(() => _showContacts = !_showContacts),
                                ),
                              ],
                            ),
                          ),

                          // Lista contatti
                          if (_showContacts)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: OlderOSTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: OlderOSTheme.primary),
                              ),
                              child: Column(
                                children: _contacts.map((contact) {
                                  return _ContactTile(
                                    contact: contact,
                                    isSelected: _selectedContact == contact,
                                    onTap: () => _selectContact(contact),
                                  );
                                }).toList(),
                              ),
                            ),

                          const Divider(),

                          // Oggetto
                          _FormField(
                            label: 'Oggetto:',
                            child: TextField(
                              controller: _subjectController,
                              style: Theme.of(context).textTheme.titleMedium,
                              decoration: InputDecoration(
                                hintText: 'Inserisci oggetto...',
                                hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: OlderOSTheme.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          const Divider(),

                          // Corpo messaggio
                          Expanded(
                            child: TextField(
                              controller: _bodyController,
                              style: Theme.of(context).textTheme.bodyLarge,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                hintText: 'Scrivi il tuo messaggio qui...',
                                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: OlderOSTheme.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: OlderOSTheme.textSecondary,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ContactTile extends StatefulWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactTile({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? OlderOSTheme.primary.withOpacity(0.1)
                : (_isHovered ? Colors.grey.shade100 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: OlderOSTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.contact.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contact.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      widget.contact.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_circle, color: OlderOSTheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? widget.color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 24, color: widget.color),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SendButton({required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? OlderOSTheme.success.withOpacity(0.9)
                : OlderOSTheme.success,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: OlderOSTheme.success.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.send, size: 28, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'INVIA',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
