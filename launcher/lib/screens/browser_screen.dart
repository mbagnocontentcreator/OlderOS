import 'package:flutter/material.dart';
import '../theme/olderos_theme.dart';
import '../widgets/top_bar.dart';
import 'webview_screen.dart';

class FavoriteSite {
  final String name;
  final String url;
  final IconData icon;
  final Color color;

  const FavoriteSite({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
  });
}

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<FavoriteSite> _favorites = const [
    FavoriteSite(
      name: 'Repubblica',
      url: 'https://www.repubblica.it',
      icon: Icons.newspaper,
      color: Color(0xFFD32F2F),
    ),
    FavoriteSite(
      name: 'RAI News',
      url: 'https://www.rainews.it',
      icon: Icons.tv,
      color: Color(0xFF1976D2),
    ),
    FavoriteSite(
      name: 'Meteo',
      url: 'https://www.ilmeteo.it',
      icon: Icons.wb_sunny,
      color: Color(0xFFF57C00),
    ),
    FavoriteSite(
      name: 'Google',
      url: 'https://www.google.it',
      icon: Icons.search,
      color: Color(0xFF4285F4),
    ),
    FavoriteSite(
      name: 'YouTube',
      url: 'https://www.youtube.com',
      icon: Icons.play_circle_filled,
      color: Color(0xFFFF0000),
    ),
    FavoriteSite(
      name: 'Wikipedia',
      url: 'https://it.wikipedia.org',
      icon: Icons.menu_book,
      color: Color(0xFF757575),
    ),
  ];

  void _search() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final searchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      _openWebView(searchUrl, 'Ricerca: $query');
    }
  }

  void _openWebView(String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: url,
          title: title,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopBar(
            title: 'INTERNET',
            onGoHome: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(OlderOSTheme.marginScreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // Titolo ricerca
                  Text(
                    'Cosa vuoi cercare?',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 24),

                  // Barra di ricerca
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: OlderOSTheme.cardBackground,
                            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
                            border: Border.all(
                              color: OlderOSTheme.primary,
                              width: 2,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: Theme.of(context).textTheme.titleLarge,
                            decoration: InputDecoration(
                              hintText: 'Scrivi qui cosa cercare...',
                              hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: OlderOSTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _SearchButton(onTap: _search),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Titolo preferiti
                  Text(
                    'Siti preferiti:',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 24),

                  // Griglia preferiti
                  Expanded(
                    child: Center(
                      child: Wrap(
                        spacing: OlderOSTheme.gapElements * 1.5,
                        runSpacing: OlderOSTheme.gapElements * 1.5,
                        alignment: WrapAlignment.center,
                        children: _favorites.map((site) => _FavoriteCard(
                          site: site,
                          onTap: () => _openWebView(site.url, site.name),
                        )).toList(),
                      ),
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
}

class _SearchButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SearchButton({required this.onTap});

  @override
  State<_SearchButton> createState() => _SearchButtonState();
}

class _SearchButtonState extends State<_SearchButton> {
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
            ..scale(_isPressed ? 0.95 : 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered ? OlderOSTheme.primary.withOpacity(0.9) : OlderOSTheme.primary,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
          ),
          child: const Icon(
            Icons.search,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatefulWidget {
  final FavoriteSite site;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.site,
    required this.onTap,
  });

  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard> {
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
          width: 180,
          height: 140,
          decoration: BoxDecoration(
            color: OlderOSTheme.cardBackground,
            borderRadius: BorderRadius.circular(OlderOSTheme.borderRadiusCard),
            border: Border.all(
              color: _isHovered ? widget.site.color : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.site.icon,
                size: 48,
                color: widget.site.color,
              ),
              const SizedBox(height: 12),
              Text(
                widget.site.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
