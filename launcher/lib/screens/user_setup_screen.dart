import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/pin_keypad.dart';
import '../theme/olderos_theme.dart';

/// Schermata per la creazione di un nuovo utente
class UserSetupScreen extends StatefulWidget {
  final bool isFirstUser;
  final VoidCallback onComplete;
  final VoidCallback? onCancel;
  final bool autoLogin;

  const UserSetupScreen({
    super.key,
    this.isFirstUser = false,
    required this.onComplete,
    this.onCancel,
    this.autoLogin = true,
  });

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final UserService _userService = UserService();
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();

  int _currentPage = 0;
  int _avatarColorIndex = 0;
  String _pin = '';
  String _confirmPin = '';
  bool _pinError = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Richiedi il focus esplicitamente dopo il build (necessario su Linux)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_isCreating) return;

    // Gestisci solo nelle pagine PIN (2 e 3)
    if (_currentPage != 2 && _currentPage != 3) return;

    final key = event.logicalKey;
    String? digit;

    // Numeri 0-9 dalla tastiera principale e numpad
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      digit = '0';
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      digit = '1';
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      digit = '2';
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      digit = '3';
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      digit = '4';
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      digit = '5';
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      digit = '6';
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      digit = '7';
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      digit = '8';
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      digit = '9';
    }

    if (_currentPage == 2) {
      // Pagina creazione PIN
      if (digit != null && _pin.length < UserService.maxPinLength) {
        setState(() {
          _pin += digit!;
        });
      } else if (key == LogicalKeyboardKey.backspace && _pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
        });
      } else if ((key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) &&
          _pin.length >= UserService.minPinLength) {
        _goToConfirmPinPage();
      }
    } else if (_currentPage == 3) {
      // Pagina conferma PIN
      if (digit != null && _confirmPin.length < _pin.length) {
        setState(() {
          _confirmPin += digit!;
          _pinError = false;
        });
        // Auto-verifica quando raggiunge la lunghezza
        if (_confirmPin.length == _pin.length) {
          _verifyAndCreate();
        }
      } else if (key == LogicalKeyboardKey.backspace && _confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          _pinError = false;
        });
      } else if ((key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) &&
          _confirmPin.length == _pin.length) {
        _verifyAndCreate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OlderOSTheme.background,
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Column(
          children: [
            // Header
            _buildHeader(),

            // Indicatore di progresso
            _buildProgressIndicator(),

            // Contenuto pagine
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildNamePage(),
                  _buildAvatarPage(),
                  _buildPinPage(),
                  _buildConfirmPinPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0 || (!widget.isFirstUser && widget.onCancel != null))
            IconButton(
              onPressed: _currentPage > 0 ? _goBack : widget.onCancel,
              icon: const Icon(Icons.arrow_back),
              iconSize: 32,
              tooltip: 'Indietro',
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              widget.isFirstUser ? 'Benvenuto!' : 'Nuovo Utente',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: OlderOSTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentPage;
          final isCurrent = index == _currentPage;

          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? OlderOSTheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Pagina 1: Nome
  Widget _buildNamePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 32),

          const Text(
            'Come ti chiami?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: OlderOSTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Scrivi il tuo nome come vuoi che appaia',
            style: TextStyle(
              fontSize: 22,
              color: OlderOSTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Campo nome
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 28),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Es: Mario',
                hintStyle: TextStyle(
                  fontSize: 28,
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 48),

          // Pulsante continua
          ElevatedButton(
            onPressed: _nameController.text.trim().isNotEmpty ? _goToAvatarPage : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 64),
              textStyle: const TextStyle(fontSize: 24),
            ),
            child: const Text('CONTINUA'),
          ),
        ],
      ),
    );
  }

  // Pagina 2: Avatar
  Widget _buildAvatarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 16),

          const Text(
            'Scegli un colore',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: OlderOSTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Questo sara\' il colore del tuo profilo',
            style: TextStyle(
              fontSize: 22,
              color: OlderOSTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Anteprima avatar
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: UserAvatarColors.getColor(_avatarColorIndex),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: UserAvatarColors.getColor(_avatarColorIndex)
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Selettore colori
          AvatarColorPicker(
            selectedIndex: _avatarColorIndex,
            onColorSelected: (index) {
              setState(() {
                _avatarColorIndex = index;
              });
            },
            itemSize: 64,
          ),

          const SizedBox(height: 48),

          // Pulsante continua
          ElevatedButton(
            onPressed: _goToPinPage,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 64),
              textStyle: const TextStyle(fontSize: 24),
            ),
            child: const Text('CONTINUA'),
          ),
        ],
      ),
    );
  }

  // Pagina 3: Creazione PIN
  Widget _buildPinPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Crea un PIN',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: OlderOSTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Scegli 4-6 numeri facili da ricordare',
            style: TextStyle(
              fontSize: 22,
              color: OlderOSTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Display PIN
          PinDisplay(
            length: _pin.length,
            maxLength: UserService.maxPinLength,
            dotSize: 24,
          ),

          const SizedBox(height: 32),

          // Tastierino
          PinKeypad(
            onDigitPressed: (digit) {
              if (_pin.length < UserService.maxPinLength) {
                setState(() {
                  _pin += digit;
                });
              }
            },
            onDelete: () {
              if (_pin.isNotEmpty) {
                setState(() {
                  _pin = _pin.substring(0, _pin.length - 1);
                });
              }
            },
            onConfirm: _pin.length >= UserService.minPinLength ? _goToConfirmPinPage : null,
            buttonSize: 72,
          ),
        ],
      ),
    );
  }

  // Pagina 4: Conferma PIN
  Widget _buildConfirmPinPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Conferma il PIN',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: OlderOSTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          const Text(
            'Inserisci di nuovo lo stesso PIN',
            style: TextStyle(
              fontSize: 22,
              color: OlderOSTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Display PIN con errore
          ShakeAnimation(
            shake: _pinError,
            onShakeComplete: () {
              setState(() {
                _pinError = false;
                _confirmPin = '';
              });
            },
            child: PinDisplay(
              length: _confirmPin.length,
              maxLength: _pin.length,
              hasError: _pinError,
              dotSize: 24,
            ),
          ),

          if (_pinError) ...[
            const SizedBox(height: 16),
            const Text(
              'I PIN non corrispondono. Riprova.',
              style: TextStyle(
                fontSize: 18,
                color: OlderOSTheme.danger,
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Tastierino
          PinKeypad(
            onDigitPressed: (digit) {
              if (_confirmPin.length < _pin.length) {
                setState(() {
                  _confirmPin += digit;
                  _pinError = false;
                });

                // Auto-verifica quando raggiunge la lunghezza
                if (_confirmPin.length == _pin.length) {
                  _verifyAndCreate();
                }
              }
            },
            onDelete: () {
              if (_confirmPin.isNotEmpty) {
                setState(() {
                  _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
                  _pinError = false;
                });
              }
            },
            onConfirm: _confirmPin.length == _pin.length ? _verifyAndCreate : null,
            buttonSize: 72,
            enabled: !_isCreating,
          ),

          if (_isCreating) ...[
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Creazione profilo...',
              style: TextStyle(
                fontSize: 20,
                color: OlderOSTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getInitials() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Reset stato pagina corrente
      if (_currentPage == 3) {
        setState(() {
          _confirmPin = '';
          _pinError = false;
        });
      } else if (_currentPage == 2) {
        setState(() {
          _pin = '';
        });
      }
    }
  }

  void _goToAvatarPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPinPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToConfirmPinPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _verifyAndCreate() async {
    if (_confirmPin != _pin) {
      setState(() {
        _pinError = true;
      });
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Crea l'utente
      final user = await _userService.createUser(
        name: _nameController.text.trim(),
        pin: _pin,
        avatarColorIndex: _avatarColorIndex,
      );

      // Se e' il primo utente, migra i dati esistenti
      if (widget.isFirstUser && await _userService.hasLegacyData()) {
        await _userService.migrateExistingData(user.id);
      }

      // Effettua login automatico se richiesto
      if (widget.autoLogin) {
        await _userService.login(user.id, _pin);
      }

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: OlderOSTheme.danger,
          ),
        );
      }
    }
  }
}
