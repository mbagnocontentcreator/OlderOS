import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/pin_keypad.dart';
import '../theme/olderos_theme.dart';

/// Schermata per l'inserimento del PIN utente
class PinEntryScreen extends StatefulWidget {
  final User user;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const PinEntryScreen({
    super.key,
    required this.user,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final UserService _userService = UserService();
  final FocusNode _focusNode = FocusNode();
  String _enteredPin = '';
  bool _hasError = false;
  bool _isVerifying = false;
  bool _shake = false;

  @override
  void initState() {
    super.initState();
    // Richiedi il focus esplicitamente dopo il build (necessario su Linux)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_isVerifying || _userService.isLockedOut) return;

    final key = event.logicalKey;

    // Numeri 0-9 dalla tastiera principale
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _onDigitPressed('0');
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _onDigitPressed('1');
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      _onDigitPressed('2');
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      _onDigitPressed('3');
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      _onDigitPressed('4');
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      _onDigitPressed('5');
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      _onDigitPressed('6');
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      _onDigitPressed('7');
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      _onDigitPressed('8');
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      _onDigitPressed('9');
    } else if (key == LogicalKeyboardKey.backspace) {
      _onDelete();
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_enteredPin.length >= UserService.minPinLength) {
        _verifyPin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLockedOut = _userService.isLockedOut;

    return Scaffold(
      backgroundColor: OlderOSTheme.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
        child: Column(
          children: [
            // Header con pulsante indietro
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 32,
                    tooltip: 'Indietro',
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar utente
                      UserAvatar(
                        user: widget.user,
                        size: 120,
                        showName: true,
                      ),

                      const SizedBox(height: 48),

                      // Messaggio
                      Text(
                        isLockedOut
                            ? 'Accesso bloccato'
                            : 'Inserisci il tuo PIN',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: OlderOSTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Display PIN o messaggio blocco
                      if (isLockedOut)
                        _buildLockoutMessage()
                      else ...[
                        // Display pallini PIN
                        ShakeAnimation(
                          shake: _shake,
                          onShakeComplete: () {
                            setState(() {
                              _shake = false;
                              _enteredPin = '';
                              _hasError = false;
                            });
                          },
                          child: PinDisplay(
                            length: _enteredPin.length,
                            maxLength: UserService.maxPinLength,
                            hasError: _hasError,
                            dotSize: 24,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Messaggio errore o tentativi
                        if (_hasError)
                          Text(
                            'PIN errato. ${_userService.remainingAttempts} tentativi rimanenti',
                            style: const TextStyle(
                              fontSize: 18,
                              color: OlderOSTheme.danger,
                            ),
                          )
                        else
                          const SizedBox(height: 22), // Spazio placeholder

                        const SizedBox(height: 32),

                        // Tastierino
                        PinKeypad(
                          onDigitPressed: _onDigitPressed,
                          onDelete: _onDelete,
                          onConfirm: _enteredPin.length >= UserService.minPinLength
                              ? _verifyPin
                              : null,
                          buttonSize: 80,
                          enabled: !_isVerifying,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLockoutMessage() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final remaining = _userService.lockoutRemaining;
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;

        if (remaining.inSeconds <= 0) {
          // Blocco terminato, ricarica lo stato
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {});
          });
        }

        return Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: OlderOSTheme.danger.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Troppi tentativi errati',
              style: TextStyle(
                fontSize: 22,
                color: OlderOSTheme.danger.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Riprova tra ${minutes > 0 ? '$minutes min ' : ''}${seconds} sec',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: OlderOSTheme.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= UserService.maxPinLength) return;

    setState(() {
      _enteredPin += digit;
      _hasError = false;
    });

    // Auto-verifica se raggiunto maxPinLength
    if (_enteredPin.length == UserService.maxPinLength) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    if (_isVerifying || _enteredPin.length < UserService.minPinLength) return;

    setState(() {
      _isVerifying = true;
    });

    final success = await _userService.login(widget.user.id, _enteredPin);

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });

      if (success) {
        widget.onSuccess();
      } else {
        setState(() {
          _hasError = true;
          _shake = true;
        });
      }
    }
  }
}
