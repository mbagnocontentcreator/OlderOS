import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _equation = '';
  double? _firstNumber;
  String? _operation;
  bool _shouldResetDisplay = false;

  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Richiedi il focus all'avvio per ricevere input da tastiera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    // Numeri 0-9 (riga superiore e numpad)
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
    }
    // Operatori
    else if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      _onOperationPressed('+');
    } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      _onOperationPressed('-');
    } else if (key == LogicalKeyboardKey.asterisk || key == LogicalKeyboardKey.numpadMultiply) {
      _onOperationPressed('×');
    } else if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.numpadDivide) {
      _onOperationPressed('÷');
    }
    // Uguale (Enter, =)
    else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.equal) {
      _onEqualsPressed();
    }
    // Decimale (virgola o punto)
    else if (key == LogicalKeyboardKey.comma || key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) {
      _onDecimalPressed();
    }
    // Cancella (Backspace)
    else if (key == LogicalKeyboardKey.backspace) {
      _onBackspacePressed();
    }
    // Clear (C, Escape, Delete)
    else if (key == LogicalKeyboardKey.keyC || key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.delete) {
      _onClearPressed();
    }
    // Percentuale (% - richiede Shift+5 su tastiere italiane)
    else if (key == LogicalKeyboardKey.percent) {
      _onPercentPressed();
    }
  }

  void _onDigitPressed(String digit) {
    setState(() {
      if (_shouldResetDisplay || _display == '0') {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        if (_display.length < 12) {
          _display += digit;
        }
      }
    });
  }

  void _onDecimalPressed() {
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0,';
        _shouldResetDisplay = false;
      } else if (!_display.contains(',')) {
        _display += ',';
      }
    });
  }

  void _onOperationPressed(String operation) {
    setState(() {
      _firstNumber = _parseDisplay();
      _operation = operation;
      _equation = '$_display $operation';
      _shouldResetDisplay = true;
    });
  }

  void _onEqualsPressed() {
    if (_firstNumber == null || _operation == null) return;

    final secondNumber = _parseDisplay();
    double result = 0;

    switch (_operation) {
      case '+':
        result = _firstNumber! + secondNumber;
        break;
      case '-':
        result = _firstNumber! - secondNumber;
        break;
      case '×':
        result = _firstNumber! * secondNumber;
        break;
      case '÷':
        if (secondNumber == 0) {
          setState(() {
            _display = 'Errore';
            _equation = '';
            _firstNumber = null;
            _operation = null;
            _shouldResetDisplay = true;
          });
          return;
        }
        result = _firstNumber! / secondNumber;
        break;
    }

    setState(() {
      _equation = '';
      _display = _formatResult(result);
      _firstNumber = null;
      _operation = null;
      _shouldResetDisplay = true;
    });
  }

  void _onClearPressed() {
    setState(() {
      _display = '0';
      _equation = '';
      _firstNumber = null;
      _operation = null;
      _shouldResetDisplay = false;
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onPercentPressed() {
    final number = _parseDisplay();
    setState(() {
      _display = _formatResult(number / 100);
      _shouldResetDisplay = true;
    });
  }

  void _onSquareRootPressed() {
    final number = _parseDisplay();
    if (number < 0) {
      setState(() {
        _display = 'Errore';
        _shouldResetDisplay = true;
      });
      return;
    }
    setState(() {
      _display = _formatResult(sqrt(number));
      _shouldResetDisplay = true;
    });
  }

  double _parseDisplay() {
    return double.tryParse(_display.replaceAll(',', '.')) ?? 0;
  }

  String _formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    }
    String formatted = result.toStringAsFixed(8);
    // Rimuovi zeri finali
    while (formatted.contains('.') && (formatted.endsWith('0') || formatted.endsWith('.'))) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    // Limita lunghezza
    if (formatted.length > 12) {
      formatted = result.toStringAsExponential(4);
    }
    return formatted.replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopBar(
                title: 'CALCOLA',
                onGoHome: () => Navigator.of(context).pop(),
              ),

              Expanded(
              child: Padding(
                padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
                child: Column(
                  children: [
                    // Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: OlderOSTheme.cardBackground,
                        borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Equazione in corso
                          if (_equation.isNotEmpty)
                            Text(
                              _equation,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: OlderOSTheme.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Risultato principale
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _display,
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: OlderOSTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tastierino
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: OlderOSTheme.cardBackground,
                          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Riga 1: C, ←, %, ÷
                            Expanded(
                              child: Row(
                                children: [
                                  _CalcButton(
                                    label: 'C',
                                    color: OlderOSTheme.danger,
                                    textColor: Colors.white,
                                    onTap: _onClearPressed,
                                  ),
                                  _CalcButton(
                                    icon: Icons.backspace_outlined,
                                    color: OlderOSTheme.warning,
                                    textColor: Colors.white,
                                    onTap: _onBackspacePressed,
                                  ),
                                  _CalcButton(
                                    label: '%',
                                    color: OlderOSTheme.textSecondary.withAlpha(50),
                                    onTap: _onPercentPressed,
                                  ),
                                  _CalcButton(
                                    label: '÷',
                                    color: OlderOSTheme.primary,
                                    textColor: Colors.white,
                                    onTap: () => _onOperationPressed('÷'),
                                  ),
                                ],
                              ),
                            ),
                            // Riga 2: 7, 8, 9, ×
                            Expanded(
                              child: Row(
                                children: [
                                  _CalcButton(label: '7', onTap: () => _onDigitPressed('7')),
                                  _CalcButton(label: '8', onTap: () => _onDigitPressed('8')),
                                  _CalcButton(label: '9', onTap: () => _onDigitPressed('9')),
                                  _CalcButton(
                                    label: '×',
                                    color: OlderOSTheme.primary,
                                    textColor: Colors.white,
                                    onTap: () => _onOperationPressed('×'),
                                  ),
                                ],
                              ),
                            ),
                            // Riga 3: 4, 5, 6, -
                            Expanded(
                              child: Row(
                                children: [
                                  _CalcButton(label: '4', onTap: () => _onDigitPressed('4')),
                                  _CalcButton(label: '5', onTap: () => _onDigitPressed('5')),
                                  _CalcButton(label: '6', onTap: () => _onDigitPressed('6')),
                                  _CalcButton(
                                    label: '-',
                                    color: OlderOSTheme.primary,
                                    textColor: Colors.white,
                                    onTap: () => _onOperationPressed('-'),
                                  ),
                                ],
                              ),
                            ),
                            // Riga 4: 1, 2, 3, +
                            Expanded(
                              child: Row(
                                children: [
                                  _CalcButton(label: '1', onTap: () => _onDigitPressed('1')),
                                  _CalcButton(label: '2', onTap: () => _onDigitPressed('2')),
                                  _CalcButton(label: '3', onTap: () => _onDigitPressed('3')),
                                  _CalcButton(
                                    label: '+',
                                    color: OlderOSTheme.primary,
                                    textColor: Colors.white,
                                    onTap: () => _onOperationPressed('+'),
                                  ),
                                ],
                              ),
                            ),
                            // Riga 5: √, 0, ,, =
                            Expanded(
                              child: Row(
                                children: [
                                  _CalcButton(
                                    label: '√',
                                    color: OlderOSTheme.textSecondary.withAlpha(50),
                                    onTap: _onSquareRootPressed,
                                  ),
                                  _CalcButton(label: '0', onTap: () => _onDigitPressed('0')),
                                  _CalcButton(label: ',', onTap: _onDecimalPressed),
                                  _CalcButton(
                                    label: '=',
                                    color: OlderOSTheme.success,
                                    textColor: Colors.white,
                                    onTap: _onEqualsPressed,
                                  ),
                                ],
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
      ),
      ),
    );
  }
}

class _CalcButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _CalcButton({
    this.label,
    this.icon,
    this.color = const Color(0xFFF5F5F5),
    this.textColor = OlderOSTheme.textPrimary,
    required this.onTap,
  });

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: _isPressed ? widget.color.withAlpha(200) : widget.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isPressed
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: widget.icon != null
                  ? Icon(
                      widget.icon,
                      size: 36,
                      color: widget.textColor,
                    )
                  : Text(
                      widget.label ?? '',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
