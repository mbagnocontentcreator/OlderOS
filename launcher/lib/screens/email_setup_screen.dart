import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../widgets/big_button.dart';
import '../services/email_service.dart';

class EmailSetupScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const EmailSetupScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<EmailSetupScreen> createState() => _EmailSetupScreenState();
}

class _EmailSetupScreenState extends State<EmailSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showManualForm = false;
  bool _obscurePassword = true;
  String? _error;

  final _emailService = EmailService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Verifica se OAuth e' configurato
    if (!_emailService.isGoogleOAuthConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'L\'accesso rapido Google non è disponibile.\nUsa la configurazione manuale qui sotto inserendo email e password.';
      });
      return;
    }

    final error = await _emailService.signInWithGoogle();

    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        widget.onComplete?.call();
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() => _error = error);
    }
  }

  Future<void> _configureManualAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final error = await _emailService.configureAccount(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        widget.onComplete?.call();
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'CONFIGURA POSTA',
            onGoHome: () => Navigator.of(context).pop(false),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _showManualForm
                      ? _buildManualForm()
                      : _buildMainOptions(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icona e titolo
        const Icon(
          Icons.email_outlined,
          size: 80,
          color: OlderOSTheme.emailColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Configura la tua email',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Scegli come vuoi accedere alla tua posta',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: OlderOSTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        // Pulsante Google (consigliato)
        _GoogleSignInButton(
          isLoading: _isLoading,
          onTap: _signInWithGoogle,
        ),

        const SizedBox(height: 16),

        Text(
          'Consigliato per Gmail',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: OlderOSTheme.success,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Divider
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'oppure',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: OlderOSTheme.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 32),

        // Pulsante altro provider
        _OutlineButton(
          label: 'USA UN ALTRO PROVIDER',
          icon: Icons.email,
          onTap: () => setState(() => _showManualForm = true),
        ),

        const SizedBox(height: 8),

        Text(
          'Per Outlook, Libero, Yahoo e altri',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: OlderOSTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        // Errore
        if (_error != null) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OlderOSTheme.danger.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OlderOSTheme.danger),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: OlderOSTheme.danger, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: OlderOSTheme.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Pulsante annulla
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Annulla',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pulsante indietro
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _showManualForm = false;
                _error = null;
              }),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Indietro'),
            ),
          ),

          const SizedBox(height: 16),

          // Icona e titolo
          const Icon(
            Icons.email_outlined,
            size: 60,
            color: OlderOSTheme.emailColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Inserisci i dati del tuo account',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Campo nome
          _FormField(
            controller: _nameController,
            label: 'Il tuo nome',
            hint: 'es. Mario Rossi',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Inserisci il tuo nome';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Campo email
          _FormField(
            controller: _emailController,
            label: 'Indirizzo email',
            hint: 'es. mario.rossi@libero.it',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Inserisci la tua email';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Inserisci un indirizzo email valido';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Campo password
          _FormField(
            controller: _passwordController,
            label: 'Password',
            hint: 'La password della tua email',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                size: 28,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Inserisci la password';
              }
              return null;
            },
          ),

          // Errore
          if (_error != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OlderOSTheme.danger.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OlderOSTheme.danger),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: OlderOSTheme.danger, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: OlderOSTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Pulsante configura
          if (_isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: OlderOSTheme.primary,
                    strokeWidth: 4,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sto configurando l\'account...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: OlderOSTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            BigButton(
              label: 'CONFIGURA ACCOUNT',
              icon: Icons.check,
              backgroundColor: OlderOSTheme.primary,
              onTap: _configureManualAccount,
            ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GoogleSignInButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 16),
            Text(
              'Connessione a Google...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? OlderOSTheme.primary : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_isHovered ? 26 : 13),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google logo (simplified)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [
                            Color(0xFF4285F4), // Blue
                            Color(0xFF34A853), // Green
                            Color(0xFFFBBC05), // Yellow
                            Color(0xFFEA4335), // Red
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 28, 28)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'ACCEDI CON GOOGLE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
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
            color: _isHovered ? OlderOSTheme.primary.withAlpha(13) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? OlderOSTheme.primary : OlderOSTheme.textSecondary,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 28,
                color: _isHovered ? OlderOSTheme.primary : OlderOSTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? OlderOSTheme.primary : OlderOSTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 18,
              color: OlderOSTheme.textSecondary.withAlpha(150),
            ),
            prefixIcon: Icon(icon, size: 28),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: OlderOSTheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: OlderOSTheme.danger, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: OlderOSTheme.danger, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
