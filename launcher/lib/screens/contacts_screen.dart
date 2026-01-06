import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../services/contact_service.dart';

/// Schermata per gestire la rubrica contatti
class ContactsScreen extends StatefulWidget {
  /// Se true, e in modalita selezione (per scegliere un destinatario email)
  final bool selectionMode;

  const ContactsScreen({
    super.key,
    this.selectionMode = false,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _contactService = ContactService();
  final _searchController = TextEditingController();

  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    await _contactService.loadContacts();
    final contacts = _contactService.getContactsAlphabetically();

    if (mounted) {
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    }
  }

  void _filterContacts() {
    final query = _searchController.text;
    setState(() {
      _filteredContacts = _contactService.searchContacts(query);
    });
  }

  void _selectContact(Contact contact) {
    // Aggiorna l'ultimo utilizzo
    _contactService.markAsUsed(contact.id);
    Navigator.of(context).pop(contact);
  }

  void _addContact() async {
    final result = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (context) => const _ContactEditScreen(),
      ),
    );

    if (result != null) {
      await _loadContacts();
      if (mounted) {
        _showSuccess('Contatto aggiunto');
      }
    }
  }

  void _editContact(Contact contact) async {
    final result = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (context) => _ContactEditScreen(contact: contact),
      ),
    );

    if (result != null) {
      await _loadContacts();
      if (mounted) {
        _showSuccess('Contatto modificato');
      }
    }
  }

  void _deleteContact(Contact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Text(
          'Eliminare il contatto?',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Vuoi eliminare "${contact.name}" dalla rubrica?',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annulla',
              style: TextStyle(fontSize: 18, color: OlderOSTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: OlderOSTheme.danger,
            ),
            child: const Text('Elimina', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _contactService.deleteContact(contact.id);
      await _loadContacts();
      if (mounted) {
        _showSuccess('Contatto eliminato');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontSize: 18)),
          ],
        ),
        backgroundColor: OlderOSTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: widget.selectionMode ? 'SCEGLI CONTATTO' : 'RUBRICA',
            onGoHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
              child: Column(
                children: [
                  // Barra azioni
                  Row(
                    children: [
                      // Campo ricerca
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: OlderOSTheme.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 28,
                                color: OlderOSTheme.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Cerca contatto...',
                                    hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: OlderOSTheme.textSecondary,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Pulsante aggiungi
                      _AddContactButton(onTap: _addContact),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Lista contatti
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: OlderOSTheme.primary,
                            ),
                          )
                        : _filteredContacts.isEmpty
                            ? _EmptyState(
                                hasSearch: _searchController.text.isNotEmpty,
                                onAddContact: _addContact,
                              )
                            : ListView.separated(
                                itemCount: _filteredContacts.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final contact = _filteredContacts[index];
                                  return _ContactCard(
                                    contact: contact,
                                    selectionMode: widget.selectionMode,
                                    onTap: widget.selectionMode
                                        ? () => _selectContact(contact)
                                        : () => _editContact(contact),
                                    onDelete: widget.selectionMode
                                        ? null
                                        : () => _deleteContact(contact),
                                  );
                                },
                              ),
                  ),

                  // Contatore
                  if (!_isLoading && _contacts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        '${_contacts.length} contatt${_contacts.length == 1 ? 'o' : 'i'} in rubrica',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: OlderOSTheme.textSecondary,
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

/// Pulsante per aggiungere un contatto
class _AddContactButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddContactButton({required this.onTap});

  @override
  State<_AddContactButton> createState() => _AddContactButtonState();
}

class _AddContactButtonState extends State<_AddContactButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered
                ? OlderOSTheme.primary.withAlpha(230)
                : OlderOSTheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: OlderOSTheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.person_add, size: 28, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'NUOVO CONTATTO',
                style: TextStyle(
                  fontSize: 18,
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

/// Stato vuoto
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAddContact;

  const _EmptyState({
    required this.hasSearch,
    required this.onAddContact,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.contacts,
            size: 100,
            color: OlderOSTheme.textSecondary.withAlpha(128),
          ),
          const SizedBox(height: 20),
          Text(
            hasSearch
                ? 'Nessun contatto trovato'
                : 'La rubrica e vuota',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 24),
            Text(
              'Aggiungi il tuo primo contatto!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: OlderOSTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddContact,
              icon: const Icon(Icons.person_add, size: 28),
              label: const Text(
                'AGGIUNGI CONTATTO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: OlderOSTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card per visualizzare un contatto
class _ContactCard extends StatefulWidget {
  final Contact contact;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ContactCard({
    required this.contact,
    required this.selectionMode,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            border: Border.all(
              color: _isHovered ? OlderOSTheme.primary : Colors.transparent,
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
                  color: _getAvatarColor(widget.contact.name),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.contact.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Info contatto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contact.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: OlderOSTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.contact.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.contact.phone != null && widget.contact.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: OlderOSTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.contact.phone!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Azioni
              if (widget.onDelete != null && !widget.selectionMode)
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 28,
                    color: OlderOSTheme.danger,
                  ),
                  tooltip: 'Elimina',
                ),

              Icon(
                widget.selectionMode ? Icons.check_circle_outline : Icons.edit,
                size: 28,
                color: _isHovered ? OlderOSTheme.primary : OlderOSTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Schermata per modificare/creare un contatto
class _ContactEditScreen extends StatefulWidget {
  final Contact? contact;

  const _ContactEditScreen({this.contact});

  @override
  State<_ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<_ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  final _contactService = ContactService();
  bool _isSaving = false;

  bool get isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _emailController.text = widget.contact!.email;
      _phoneController.text = widget.contact!.phone ?? '';
      _notesController.text = widget.contact!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      Contact savedContact;

      if (isEditing) {
        savedContact = widget.contact!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        await _contactService.updateContact(savedContact);
      } else {
        savedContact = await _contactService.addContact(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(savedContact);
      }
    } catch (e) {
      _showError('Errore nel salvataggio');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 28),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: isEditing ? 'MODIFICA CONTATTO' : 'NUOVO CONTATTO',
            onGoHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(32),
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
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar centrato
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: OlderOSTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: _nameController.text.isNotEmpty
                                        ? Text(
                                            _getInitials(_nameController.text),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Nome
                              _FormField(
                                label: 'Nome *',
                                icon: Icons.person_outline,
                                child: TextFormField(
                                  controller: _nameController,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  decoration: _inputDecoration('Es: Maria Rossi'),
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Inserisci un nome';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Email
                              _FormField(
                                label: 'Email *',
                                icon: Icons.email_outlined,
                                child: TextFormField(
                                  controller: _emailController,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration('Es: maria@email.com'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Inserisci un\'email';
                                    }
                                    if (!value.contains('@') || !value.contains('.')) {
                                      return 'Email non valida';
                                    }
                                    if (_contactService.emailExists(
                                      value.trim(),
                                      excludeId: widget.contact?.id,
                                    )) {
                                      return 'Questa email esiste gia nella rubrica';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Telefono
                              _FormField(
                                label: 'Telefono',
                                icon: Icons.phone_outlined,
                                child: TextFormField(
                                  controller: _phoneController,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDecoration('Es: 333 1234567'),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Note
                              _FormField(
                                label: 'Note',
                                icon: Icons.note_outlined,
                                child: TextFormField(
                                  controller: _notesController,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 3,
                                  decoration: _inputDecoration('Es: Figlia, lavora a Milano'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pulsanti azione
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'ANNULLA',
                          icon: Icons.close,
                          color: OlderOSTheme.textSecondary,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _SaveButton(
                          isSaving: _isSaving,
                          onTap: _save,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: OlderOSTheme.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: OlderOSTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: OlderOSTheme.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _FormField({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: OlderOSTheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered ? widget.color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 24, color: widget.color),
              const SizedBox(width: 12),
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

class _SaveButton extends StatefulWidget {
  final bool isSaving;
  final VoidCallback onTap;

  const _SaveButton({
    required this.isSaving,
    required this.onTap,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isSaving ? null : widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered && !widget.isSaving
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.isSaving
                ? const [
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
                      'SALVATAGGIO...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ]
                : const [
                    Icon(Icons.save, size: 28, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'SALVA CONTATTO',
                      style: TextStyle(
                        fontSize: 18,
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
