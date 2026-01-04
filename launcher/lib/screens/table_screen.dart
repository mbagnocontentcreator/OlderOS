import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../widgets/big_button.dart';

class CellPosition {
  final int row;
  final int col;

  const CellPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellPosition && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class CellRange {
  final CellPosition start;
  final CellPosition end;

  const CellRange(this.start, this.end);

  int get minRow => start.row < end.row ? start.row : end.row;
  int get maxRow => start.row > end.row ? start.row : end.row;
  int get minCol => start.col < end.col ? start.col : end.col;
  int get maxCol => start.col > end.col ? start.col : end.col;

  bool contains(int row, int col) {
    return row >= minRow && row <= maxRow && col >= minCol && col <= maxCol;
  }
}

enum CellBorder { none, all, outer, top, bottom, left, right }

class CellData {
  String content;
  bool isBold;
  Color? backgroundColor;
  TextAlign textAlign;
  Set<CellBorder> borders;

  CellData({
    this.content = '',
    this.isBold = false,
    this.backgroundColor,
    this.textAlign = TextAlign.left,
    Set<CellBorder>? borders,
  }) : borders = borders ?? {};

  double? get numericValue {
    if (content.isEmpty) return null;
    final cleaned = content.replaceAll(',', '.').replaceAll(' ', '');
    return double.tryParse(cleaned);
  }

  bool get isNumeric => numericValue != null;

  bool hasBorder(CellBorder border) => borders.contains(border) || borders.contains(CellBorder.all);
}

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  static const double columnWidth = 120.0;
  static const double rowHeight = 50.0;

  int _numRows = 15;
  int _numCols = 6;

  late List<List<CellData>> _cells;
  late List<List<TextEditingController>> _controllers;
  late List<List<FocusNode>> _focusNodes;

  CellRange? _selectionRange;
  CellPosition? _anchorCell; // Cella di ancoraggio per selezione
  CellPosition? _activeCell; // Cella attiva corrente
  bool _isEditing = false; // true = modifica testo esistente, false = sostituisci

  final FocusNode _keyboardFocusNode = FocusNode();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // Genera etichetta colonna (A, B, ... Z, AA, AB, ...)
  String _getColumnLabel(int index) {
    String label = '';
    int n = index;
    while (n >= 0) {
      label = String.fromCharCode(65 + (n % 26)) + label;
      n = (n ~/ 26) - 1;
    }
    return label;
  }

  @override
  void initState() {
    super.initState();
    _initializeGrid(_numRows, _numCols);
  }

  void _initializeGrid(int numRows, int numCols) {
    _cells = List.generate(
      numRows,
      (row) => List.generate(numCols, (col) => CellData()),
    );
    _controllers = List.generate(
      numRows,
      (row) => List.generate(numCols, (col) => TextEditingController()),
    );
    _focusNodes = List.generate(
      numRows,
      (row) => List.generate(numCols, (col) => FocusNode()),
    );

    for (int row = 0; row < numRows; row++) {
      for (int col = 0; col < numCols; col++) {
        _setupCellListeners(row, col);
      }
    }
  }

  void _setupCellListeners(int row, int col) {
    _controllers[row][col].addListener(() {
      _cells[row][col].content = _controllers[row][col].text;
    });
    _focusNodes[row][col].addListener(() {
      if (!_focusNodes[row][col].hasFocus && _isEditing) {
        if (_activeCell?.row == row && _activeCell?.col == col) {
          setState(() {
            _isEditing = false;
          });
        }
      }
    });
  }

  void _addRow() {
    setState(() {
      _numRows++;
      // Aggiungi nuova riga alle strutture dati
      _cells.add(List.generate(_numCols, (col) => CellData()));
      _controllers.add(List.generate(_numCols, (col) => TextEditingController()));
      _focusNodes.add(List.generate(_numCols, (col) => FocusNode()));
      // Setup listeners per la nuova riga
      for (int col = 0; col < _numCols; col++) {
        _setupCellListeners(_numRows - 1, col);
      }
    });
  }

  void _addColumn() {
    setState(() {
      _numCols++;
      // Aggiungi nuova colonna a ogni riga
      for (int row = 0; row < _numRows; row++) {
        _cells[row].add(CellData());
        _controllers[row].add(TextEditingController());
        _focusNodes[row].add(FocusNode());
        _setupCellListeners(row, _numCols - 1);
      }
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    for (var row in _controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in _focusNodes) {
      for (var focusNode in row) {
        focusNode.dispose();
      }
    }
    super.dispose();
  }

  // Singolo clic: seleziona cella
  void _onCellTap(int row, int col) {
    setState(() {
      _activeCell = CellPosition(row, col);
      _anchorCell = CellPosition(row, col);
      _selectionRange = CellRange(CellPosition(row, col), CellPosition(row, col));
      _isEditing = false;
    });
    _keyboardFocusNode.requestFocus();
  }

  // Doppio clic: entra in modalità modifica
  void _onCellDoubleTap(int row, int col) {
    setState(() {
      _activeCell = CellPosition(row, col);
      _anchorCell = CellPosition(row, col);
      _selectionRange = CellRange(CellPosition(row, col), CellPosition(row, col));
      _isEditing = true;
    });
    _focusNodes[row][col].requestFocus();
  }

  void _selectColumn(int col) {
    setState(() {
      _selectionRange = CellRange(CellPosition(0, col), CellPosition(_numRows - 1, col));
      _activeCell = CellPosition(0, col);
      _anchorCell = CellPosition(0, col);
      _isEditing = false;
    });
    _keyboardFocusNode.requestFocus();
  }

  void _selectRow(int row) {
    setState(() {
      _selectionRange = CellRange(CellPosition(row, 0), CellPosition(row, _numCols - 1));
      _activeCell = CellPosition(row, 0);
      _anchorCell = CellPosition(row, 0);
      _isEditing = false;
    });
    _keyboardFocusNode.requestFocus();
  }

  bool _isCellSelected(int row, int col) {
    if (_selectionRange == null) return false;
    return _selectionRange!.contains(row, col);
  }

  bool _isCellActive(int row, int col) {
    return _activeCell?.row == row && _activeCell?.col == col;
  }

  String _getRangeLabel() {
    if (_selectionRange == null) return '';
    final startLabel = '${_getColumnLabel(_selectionRange!.minCol)}${_selectionRange!.minRow + 1}';
    final endLabel = '${_getColumnLabel(_selectionRange!.maxCol)}${_selectionRange!.maxRow + 1}';
    if (startLabel == endLabel) return startLabel;
    return '$startLabel:$endLabel';
  }

  // Gestione tastiera
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Se stiamo editando, lascia gestire al TextField
    if (_isEditing) {
      // ESC esce dalla modifica
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _isEditing = false;
        });
        _keyboardFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      // Enter conferma e va alla cella sotto
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        setState(() {
          _isEditing = false;
        });
        _moveActiveCell(1, 0, extendSelection: false);
        return KeyEventResult.handled;
      }
      // Tab va alla cella a destra
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        setState(() {
          _isEditing = false;
        });
        _moveActiveCell(0, isShiftPressed ? -1 : 1, extendSelection: false);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Navigazione con frecce
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveActiveCell(-1, 0, extendSelection: isShiftPressed);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveActiveCell(1, 0, extendSelection: isShiftPressed);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveActiveCell(0, -1, extendSelection: isShiftPressed);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveActiveCell(0, 1, extendSelection: isShiftPressed);
      return KeyEventResult.handled;
    }

    // Enter: vai alla cella sotto
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _moveActiveCell(1, 0, extendSelection: false);
      return KeyEventResult.handled;
    }

    // Tab: vai alla cella a destra (Shift+Tab: sinistra)
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _moveActiveCell(0, isShiftPressed ? -1 : 1, extendSelection: false);
      return KeyEventResult.handled;
    }

    // Delete/Backspace: cancella contenuto celle selezionate
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      _clearSelection();
      return KeyEventResult.handled;
    }

    // F2: entra in modalità modifica
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      if (_activeCell != null) {
        setState(() {
          _isEditing = true;
        });
        _focusNodes[_activeCell!.row][_activeCell!.col].requestFocus();
      }
      return KeyEventResult.handled;
    }

    // ESC: deseleziona
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _selectionRange = null;
        _activeCell = null;
        _anchorCell = null;
      });
      return KeyEventResult.handled;
    }

    // Qualsiasi altro carattere: inizia a scrivere (sostituisce contenuto)
    if (event.character != null &&
        event.character!.isNotEmpty &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      if (_activeCell != null) {
        final char = event.character!;
        // Solo caratteri stampabili
        if (char.codeUnitAt(0) >= 32) {
          _controllers[_activeCell!.row][_activeCell!.col].text = char;
          _controllers[_activeCell!.row][_activeCell!.col].selection =
              TextSelection.collapsed(offset: char.length);
          setState(() {
            _isEditing = true;
            _selectionRange = CellRange(_activeCell!, _activeCell!);
          });
          _focusNodes[_activeCell!.row][_activeCell!.col].requestFocus();
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  void _moveActiveCell(int deltaRow, int deltaCol, {required bool extendSelection}) {
    if (_activeCell == null) {
      setState(() {
        _activeCell = const CellPosition(0, 0);
        _anchorCell = const CellPosition(0, 0);
        _selectionRange = const CellRange(CellPosition(0, 0), CellPosition(0, 0));
      });
      return;
    }

    final newRow = (_activeCell!.row + deltaRow).clamp(0, _numRows - 1);
    final newCol = (_activeCell!.col + deltaCol).clamp(0, _numCols - 1);

    setState(() {
      _activeCell = CellPosition(newRow, newCol);
      if (extendSelection && _anchorCell != null) {
        _selectionRange = CellRange(_anchorCell!, _activeCell!);
      } else {
        _anchorCell = _activeCell;
        _selectionRange = CellRange(_activeCell!, _activeCell!);
      }
    });
  }

  void _toggleBold() {
    if (_selectionRange == null) return;
    // Controlla se la prima cella è bold, poi inverte tutto
    final firstIsBold = _cells[_selectionRange!.minRow][_selectionRange!.minCol].isBold;
    setState(() {
      for (int row = _selectionRange!.minRow; row <= _selectionRange!.maxRow; row++) {
        for (int col = _selectionRange!.minCol; col <= _selectionRange!.maxCol; col++) {
          _cells[row][col].isBold = !firstIsBold;
        }
      }
    });
  }

  void _setAlignment(TextAlign align) {
    if (_selectionRange == null) return;
    setState(() {
      for (int row = _selectionRange!.minRow; row <= _selectionRange!.maxRow; row++) {
        for (int col = _selectionRange!.minCol; col <= _selectionRange!.maxCol; col++) {
          _cells[row][col].textAlign = align;
        }
      }
    });
  }

  void _setBackgroundColor(Color? color) {
    if (_selectionRange == null) return;
    setState(() {
      for (int row = _selectionRange!.minRow; row <= _selectionRange!.maxRow; row++) {
        for (int col = _selectionRange!.minCol; col <= _selectionRange!.maxCol; col++) {
          _cells[row][col].backgroundColor = color;
        }
      }
    });
  }

  void _setBorders(CellBorder borderType) {
    if (_selectionRange == null) return;
    setState(() {
      for (int row = _selectionRange!.minRow; row <= _selectionRange!.maxRow; row++) {
        for (int col = _selectionRange!.minCol; col <= _selectionRange!.maxCol; col++) {
          if (borderType == CellBorder.none) {
            _cells[row][col].borders.clear();
          } else if (borderType == CellBorder.all) {
            _cells[row][col].borders.clear();
            _cells[row][col].borders.add(CellBorder.all);
          } else if (borderType == CellBorder.outer) {
            _cells[row][col].borders.clear();
            // Top row
            if (row == _selectionRange!.minRow) {
              _cells[row][col].borders.add(CellBorder.top);
            }
            // Bottom row
            if (row == _selectionRange!.maxRow) {
              _cells[row][col].borders.add(CellBorder.bottom);
            }
            // Left column
            if (col == _selectionRange!.minCol) {
              _cells[row][col].borders.add(CellBorder.left);
            }
            // Right column
            if (col == _selectionRange!.maxCol) {
              _cells[row][col].borders.add(CellBorder.right);
            }
          }
        }
      }
    });
  }

  void _calculateSum() {
    if (_selectionRange == null) {
      _showMessage('Seleziona prima delle celle');
      return;
    }

    double sum = 0;
    int count = 0;

    for (int row = _selectionRange!.minRow; row <= _selectionRange!.maxRow; row++) {
      for (int col = _selectionRange!.minCol; col <= _selectionRange!.maxCol; col++) {
        final value = _cells[row][col].numericValue;
        if (value != null) {
          sum += value;
          count++;
        }
      }
    }

    _showResultDialog(
      'Somma (${_getRangeLabel()})',
      count > 0 ? _formatNumber(sum) : 'Nessun numero',
    );
  }

  void _calculateAverage() {
    if (_selectionRange == null) {
      _showMessage('Seleziona prima delle celle');
      return;
    }

    double sum = 0;
    int count = 0;

    for (int row = _selectionRange!.minRow; row <= _selectionRange!.maxRow; row++) {
      for (int col = _selectionRange!.minCol; col <= _selectionRange!.maxCol; col++) {
        final value = _cells[row][col].numericValue;
        if (value != null) {
          sum += value;
          count++;
        }
      }
    }

    _showResultDialog(
      'Media (${_getRangeLabel()})',
      count > 0 ? _formatNumber(sum / count) : 'Nessun numero',
    );
  }

  void _clearSelection() {
    if (_selectionRange == null) return;
    setState(() {
      for (int row = _selectionRange!.minRow; row <= _selectionRange!.maxRow; row++) {
        for (int col = _selectionRange!.minCol; col <= _selectionRange!.maxCol; col++) {
          _controllers[row][col].clear();
          _cells[row][col].content = '';
        }
      }
    });
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 18)),
        backgroundColor: OlderOSTheme.tableColor,
      ),
    );
  }

  void _showResultDialog(String title, String result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: OlderOSTheme.tableColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            result,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: OlderOSTheme.tableColor,
              fontSize: 48,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: BigButton(
              label: 'OK',
              backgroundColor: OlderOSTheme.primary,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Focus(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          autofocus: true,
          child: Column(
            children: [
              TopBar(
                title: 'TABELLA',
                onGoHome: () => Navigator.of(context).pop(),
              ),

              // Toolbar formattazione
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: OlderOSTheme.cardBackground,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Info selezione
                      if (_selectionRange != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: OlderOSTheme.tableColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getRangeLabel(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: OlderOSTheme.tableColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),

                      // Pulsanti formattazione testo
                      _ToolButton(
                        icon: Icons.format_bold,
                        tooltip: 'Grassetto',
                        onTap: _toggleBold,
                      ),
                      _ToolButton(
                        icon: Icons.format_align_left,
                        tooltip: 'Allinea a sinistra',
                        onTap: () => _setAlignment(TextAlign.left),
                      ),
                      _ToolButton(
                        icon: Icons.format_align_center,
                        tooltip: 'Centra',
                        onTap: () => _setAlignment(TextAlign.center),
                      ),
                      _ToolButton(
                        icon: Icons.format_align_right,
                        tooltip: 'Allinea a destra',
                        onTap: () => _setAlignment(TextAlign.right),
                      ),

                      const SizedBox(width: 8),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      const SizedBox(width: 8),

                      // Bordi
                      _ToolButton(
                        icon: Icons.border_all,
                        tooltip: 'Tutti i bordi',
                        onTap: () => _setBorders(CellBorder.all),
                      ),
                      _ToolButton(
                        icon: Icons.border_outer,
                        tooltip: 'Bordo esterno',
                        onTap: () => _setBorders(CellBorder.outer),
                      ),
                      _ToolButton(
                        icon: Icons.border_clear,
                        tooltip: 'Rimuovi bordi',
                        onTap: () => _setBorders(CellBorder.none),
                      ),

                      const SizedBox(width: 8),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      const SizedBox(width: 8),

                      // Colori sfondo
                      _ColorButton(
                        color: Colors.yellow.shade100,
                        onTap: () => _setBackgroundColor(Colors.yellow.shade100),
                      ),
                      _ColorButton(
                        color: Colors.green.shade100,
                        onTap: () => _setBackgroundColor(Colors.green.shade100),
                      ),
                      _ColorButton(
                        color: Colors.blue.shade100,
                        onTap: () => _setBackgroundColor(Colors.blue.shade100),
                      ),
                      _ColorButton(
                        color: Colors.red.shade100,
                        onTap: () => _setBackgroundColor(Colors.red.shade100),
                      ),
                      _ToolButton(
                        icon: Icons.format_color_reset,
                        tooltip: 'Rimuovi colore',
                        onTap: () => _setBackgroundColor(null),
                      ),

                      const SizedBox(width: 16),

                      // Operazioni
                      _ActionButton(
                        label: 'SOMMA',
                        icon: Icons.functions,
                        onTap: _calculateSum,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'MEDIA',
                        icon: Icons.calculate,
                        onTap: _calculateAverage,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'CANCELLA',
                        icon: Icons.delete_outline,
                        color: OlderOSTheme.danger,
                        onTap: _clearSelection,
                      ),

                      const SizedBox(width: 8),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      const SizedBox(width: 8),

                      // Aggiungi righe/colonne
                      _ActionButton(
                        label: '+ RIGA',
                        icon: Icons.add,
                        color: OlderOSTheme.success,
                        onTap: _addRow,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: '+ COLONNA',
                        icon: Icons.add,
                        color: OlderOSTheme.success,
                        onTap: _addColumn,
                      ),
                    ],
                  ),
                ),
              ),

              // Tabella
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: Column(
                              children: [
                                // Header colonne
                                Row(
                                  children: [
                                    // Angolo
                                    Container(
                                      width: 50,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: OlderOSTheme.tableColor.withAlpha(40),
                                        border: Border.all(color: OlderOSTheme.tableColor.withAlpha(100)),
                                      ),
                                    ),
                                    ...List.generate(_numCols, (col) => GestureDetector(
                                      onTap: () => _selectColumn(col),
                                      child: Container(
                                        width: columnWidth,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: _selectionRange != null &&
                                                 _selectionRange!.minCol <= col &&
                                                 _selectionRange!.maxCol >= col
                                              ? OlderOSTheme.tableColor.withAlpha(60)
                                              : OlderOSTheme.tableColor.withAlpha(40),
                                          border: Border.all(color: OlderOSTheme.tableColor.withAlpha(100)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getColumnLabel(col),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: OlderOSTheme.tableColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )),
                                  ],
                                ),

                                // Righe dati
                                ...List.generate(_numRows, (row) => Row(
                                  children: [
                                    // Numero riga
                                    GestureDetector(
                                      onTap: () => _selectRow(row),
                                      child: Container(
                                        width: 50,
                                        height: rowHeight,
                                        decoration: BoxDecoration(
                                          color: _selectionRange != null &&
                                                 _selectionRange!.minRow <= row &&
                                                 _selectionRange!.maxRow >= row
                                              ? OlderOSTheme.tableColor.withAlpha(60)
                                              : OlderOSTheme.tableColor.withAlpha(40),
                                          border: Border.all(color: OlderOSTheme.tableColor.withAlpha(100)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${row + 1}',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: OlderOSTheme.tableColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Celle
                                    ...List.generate(_numCols, (col) => _TableCell(
                                      cellData: _cells[row][col],
                                      controller: _controllers[row][col],
                                      focusNode: _focusNodes[row][col],
                                      isSelected: _isCellSelected(row, col),
                                      isActive: _isCellActive(row, col),
                                      isEditing: _isEditing && _isCellActive(row, col),
                                      width: columnWidth,
                                      height: rowHeight,
                                      onTap: () => _onCellTap(row, col),
                                      onDoubleTap: () => _onCellDoubleTap(row, col),
                                    )),
                                  ],
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Suggerimento
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Clic = seleziona • 2x clic = modifica • Frecce = naviga • Shift+Frecce = estendi selezione • Digita = scrivi',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final CellData cellData;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSelected;
  final bool isActive;
  final bool isEditing;
  final double width;
  final double height;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _TableCell({
    required this.cellData,
    required this.controller,
    required this.focusNode,
    required this.isSelected,
    required this.isActive,
    required this.isEditing,
    required this.width,
    required this.height,
    required this.onTap,
    required this.onDoubleTap,
  });

  BorderSide _getBorderSide(bool hasBorder) {
    return hasBorder
        ? const BorderSide(color: Colors.black, width: 2)
        : BorderSide(color: Colors.grey.shade300, width: 1);
  }

  @override
  Widget build(BuildContext context) {
    final hasBorders = cellData.borders.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cellData.backgroundColor ??
              (isActive
                  ? Colors.white
                  : isSelected
                      ? OlderOSTheme.tableColor.withAlpha(30)
                      : Colors.white),
          border: isActive
              ? Border.all(color: OlderOSTheme.tableColor, width: 3)
              : hasBorders
                  ? Border(
                      top: _getBorderSide(cellData.hasBorder(CellBorder.top)),
                      bottom: _getBorderSide(cellData.hasBorder(CellBorder.bottom)),
                      left: _getBorderSide(cellData.hasBorder(CellBorder.left)),
                      right: _getBorderSide(cellData.hasBorder(CellBorder.right)),
                    )
                  : Border.all(
                      color: isSelected
                          ? OlderOSTheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
        ),
        child: isEditing
            ? TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: cellData.textAlign,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: cellData.isBold ? FontWeight.bold : FontWeight.normal,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: cellData.textAlign == TextAlign.left
                      ? Alignment.centerLeft
                      : cellData.textAlign == TextAlign.right
                          ? Alignment.centerRight
                          : Alignment.center,
                  child: Text(
                    controller.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: cellData.isBold ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _isHovered ? OlderOSTheme.tableColor.withAlpha(30) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 24,
              color: _isHovered ? OlderOSTheme.tableColor : OlderOSTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade400),
        ),
      ),
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
    this.color = OlderOSTheme.tableColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? widget.color : widget.color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 20, color: _isHovered ? Colors.white : widget.color),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _isHovered ? Colors.white : widget.color,
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
