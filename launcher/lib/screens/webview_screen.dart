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
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            final canGoBack = await _controller.canGoBack();
            setState(() => _canGoBack = canGoBack);
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
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

          // WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
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
