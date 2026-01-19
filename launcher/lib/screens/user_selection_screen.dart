import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';
import '../theme/olderos_theme.dart';

/// Schermata per la selezione dell'utente all'avvio
class UserSelectionScreen extends StatefulWidget {
  final Function(User) onUserSelected;
  final VoidCallback onAddUser;

  const UserSelectionScreen({
    super.key,
    required this.onUserSelected,
    required this.onAddUser,
  });

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final users = _userService.users;

    return Scaffold(
      backgroundColor: OlderOSTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Titolo
                const Text(
                  'Chi sei?',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: OlderOSTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Tocca il tuo nome per entrare',
                  style: TextStyle(
                    fontSize: 24,
                    color: OlderOSTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 64),

                // Griglia utenti 2x2
                _buildUsersGrid(users),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersGrid(List<User> users) {
    // Crea lista di 4 slot (utenti + spazi vuoti + pulsante aggiungi)
    final List<Widget> slots = [];

    // Aggiungi utenti esistenti
    for (final user in users) {
      slots.add(_buildUserSlot(user));
    }

    // Aggiungi pulsante "Aggiungi" se c'e' spazio
    if (_userService.canAddUser) {
      slots.add(_buildAddSlot());
    }

    // Riempi con slot vuoti fino a 4
    while (slots.length < 4) {
      slots.add(_buildEmptySlot());
    }

    return Column(
      children: [
        // Prima riga
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            slots[0],
            const SizedBox(width: 48),
            slots[1],
          ],
        ),
        const SizedBox(height: 48),
        // Seconda riga
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            slots[2],
            const SizedBox(width: 48),
            slots[3],
          ],
        ),
      ],
    );
  }

  Widget _buildUserSlot(User user) {
    return SizedBox(
      width: 160,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onUserSelected(user),
              borderRadius: BorderRadius.circular(70),
              splashColor: UserAvatarColors.getColor(user.avatarColorIndex)
                  .withValues(alpha: 0.3),
              child: UserAvatar(
                user: user,
                size: 140,
                showBorder: false,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: OlderOSTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddSlot() {
    return SizedBox(
      width: 160,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onAddUser,
              borderRadius: BorderRadius.circular(70),
              splashColor: OlderOSTheme.primary.withValues(alpha: 0.2),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: OlderOSTheme.primary.withValues(alpha: 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_add,
                  size: 56,
                  color: OlderOSTheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aggiungi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: OlderOSTheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    return const SizedBox(
      width: 160,
      height: 190,
    );
  }
}
