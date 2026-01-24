import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../services/first_run_service.dart';
import '../services/contact_service.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';
import 'email_setup_screen.dart';

/// Wizard di configurazione iniziale per OlderOS
class SetupWizardScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SetupWizardScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _firstRunService = FirstRunService();
  final _contactService = ContactService();
  final _userService = UserService();
  final _pageController = PageController();

  int _currentPage = 0;
  static const _totalPages = 4; // Ridotto da 5 a 4 (rimossa pagina nome)

  // Dati dall'account utente (non piu' richiesti)
  String _userName = '';
  int _avatarColorIndex = 0;
  bool _emailConfigured = false;
  final List<_FamilyContact> _familyContacts = [];

  @override
  void initState() {
    super.initState();
    // Carica nome e avatar dall'account utente gia' creato
    final currentUser = _userService.currentUser;
    if (currentUser != null) {
      _userName = currentUser.name;
      _avatarColorIndex = currentUser.avatarColorIndex;
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    // Nome e avatar sono gia' salvati nell'account utente
    // Li sincronizziamo anche nel FirstRunService per compatibilita'
    await _firstRunService.setUserName(_userName);
    await _firstRunService.setAvatarColor(_avatarColorIndex);

    // Salva contatti familiari
    await _contactService.loadContacts();
    for (final contact in _familyContacts) {
      await _contactService.addContact(
        name: contact.name,
        email: contact.email,
        phone: contact.phone,
        notes: contact.relation,
      );
    }

    // Marca setup come completato
    await _firstRunService.completeSetup();

    // Callback completamento
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(24),
                child: _ProgressIndicator(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                ),
              ),

              // Pages (4 pagine: Benvenuto, Email, Contatti, Completamento)
              // Nome e avatar sono gia' stati raccolti nella creazione account
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    _WelcomePage(
                      userName: _userName,
                      onNext: _nextPage,
                    ),
                    _EmailSetupPage(
                      emailConfigured: _emailConfigured,
                      onEmailConfigured: (configured) => setState(() => _emailConfigured = configured),
                      onNext: _nextPage,
                      onBack: _previousPage,
                    ),
                    _FamilyContactsPage(
                      contacts: _familyContacts,
                      onContactsChanged: () => setState(() {}),
                      onNext: _nextPage,
                      onBack: _previousPage,
                    ),
                    _CompletionPage(
                      userName: _userName,
                      avatarColor: UserAvatarColors.getColor(_avatarColorIndex),
                      emailConfigured: _emailConfigured,
                      contactsCount: _familyContacts.length,
                      onComplete: _completeSetup,
                      onBack: _previousPage,
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

/// Indicatore di progresso
class _ProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _ProgressIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        final isCompleted = index < currentPage;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 40 : 16,
          height: 16,
          decoration: BoxDecoration(
            color: isCompleted
                ? OlderOSTheme.success
                : (isActive ? OlderOSTheme.primary : OlderOSTheme.textSecondary.withAlpha(50)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : null,
        );
      }),
    );
  }
}

/// Pagina 1: Benvenuto (personalizzato con nome utente)
class _WelcomePage extends StatelessWidget {
  final String userName;
  final VoidCallback onNext;

  const _WelcomePage({
    required this.userName,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji anziano sorridente
          const Text(
            '👴🏻',
            style: TextStyle(fontSize: 120),
          ),

          const SizedBox(height: 48),

          Text(
            userName.isNotEmpty ? 'Ciao $userName!' : 'Benvenuto in OlderOS',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: OlderOSTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          Text(
            'Configuriamo insieme il tuo dispositivo.\nAggiungi email e contatti per iniziare.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 64),

          _BigWizardButton(
            label: 'INIZIAMO',
            icon: Icons.arrow_forward,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

/// Pagina 2: Configurazione Email
class _EmailSetupPage extends StatelessWidget {
  final bool emailConfigured;
  final ValueChanged<bool> onEmailConfigured;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _EmailSetupPage({
    required this.emailConfigured,
    required this.onEmailConfigured,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emailConfigured ? Icons.mark_email_read : Icons.email_outlined,
            size: 100,
            color: emailConfigured ? OlderOSTheme.success : OlderOSTheme.primary,
          ),

          const SizedBox(height: 32),

          Text(
            'Configurare la posta?',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            emailConfigured
                ? 'Email configurata correttamente!'
                : 'Potrai inviare e ricevere email.\nPuoi farlo anche dopo.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          if (!emailConfigured)
            _BigWizardButton(
              label: 'CONFIGURA EMAIL',
              icon: Icons.settings,
              color: OlderOSTheme.emailColor,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EmailSetupScreen(
                      onComplete: () {
                        onEmailConfigured(true);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),

          if (emailConfigured)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OlderOSTheme.success.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OlderOSTheme.success),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: OlderOSTheme.success, size: 32),
                  const SizedBox(width: 16),
                  Text(
                    'Email pronta!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: OlderOSTheme.success,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _WizardNavButton(
                label: 'INDIETRO',
                icon: Icons.arrow_back,
                isSecondary: true,
                onTap: onBack,
              ),
              const SizedBox(width: 24),
              _BigWizardButton(
                label: emailConfigured ? 'AVANTI' : 'SALTA',
                icon: Icons.arrow_forward,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pagina 3: Contatti familiari
class _FamilyContactsPage extends StatefulWidget {
  final List<_FamilyContact> contacts;
  final VoidCallback onContactsChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _FamilyContactsPage({
    required this.contacts,
    required this.onContactsChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_FamilyContactsPage> createState() => _FamilyContactsPageState();
}

class _FamilyContactsPageState extends State<_FamilyContactsPage> {
  void _addContact() {
    showDialog(
      context: context,
      builder: (ctx) => _AddContactDialog(
        onAdd: (contact) {
          widget.contacts.add(contact);
          widget.onContactsChanged();
        },
      ),
    );
  }

  void _removeContact(int index) {
    widget.contacts.removeAt(index);
    widget.onContactsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            'Aggiungi i tuoi familiari',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Potrai chiamarli e scrivergli facilmente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Lista contatti aggiunti
          if (widget.contacts.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: widget.contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return _ContactCard(
                    contact: contact,
                    onRemove: () => _removeContact(index),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Bottone aggiungi
          _BigWizardButton(
            label: widget.contacts.isEmpty ? 'AGGIUNGI FAMILIARE' : 'AGGIUNGI ALTRO',
            icon: Icons.person_add,
            color: OlderOSTheme.contactsColor,
            onTap: _addContact,
          ),

          if (widget.contacts.isEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Puoi aggiungere contatti anche dopo',
              style: TextStyle(
                fontSize: 18,
                color: OlderOSTheme.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _WizardNavButton(
                label: 'INDIETRO',
                icon: Icons.arrow_back,
                isSecondary: true,
                onTap: widget.onBack,
              ),
              const SizedBox(width: 24),
              _BigWizardButton(
                label: 'AVANTI',
                icon: Icons.arrow_forward,
                onTap: widget.onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pagina 4: Completamento
class _CompletionPage extends StatelessWidget {
  final String userName;
  final Color avatarColor;
  final bool emailConfigured;
  final int contactsCount;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const _CompletionPage({
    required this.userName,
    required this.avatarColor,
    required this.emailConfigured,
    required this.contactsCount,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: avatarColor.withAlpha(100),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
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
            'Tutto pronto, $userName!',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Riepilogo
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: OlderOSTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _SummaryItem(
                  icon: Icons.person,
                  label: 'Nome',
                  value: userName,
                  color: avatarColor,
                ),
                const Divider(height: 24),
                _SummaryItem(
                  icon: Icons.email,
                  label: 'Email',
                  value: emailConfigured ? 'Configurata' : 'Non configurata',
                  color: emailConfigured ? OlderOSTheme.success : OlderOSTheme.textSecondary,
                ),
                const Divider(height: 24),
                _SummaryItem(
                  icon: Icons.people,
                  label: 'Contatti',
                  value: contactsCount > 0 ? '$contactsCount aggiunti' : 'Nessuno',
                  color: contactsCount > 0 ? OlderOSTheme.contactsColor : OlderOSTheme.textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _WizardNavButton(
                label: 'INDIETRO',
                icon: Icons.arrow_back,
                isSecondary: true,
                onTap: onBack,
              ),
              const SizedBox(width: 24),
              _BigWizardButton(
                label: 'INIZIA A USARE',
                icon: Icons.check,
                color: OlderOSTheme.success,
                onTap: onComplete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card contatto
class _ContactCard extends StatelessWidget {
  final _FamilyContact contact;
  final VoidCallback onRemove;

  const _ContactCard({
    required this.contact,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OlderOSTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OlderOSTheme.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: OlderOSTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (contact.relation.isNotEmpty)
                  Text(
                    contact.relation,
                    style: TextStyle(
                      fontSize: 16,
                      color: OlderOSTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: OlderOSTheme.danger),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Dialog aggiunta contatto
class _AddContactDialog extends StatefulWidget {
  final ValueChanged<_FamilyContact> onAdd;

  const _AddContactDialog({required this.onAdd});

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRelation = '';

  static const _relations = [
    'Figlio/a',
    'Nipote',
    'Fratello/Sorella',
    'Coniuge',
    'Amico/a',
    'Altro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.person_add, color: OlderOSTheme.primary, size: 32),
          const SizedBox(width: 12),
          const Text('Nuovo familiare'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 20),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nome *',
                  labelStyle: const TextStyle(fontSize: 18),
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Relazione
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _relations.map((relation) {
                  final isSelected = _selectedRelation == relation;
                  return ChoiceChip(
                    label: Text(relation, style: const TextStyle(fontSize: 16)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedRelation = selected ? relation : '';
                      });
                    },
                    selectedColor: OlderOSTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : OlderOSTheme.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                style: const TextStyle(fontSize: 20),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(fontSize: 18),
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _phoneController,
                style: const TextStyle(fontSize: 20),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefono',
                  labelStyle: const TextStyle(fontSize: 18),
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'ANNULLA',
            style: TextStyle(
              fontSize: 18,
              color: OlderOSTheme.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  widget.onAdd(_FamilyContact(
                    name: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim(),
                    relation: _selectedRelation,
                  ));
                  Navigator.of(context).pop();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: OlderOSTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('AGGIUNGI', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}

/// Item riepilogo
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: OlderOSTheme.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bottone grande wizard
class _BigWizardButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool enabled;
  final VoidCallback onTap;

  const _BigWizardButton({
    required this.label,
    required this.icon,
    this.color,
    this.enabled = true,
    required this.onTap,
  });

  @override
  State<_BigWizardButton> createState() => _BigWizardButtonState();
}

class _BigWizardButtonState extends State<_BigWizardButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled
        ? (widget.color ?? OlderOSTheme.primary)
        : OlderOSTheme.textSecondary;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Icon(widget.icon, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

/// Bottone navigazione wizard
class _WizardNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSecondary;
  final VoidCallback onTap;

  const _WizardNavButton({
    required this.label,
    required this.icon,
    this.isSecondary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 20)),
      style: TextButton.styleFrom(
        foregroundColor: isSecondary ? OlderOSTheme.textSecondary : OlderOSTheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}

/// Modello contatto familiare
class _FamilyContact {
  final String name;
  final String email;
  final String phone;
  final String relation;

  _FamilyContact({
    required this.name,
    required this.email,
    required this.phone,
    required this.relation,
  });
}
