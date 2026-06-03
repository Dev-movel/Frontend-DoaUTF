import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../auth/services/token_storage.dart';
import '../auth/services/auth_service.dart';
import '../theme/app_colors.dart';

enum _MenuOpcao { perfil, sair }

class MainAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String activeRoute;
  final Widget? leading;

  const MainAppBar({
    super.key,
    this.activeRoute = '/home',
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<MainAppBar> createState() => _MainAppBarState();
}

class _MainAppBarState extends State<MainAppBar> {
  Usuario? _usuario;
  bool _autenticado = false;

  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    final temToken = await TokenStorage.instance.hasTokens();
    if (!temToken) {
      if (mounted) setState(() => _autenticado = false);
      return;
    }
    try {
      final user = await UsuarioService.instance.getMe();
      if (mounted) {
        setState(() {
          _usuario = user;
          _autenticado = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _autenticado = false);
    }
  }

  TextStyle _navStyle(String route) {
    final isActive = widget.activeRoute == route;
    return TextStyle(
      color: isActive ? AppColors.primary : AppColors.onSurface,
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }

  Future<void> _sair() async {
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          // ── Hamburguer mobile (só autenticado) ───────────────────────────
          if (isMobile && _autenticado)
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: AppColors.onSurface),
              onSelected: (route) {
                if (route == '/mapa') {
                  Navigator.pushNamed(context, route);
                } else if (route == '/doar') {
                  Navigator.pushNamed(context, route);
                } else {
                  Navigator.pushReplacementNamed(context, route);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: '/feed',      child: Text('Feed',      style: _navStyle('/feed'))),
                PopupMenuItem(value: '/doar',      child: Text('Doar',      style: _navStyle('/doar'))),
                PopupMenuItem(value: '/mapa',      child: Text('Mapa',      style: _navStyle('/mapa'))),
                PopupMenuItem(value: '/dashboard', child: Text('Dashboard', style: _navStyle('/dashboard'))),
                PopupMenuItem(value: '/profile',   child: Text('Perfil',    style: _navStyle('/profile'))),
              ],
            )
          else
            const SizedBox(width: 20),

          widget.leading ?? const SizedBox.shrink(),

          const Text(
            'DoaUTF',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),

          // ── Menu desktop: só aparece quando autenticado ──────────────────
          if (!isMobile && _autenticado)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/feed'),
                    child: Text('Feed', style: _navStyle('/feed')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/doar'),
                    child: Text('Doar', style: _navStyle('/doar')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/mapa'),
                    child: Text('Mapa', style: _navStyle('/mapa')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                    child: Text('Dashboard', style: _navStyle('/dashboard')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
                    child: Text('Perfil', style: _navStyle('/profile')),
                  ),
                ],
              ),
            )
          else
            const Spacer(),

          // ── Notificação + avatar com dropdown: só quando autenticado ─────
          if (_autenticado) ...[
            const Icon(Icons.notifications_none, color: AppColors.onSurface),
            const SizedBox(width: 10),
            PopupMenuButton<_MenuOpcao>(
              offset: const Offset(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppColors.surface,
              elevation: 4,
              tooltip: '',
              onSelected: (opcao) {
                switch (opcao) {
                  case _MenuOpcao.perfil:
                    Navigator.pushNamed(context, '/profile');
                  case _MenuOpcao.sair:
                    _sair();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _usuario?.nome ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        _usuario?.email ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _MenuOpcao.perfil,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: AppColors.onSurface),
                      SizedBox(width: 10),
                      Text('Configurações de perfil'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _MenuOpcao.sair,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.red.shade600),
                      const SizedBox(width: 10),
                      Text('Sair', style: TextStyle(color: Colors.red.shade600)),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary,
                child: Text(
                  _usuario != null ? _usuario!.nome[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],

          const SizedBox(width: 20),
        ],
      ),
    );
  }
}