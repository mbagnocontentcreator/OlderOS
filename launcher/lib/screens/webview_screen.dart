import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/olderos_theme.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _canGoBack = false;
  String _currentTitle = '';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            final canGoBack = await _controller.canGoBack();
            setState(() => _canGoBack = canGoBack);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Gestisci errori di connessione
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = _getErrorMessage(error.errorCode);
            });
          },
          onHttpError: (error) {
            // Gestisci errori HTTP (404, 500, ecc.)
            if (error.response?.statusCode == 404) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = 'La pagina che cerchi non esiste.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  String _getErrorMessage(int errorCode) {
    // Codici di errore comuni di WebView
    // -2: ERR_INTERNET_DISCONNECTED o ERR_NAME_NOT_RESOLVED
    // -6: ERR_CONNECTION_REFUSED
    // -7: ERR_CONNECTION_TIMED_OUT
    // -105: ERR_NAME_NOT_RESOLVED
    switch (errorCode) {
      case -2:
      case -105:
        return 'Non riesco a collegarmi a Internet.\nVerifica che il modem sia acceso.';
      case -6:
        return 'Il sito non risponde.\nRiprova piu\' tardi.';
      case -7:
        return 'La connessione e\' troppo lenta.\nRiprova piu\' tardi.';
      default:
        return 'C\'e\' stato un problema.\nRiprova piu\' tardi.';
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  void _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goToStart() {
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra di navigazione semplificata
          _BrowserBar(
            title: _currentTitle,
            isLoading: _isLoading,
            canGoBack: _canGoBack,
            onGoBack: _goBack,
            onGoHome: _goHome,
            onGoToStart: _goToStart,
          ),

          // WebView o schermata errore
          Expanded(
            child: _hasError
                ? _ErrorScreen(
                    message: _errorMessage,
                    onRetry: _retry,
                    onGoHome: _goHome,
                  )
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}

/// Schermata di errore amichevole per problemi di connessione
class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onGoHome;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OlderOSTheme.background,
      padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icona grande
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: OlderOSTheme.danger.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: OlderOSTheme.danger,
              ),
            ),

            const SizedBox(height: 32),

            // Titolo
            Text(
              'Ops! C\'e\' un problema',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: OlderOSTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Messaggio di errore
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: OlderOSTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Pulsanti
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ErrorButton(
                  label: 'RIPROVA',
                  icon: Icons.refresh,
                  color: OlderOSTheme.primary,
                  onTap: onRetry,
                ),
                const SizedBox(width: 24),
                _ErrorButton(
                  label: 'TORNA A CASA',
                  icon: Icons.home,
                  color: OlderOSTheme.success,
                  onTap: onGoHome,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ErrorButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ErrorButton> createState() => _ErrorButtonState();
}

class _ErrorButtonState extends State<_ErrorButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: _isHovered ? widget.color : widget.color.withAlpha(230),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 22,
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

class _BrowserBar extends StatelessWidget {
  final String title;
  final bool isLoading;
  final bool canGoBack;
  final VoidCallback onGoBack;
  final VoidCallback onGoHome;
  final VoidCallback onGoToStart;

  const _BrowserBar({
    required this.title,
    required this.isLoading,
    required this.canGoBack,
    required this.onGoBack,
    required this.onGoHome,
    required this.onGoToStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OlderOSTheme.marginScreen,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: OlderOSTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Torna a Casa
          _NavButton(
            icon: Icons.home_rounded,
            label: 'TORNA A CASA',
            color: OlderOSTheme.primary,
            onTap: onGoHome,
          ),

          const SizedBox(width: 16),

          // Indietro
          _NavButton(
            icon: Icons.arrow_back_rounded,
            label: 'INDIETRO',
            color: canGoBack ? OlderOSTheme.textPrimary : OlderOSTheme.textSecondary,
            onTap: canGoBack ? onGoBack : null,
          ),

          const SizedBox(width: 16),

          // Torna a inizio
          _NavButton(
            icon: Icons.refresh_rounded,
            label: 'RICOMINCIA',
            color: OlderOSTheme.textPrimary,
            onTap: onGoToStart,
          ),

          const Spacer(),

          // Indicatore caricamento o titolo
          if (isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: OlderOSTheme.primary,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Caricamento...',
                  style: TextStyle(
                    fontSize: 20,
                    color: OlderOSTheme.textSecondary,
                  ),
                ),
              ],
            )
          else
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.95 : 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered && isEnabled
                ? widget.color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered && isEnabled ? widget.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 28,
                color: widget.color,
              ),
              const SizedBox(width: 8),
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
