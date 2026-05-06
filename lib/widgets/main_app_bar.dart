import 'package:flutter/material.dart';
import '../auth/services/token_storage.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';

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
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    final loggedIn = await TokenStorage.instance.hasTokens();
    if (!mounted) return;
    setState(() => _isLoggedIn = loggedIn);
    if (loggedIn) _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    try {
      final user = await UsuarioService.instance.getMe();
      if (mounted) setState(() => _usuario = user);
    } catch (_) {}
  }

  TextStyle _navStyle(String route) {
    final isActive = widget.activeRoute == route;
    return TextStyle(
      color: isActive ? AppColors.primary : AppColors.onSurface,
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: widget.leading,
      title: const Text(
        'DoaUTF',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      actions: _isLoggedIn ? _loggedInActions(context) : _guestActions(context),
    );
  }

  List<Widget> _loggedInActions(BuildContext context) => [
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          child: Text('Home', style: _navStyle('/home')),
        ),
        TextButton(
          onPressed: () {},
          child: Text('Mapa', style: _navStyle('/mapa')),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/doar'),
          child: Text('Doar', style: _navStyle('/doar')),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/dashboard'),
          child: Text('Dashboard', style: _navStyle('/dashboard')),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/profile'),
          child: Text('Perfil', style: _navStyle('/profile')),
        ),
        const SizedBox(width: 20),
        const Icon(Icons.notifications_none, color: AppColors.onSurface),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.primary,
            child: Text(
              _usuario != null ? _usuario!.nome[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 20),
      ];

  List<Widget> _guestActions(BuildContext context) => [];
}
