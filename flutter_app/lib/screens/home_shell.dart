import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'admin_screen.dart';
import 'animals_screen.dart';
import 'campaigns_screen.dart';
import 'content_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.token,
    required this.user,
    required this.onLogout,
  });

  final String token;
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final ApiClient _client;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(token: widget.token);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user['tipo']?.toString() == 'administrador';

    final pages = <Widget>[
      HomeScreen(
        client: _client,
        onNavigate: (index) => setState(() => _index = index),
      ),
      AnimalsScreen(client: _client),
      CampaignsScreen(client: _client),
      ContentScreen(client: _client),
      if (isAdmin) AdminScreen(client: _client, user: widget.user),
      ProfileScreen(
        client: _client,
        user: widget.user,
        onLogout: widget.onLogout,
      ),
    ];

    final titles = <String>[
      'Início',
      'Animais',
      'Campanhas',
      'Conteúdos',
      if (isAdmin) 'Administração',
      'Meu perfil',
    ];

    final items = <_FloatNavItem>[
      const _FloatNavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Início',
      ),
      const _FloatNavItem(
        icon: Icons.pets_outlined,
        selectedIcon: Icons.pets_rounded,
        label: 'Animais',
      ),
      const _FloatNavItem(
        icon: Icons.volunteer_activism_outlined,
        selectedIcon: Icons.volunteer_activism_rounded,
        label: 'Doações',
      ),
      const _FloatNavItem(
        icon: Icons.article_outlined,
        selectedIcon: Icons.article_rounded,
        label: 'Conteúdo',
      ),
      if (isAdmin)
        const _FloatNavItem(
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings_rounded,
          label: 'Admin',
        ),
      const _FloatNavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Perfil',
      ),
    ];

    if (_index >= pages.length) _index = 0;

    return Scaffold(
      // O corpo continua por baixo da região da barra. Isso faz o dock parecer
      // realmente solto sobre a interface, em vez de uma barra presa à borda.
      extendBody: true,
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          if (isAdmin)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Chip(
                avatar: Icon(Icons.shield_outlined, size: 18),
                label: Text('ADMIN'),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.pets),
          ),
        ],
      ),
      body: Padding(
        // Reserva espaço para que o conteúdo rolável não fique encoberto pelo dock.
        padding: const EdgeInsets.only(bottom: 92),
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: _ModernFloatingDock(
        selectedIndex: _index,
        items: items,
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _FloatNavItem {
  const _FloatNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _ModernFloatingDock extends StatelessWidget {
  const _ModernFloatingDock({
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<_FloatNavItem> items;
  final ValueChanged<int> onSelected;

  static const _dockColor = Color(0xFF10382A);
  static const _selectedColor = Color(0xFF2C7A57);
  static const _selectedGlow = Color(0xFF66C99A);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: _dockColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: _selectedGlow.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == selectedIndex;
              return Expanded(
                child: _FloatingDockButton(
                  item: item,
                  selected: selected,
                  compact: items.length > 5,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FloatingDockButton extends StatelessWidget {
  const _FloatingDockButton({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final _FloatNavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(21),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(21),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected
                    ? _ModernFloatingDock._selectedColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(21),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _ModernFloatingDock._selectedGlow
                              .withOpacity(0.20),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: selected ? 25 : 22,
                      color: selected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: compact ? 9.0 : 10.2,
                      height: 1.0,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
