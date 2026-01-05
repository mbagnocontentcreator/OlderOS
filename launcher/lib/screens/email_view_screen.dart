import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import 'email_screen.dart';
import 'compose_email_screen.dart';
import '../services/email_service.dart';

class EmailViewScreen extends StatefulWidget {
  final Email email;

  const EmailViewScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailViewScreen> createState() => _EmailViewScreenState();
}

class _EmailViewScreenState extends State<EmailViewScreen> {
  bool _isOpeningAttachment = false;
  String? _openingFileName;

  Email get email => widget.email;

  String _formatDate(DateTime date) {
    final weekdays = ['Lunedi', 'Martedi', 'Mercoledi', 'Giovedi', 'Venerdi', 'Sabato', 'Domenica'];
    final months = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
                   'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$weekday ${date.day} $month ${date.year}, ore $hour:$minute';
  }

  void _replyToEmail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComposeEmailScreen(
          mode: ComposeMode.reply,
          replyTo: email.senderEmail,
          replyToName: email.senderName,
          originalSubject: email.subject,
          originalBody: email.body,
          originalSender: '${email.senderName} <${email.senderEmail}>',
          originalDate: email.date,
        ),
      ),
    );
  }

  void _forwardEmail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComposeEmailScreen(
          mode: ComposeMode.forward,
          originalSubject: email.subject,
          originalBody: email.body,
          originalSender: '${email.senderName} <${email.senderEmail}>',
          originalDate: email.date,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
        ),
        title: Text(
          'Eliminare questo messaggio?',
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Il messaggio verra spostato nel cestino.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DialogButton(
                  label: 'No, torna indietro',
                  color: OlderOSTheme.textSecondary,
                  onTap: () => Navigator.of(ctx).pop(),
                ),
                const SizedBox(width: 24),
                _DialogButton(
                  label: 'Si, elimina',
                  icon: Icons.delete,
                  color: OlderOSTheme.danger,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true); // Return true = deleted
                  },
                ),
              ],
            ),
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
            title: email.isSent ? 'MESSAGGIO INVIATO' : 'MESSAGGIO',
            onGoHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra azioni
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.arrow_back,
                        label: 'INDIETRO',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (!email.isSent) ...[
                        _ActionButton(
                          icon: Icons.reply,
                          label: 'RISPONDI',
                          color: OlderOSTheme.primary,
                          onTap: () => _replyToEmail(context),
                        ),
                        const SizedBox(width: 16),
                        _ActionButton(
                          icon: Icons.forward,
                          label: 'INOLTRA',
                          color: OlderOSTheme.success,
                          onTap: () => _forwardEmail(context),
                        ),
                        const SizedBox(width: 16),
                      ],
                      _ActionButton(
                        icon: Icons.delete,
                        label: 'ELIMINA',
                        color: OlderOSTheme.danger,
                        onTap: () => _showDeleteConfirmation(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Card messaggio
                  Container(
                    width: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header mittente
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: _getAvatarColor(email.senderName),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(email.senderName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 20),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email.isSent ? 'A: ${email.senderName}' : email.senderName,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(email.date),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Oggetto
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OlderOSTheme.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Oggetto:',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email.subject,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Corpo messaggio
                        Text(
                          email.body,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                        ),

                        // Allegati (se presenti)
                        if (email.hasAttachments) ...[
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.attach_file, size: 28, color: OlderOSTheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                'Allegati (${email.attachments.length})',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...email.attachments.map((attachment) => _AttachmentCard(
                            attachment: attachment,
                            isOpening: _isOpeningAttachment && _openingFileName == attachment.fileName,
                            onTap: () => _openAttachment(attachment),
                          )),
                        ],
                      ],
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

  Future<void> _openAttachment(EmailAttachment attachment) async {
    if (attachment.data == null || attachment.data!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allegato non disponibile')),
      );
      return;
    }

    setState(() {
      _isOpeningAttachment = true;
      _openingFileName = attachment.fileName;
    });

    try {
      // Salva il file temporaneamente
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${attachment.fileName}');
      await file.writeAsBytes(attachment.data!);

      // Apri il file
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossibile aprire: ${attachment.fileName}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningAttachment = false;
          _openingFileName = null;
        });
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

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
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 24, color: color),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
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
            color: _isHovered ? widget.color : widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 24,
                  color: _isHovered ? Colors.white : widget.color,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? Colors.white : widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatefulWidget {
  final EmailAttachment attachment;
  final bool isOpening;
  final VoidCallback onTap;

  const _AttachmentCard({
    required this.attachment,
    required this.isOpening,
    required this.onTap,
  });

  @override
  State<_AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<_AttachmentCard> {
  bool _isHovered = false;

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('sheet') || mimeType.contains('excel')) return Icons.table_chart;
    if (mimeType.contains('zip') || mimeType.contains('archive')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String mimeType) {
    if (mimeType.startsWith('image/')) return Colors.purple;
    if (mimeType.startsWith('video/')) return Colors.red;
    if (mimeType.startsWith('audio/')) return Colors.orange;
    if (mimeType.contains('pdf')) return Colors.red.shade700;
    if (mimeType.contains('word') || mimeType.contains('document')) return Colors.blue;
    if (mimeType.contains('sheet') || mimeType.contains('excel')) return Colors.green;
    return OlderOSTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isOpening ? null : widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isHovered ? OlderOSTheme.primary.withAlpha(26) : OlderOSTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? OlderOSTheme.primary : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileColor(widget.attachment.mimeType).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(widget.attachment.mimeType),
                    size: 28,
                    color: _getFileColor(widget.attachment.mimeType),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attachment.fileName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.attachment.sizeFormatted,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: OlderOSTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (widget.isOpening)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: OlderOSTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'APRI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
