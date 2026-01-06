import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../services/email_service.dart';
import '../services/draft_service.dart';
import '../services/contact_service.dart';
import 'contacts_screen.dart';

/// Modalità di composizione email
enum ComposeMode { newEmail, reply, forward }

class ComposeEmailScreen extends StatefulWidget {
  final ComposeMode mode;
  final String? replyTo;        // Email destinatario per risposta
  final String? replyToName;    // Nome destinatario per risposta
  final String? originalSubject;
  final String? originalBody;
  final String? originalSender;
  final DateTime? originalDate;

  // Parametri per bozze
  final String? draftId;
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;

  const ComposeEmailScreen({
    super.key,
    this.mode = ComposeMode.newEmail,
    this.replyTo,
    this.replyToName,
    this.originalSubject,
    this.originalBody,
    this.originalSender,
    this.originalDate,
    this.draftId,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
  });

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

  // Lista allegati
  List<File> _attachments = [];

  final _emailService = EmailService();
  final _draftService = DraftService();
  final _contactService = ContactService();

  // Gestione bozze
  String? _currentDraftId;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  // Contatti caricati dal servizio
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _initializeForMode();
    _initializeDraft();
    _startAutoSave();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    await _contactService.loadContacts();
    if (mounted) {
      setState(() {
        _contacts = _contactService.getRecentContacts(limit: 10);
        _filteredContacts = _contacts;
      });
    }
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contactService.getRecentContacts(limit: 10);
      });
    } else {
      setState(() {
        _filteredContacts = _contactService.searchContacts(query);
      });
    }
  }

  void _initializeDraft() {
    // Se abbiamo un draftId, stiamo modificando una bozza esistente
    _currentDraftId = widget.draftId;

    // Inizializza con i valori della bozza se presenti
    if (widget.initialTo != null && widget.initialTo!.isNotEmpty) {
      _toController.text = widget.initialTo!;
    }
    if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
      _subjectController.text = widget.initialSubject!;
    }
    if (widget.initialBody != null && widget.initialBody!.isNotEmpty) {
      _bodyController.text = widget.initialBody!;
    }
  }

  void _startAutoSave() {
    // Salva automaticamente ogni 10 secondi se ci sono modifiche
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_hasUnsavedChanges && !_isSending) {
        _saveDraft();
      }
    });

    // Ascolta le modifiche ai campi
    _toController.addListener(_markAsChanged);
    _subjectController.addListener(_markAsChanged);
    _bodyController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _saveDraft() async {
    // Non salvare se tutti i campi sono vuoti
    if (_toController.text.isEmpty &&
        _subjectController.text.isEmpty &&
        _bodyController.text.isEmpty) {
      return;
    }

    _currentDraftId = await _draftService.saveDraft(
      id: _currentDraftId,
      to: _toController.text,
      subject: _subjectController.text,
      body: _bodyController.text,
    );
    _hasUnsavedChanges = false;
  }

  Future<void> _deleteDraftIfExists() async {
    if (_currentDraftId != null) {
      await _draftService.deleteDraft(_currentDraftId!);
      _currentDraftId = null;
    }
  }

  void _initializeForMode() {
    switch (widget.mode) {
      case ComposeMode.reply:
        // Imposta destinatario
        if (widget.replyTo != null) {
          _toController.text = widget.replyTo!;
        }
        // Imposta oggetto con "Re:"
        if (widget.originalSubject != null) {
          final subject = widget.originalSubject!;
          if (!subject.toLowerCase().startsWith('re:')) {
            _subjectController.text = 'Re: $subject';
          } else {
            _subjectController.text = subject;
          }
        }
        // Prepara corpo con citazione
        if (widget.originalBody != null) {
          final date = widget.originalDate != null
              ? _formatQuoteDate(widget.originalDate!)
              : '';
          final sender = widget.originalSender ?? '';
          _bodyController.text = '\n\n\n--- Messaggio originale ---\nDa: $sender\nData: $date\n\n${widget.originalBody}';
        }
        break;

      case ComposeMode.forward:
        // Imposta oggetto con "Fwd:"
        if (widget.originalSubject != null) {
          final subject = widget.originalSubject!;
          if (!subject.toLowerCase().startsWith('fwd:') &&
              !subject.toLowerCase().startsWith('i:')) {
            _subjectController.text = 'Fwd: $subject';
          } else {
            _subjectController.text = subject;
          }
        }
        // Prepara corpo con messaggio originale
        if (widget.originalBody != null) {
          final date = widget.originalDate != null
              ? _formatQuoteDate(widget.originalDate!)
              : '';
          final sender = widget.originalSender ?? '';
          _bodyController.text = '\n\n\n--- Messaggio inoltrato ---\nDa: $sender\nData: $date\n\n${widget.originalBody}';
        }
        break;

      case ComposeMode.newEmail:
        // Nessuna inizializzazione speciale
        break;
    }
  }

  String _formatQuoteDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _toController.removeListener(_markAsChanged);
    _subjectController.removeListener(_markAsChanged);
    _bodyController.removeListener(_markAsChanged);
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _attachments.add(File(file.path!));
            }
          }
        });
      }
    } catch (e) {
      _showError('Errore nella selezione dei file');
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _selectContact(Contact contact) {
    // Aggiorna l'ultimo utilizzo
    _contactService.markAsUsed(contact.id);
    setState(() {
      _selectedContact = contact;
      _toController.text = contact.email;
      _showContacts = false;
    });
  }

  Future<void> _openContactsScreen() async {
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (context) => const ContactsScreen(selectionMode: true),
      ),
    );

    if (contact != null && mounted) {
      _selectContact(contact);
    }
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
      attachments: _attachments.isNotEmpty ? _attachments : null,
    );

    setState(() => _isSending = false);

    if (error == null) {
      // Successo - elimina la bozza se esiste
      await _deleteDraftIfExists();
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
    final hasContent = _toController.text.isNotEmpty ||
        _subjectController.text.isNotEmpty ||
        _bodyController.text.isNotEmpty;

    if (!hasContent) {
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
          'Cosa vuoi fare?',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Puoi salvare il messaggio come bozza per continuare dopo.',
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
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await _saveDraft();
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              Navigator.of(context).pop({'saved': true});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: OlderOSTheme.warning,
            ),
            child: const Text('Salva bozza', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await _deleteDraftIfExists();
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: OlderOSTheme.danger,
            ),
            child: const Text('Elimina', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case ComposeMode.reply:
        return 'RISPONDI';
      case ComposeMode.forward:
        return 'INOLTRA';
      case ComposeMode.newEmail:
        return 'NUOVO MESSAGGIO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: _getTitle(),
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
                                      // Filtra i contatti mentre si digita
                                      _filterContacts(value);
                                      if (value.isNotEmpty && !_showContacts) {
                                        setState(() => _showContacts = true);
                                      }
                                    },
                                  ),
                                ),
                                // Pulsante rubrica completa
                                IconButton(
                                  icon: const Icon(
                                    Icons.contacts,
                                    size: 32,
                                    color: OlderOSTheme.primary,
                                  ),
                                  tooltip: 'Apri rubrica',
                                  onPressed: _isSending ? null : _openContactsScreen,
                                ),
                                // Pulsante mostra/nascondi suggerimenti
                                IconButton(
                                  icon: Icon(
                                    _showContacts ? Icons.expand_less : Icons.expand_more,
                                    size: 32,
                                    color: OlderOSTheme.textSecondary,
                                  ),
                                  onPressed: _isSending ? null : () => setState(() => _showContacts = !_showContacts),
                                ),
                              ],
                            ),
                          ),

                          // Lista contatti suggeriti / filtrati
                          if (_showContacts)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                color: OlderOSTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: OlderOSTheme.primary),
                              ),
                              child: _filteredContacts.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_add,
                                            size: 40,
                                            color: OlderOSTheme.textSecondary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _contacts.isEmpty
                                                ? 'Rubrica vuota'
                                                : 'Nessun contatto trovato',
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: OlderOSTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          TextButton.icon(
                                            onPressed: _openContactsScreen,
                                            icon: const Icon(Icons.add),
                                            label: const Text('Aggiungi contatto'),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          ..._filteredContacts.map((contact) {
                                            return _ContactTile(
                                              contact: contact,
                                              isSelected: _selectedContact?.id == contact.id,
                                              onTap: () => _selectContact(contact),
                                            );
                                          }),
                                          const Divider(),
                                          // Link alla rubrica completa
                                          InkWell(
                                            onTap: _openContactsScreen,
                                            borderRadius: BorderRadius.circular(8),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.contacts,
                                                    size: 24,
                                                    color: OlderOSTheme.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Apri rubrica completa',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: OlderOSTheme.primary,
                                                      fontWeight: FontWeight.w600,
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

                          // Pulsante allegati
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                _AttachButton(
                                  onTap: _isSending ? () {} : _pickAttachments,
                                ),
                                const SizedBox(width: 16),
                                if (_attachments.isNotEmpty)
                                  Text(
                                    '${_attachments.length} allegat${_attachments.length == 1 ? 'o' : 'i'}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: OlderOSTheme.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Lista allegati
                          if (_attachments.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: OlderOSTheme.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: _attachments.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final file = entry.value;
                                  return _AttachmentTile(
                                    fileName: file.path.split('/').last,
                                    onRemove: _isSending ? null : () => _removeAttachment(index),
                                  );
                                }).toList(),
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

class _AttachButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AttachButton({required this.onTap});

  @override
  State<_AttachButton> createState() => _AttachButtonState();
}

class _AttachButtonState extends State<_AttachButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? OlderOSTheme.primary.withAlpha(26) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OlderOSTheme.primary, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_file, size: 24, color: OlderOSTheme.primary),
              const SizedBox(width: 8),
              Text(
                'ALLEGA FILE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: OlderOSTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final String fileName;
  final VoidCallback? onRemove;

  const _AttachmentTile({
    required this.fileName,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, size: 24, color: OlderOSTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, color: OlderOSTheme.danger),
              onPressed: onRemove,
              tooltip: 'Rimuovi',
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
                  color: _getAvatarColor(widget.contact.name),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.contact.initials,
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
