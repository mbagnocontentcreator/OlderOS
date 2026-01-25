import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import '../widgets/context_menu_region.dart';

class Document {
  String title;
  String content;
  DateTime lastModified;

  Document({
    required this.title,
    required this.content,
    required this.lastModified,
  });
}

class WriterScreen extends StatefulWidget {
  const WriterScreen({super.key});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  bool _showDocumentList = true;
  Document? _currentDocument;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();

  // Formattazione
  double _fontSize = 20;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  TextAlign _textAlign = TextAlign.left;

  // Documenti salvati (in memoria per MVP)
  final List<Document> _documents = [
    Document(
      title: 'Lista della spesa',
      content: 'Pane\nLatte\nUova\nFrutta',
      lastModified: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Document(
      title: 'Promemoria dottore',
      content: 'Appuntamento lunedi alle 10:00\nPortare tessera sanitaria',
      lastModified: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  bool _hasUnsavedChanges = false;

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _createNewDocument() {
    setState(() {
      _currentDocument = Document(
        title: 'Documento senza titolo',
        content: '',
        lastModified: DateTime.now(),
      );
      _titleController.text = _currentDocument!.title;
      _contentController.text = '';
      _showDocumentList = false;
      _hasUnsavedChanges = false;
    });
  }

  void _openDocument(Document doc) {
    setState(() {
      _currentDocument = doc;
      _titleController.text = doc.title;
      _contentController.text = doc.content;
      _showDocumentList = false;
      _hasUnsavedChanges = false;
    });
  }

  void _saveDocument() {
    if (_currentDocument != null) {
      _currentDocument!.title = _titleController.text.isEmpty
          ? 'Documento senza titolo'
          : _titleController.text;
      _currentDocument!.content = _contentController.text;
      _currentDocument!.lastModified = DateTime.now();

      if (!_documents.contains(_currentDocument)) {
        _documents.insert(0, _currentDocument!);
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      _showSaveConfirmation();
    }
  }

  void _showSaveConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'Documento salvato!',
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

  void _backToList() {
    if (_hasUnsavedChanges) {
      _showUnsavedChangesDialog();
    } else {
      setState(() {
        _showDocumentList = true;
        _currentDocument = null;
      });
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Text(
          'Salvare le modifiche?',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Hai delle modifiche non salvate.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showDocumentList = true;
                _currentDocument = null;
                _hasUnsavedChanges = false;
              });
            },
            child: Text(
              'Non salvare',
              style: TextStyle(
                fontSize: 20,
                color: OlderOSTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveDocument();
              setState(() {
                _showDocumentList = true;
                _currentDocument = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: OlderOSTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Salva',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _onContentChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'SCRIVERE',
            onGoHome: () {
              if (_hasUnsavedChanges && !_showDocumentList) {
                _showUnsavedChangesDialog();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          Expanded(
            child: _showDocumentList
                ? _buildDocumentList()
                : _buildEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    return Padding(
      padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pulsante nuovo documento
          Center(
            child: _BigActionButton(
              icon: Icons.add,
              label: 'NUOVO DOCUMENTO',
              color: OlderOSTheme.primary,
              onTap: _createNewDocument,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            'I miei documenti:',
            style: Theme.of(context).textTheme.displayMedium,
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _documents.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: _documents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _DocumentCard(
                        document: _documents[index],
                        onTap: () => _openDocument(_documents[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 100,
            color: OlderOSTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Nessun documento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: OlderOSTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clicca "Nuovo documento" per iniziare',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Barra strumenti
        _buildToolbar(),

        // Titolo documento
        Container(
          padding: const EdgeInsets.symmetric(horizontal: OlderOSTheme.marginScreen),
          child: TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.displayMedium,
            decoration: InputDecoration(
              hintText: 'Titolo del documento',
              hintStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: OlderOSTheme.textSecondary,
              ),
              border: InputBorder.none,
            ),
            onChanged: (_) => _onContentChanged(),
          ),
        ),

        const Divider(height: 1),

        // Area di scrittura
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(OlderOSTheme.marginScreen),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
                color: OlderOSTheme.textPrimary,
                height: 1.5,
              ),
              textAlign: _textAlign,
              decoration: InputDecoration(
                hintText: 'Inizia a scrivere qui...',
                hintStyle: TextStyle(
                  fontSize: _fontSize,
                  color: OlderOSTheme.textSecondary,
                ),
                border: InputBorder.none,
              ),
              onChanged: (_) => _onContentChanged(),
              contextMenuBuilder: OlderOSContextMenuBuilder.buildContextMenu,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: OlderOSTheme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Indietro alla lista
          _ToolbarButton(
            icon: Icons.arrow_back,
            label: 'INDIETRO',
            onTap: _backToList,
          ),

          const SizedBox(width: 16),

          // Salva
          _ToolbarButton(
            icon: Icons.save,
            label: 'SALVA',
            color: OlderOSTheme.success,
            onTap: _saveDocument,
          ),

          const SizedBox(width: 32),

          // Separatore
          Container(width: 2, height: 40, color: Colors.grey.shade300),

          const SizedBox(width: 32),

          // Dimensione testo
          _ToolbarButton(
            icon: Icons.text_decrease,
            onTap: () {
              if (_fontSize > 16) {
                setState(() => _fontSize -= 2);
              }
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${_fontSize.toInt()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),

          _ToolbarButton(
            icon: Icons.text_increase,
            onTap: () {
              if (_fontSize < 32) {
                setState(() => _fontSize += 2);
              }
            },
          ),

          const SizedBox(width: 24),

          // Grassetto
          _ToolbarButton(
            icon: Icons.format_bold,
            isActive: _isBold,
            onTap: () => setState(() => _isBold = !_isBold),
          ),

          // Corsivo
          _ToolbarButton(
            icon: Icons.format_italic,
            isActive: _isItalic,
            onTap: () => setState(() => _isItalic = !_isItalic),
          ),

          // Sottolineato
          _ToolbarButton(
            icon: Icons.format_underline,
            isActive: _isUnderline,
            onTap: () => setState(() => _isUnderline = !_isUnderline),
          ),

          const SizedBox(width: 24),

          // Allineamento
          _ToolbarButton(
            icon: Icons.format_align_left,
            isActive: _textAlign == TextAlign.left,
            onTap: () => setState(() => _textAlign = TextAlign.left),
          ),

          _ToolbarButton(
            icon: Icons.format_align_center,
            isActive: _textAlign == TextAlign.center,
            onTap: () => setState(() => _textAlign = TextAlign.center),
          ),

          _ToolbarButton(
            icon: Icons.format_align_right,
            isActive: _textAlign == TextAlign.right,
            onTap: () => setState(() => _textAlign = TextAlign.right),
          ),

          const Spacer(),

          // Indicatore modifiche non salvate
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: OlderOSTheme.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18, color: OlderOSTheme.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Non salvato',
                    style: TextStyle(
                      color: OlderOSTheme.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BigActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_BigActionButton> createState() => _BigActionButtonState();
}

class _BigActionButtonState extends State<_BigActionButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            color: _isHovered ? widget.color.withOpacity(0.9) : widget.color,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 32, color: Colors.white),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 24,
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

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    this.label,
    this.color,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? OlderOSTheme.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.label != null ? 16 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? color.withOpacity(0.2)
                : (_isHovered ? Colors.grey.shade200 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: widget.isActive
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 24, color: color),
              if (widget.label != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
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

class _DocumentCard extends StatefulWidget {
  final Document document;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.document,
    required this.onTap,
  });

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _isHovered = false;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Oggi';
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
              color: _isHovered ? OlderOSTheme.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.description,
                size: 48,
                color: OlderOSTheme.writerColor,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modificato: ${_formatDate(widget.document.lastModified)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
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
}
