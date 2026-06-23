import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';
import '../services/notification_service.dart';
import '../auth/services/token_storage.dart';
import '../auth/services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum _MenuOpcao { perfil, sair }

// ── Sino com badge de notificações ─────────────────────────────────────────

class _SinoBadge extends StatelessWidget {
  final BuildContext context;
  const _SinoBadge({required this.context});

  void _abrirNotificacoes(BuildContext ctx) {
    NotificationService.instance.buscarLista();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PainelNotificacoes(),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return ListenableBuilder(
      listenable: NotificationService.instance,
      builder: (_, __) {
        final total = NotificationService.instance.totalNaoLidas;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => _abrirNotificacoes(ctx),
              icon: const Icon(Icons.notifications_none,
                  color: AppColors.onSurface),
              tooltip: 'Notificações',
            ),
            if (total > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      total > 99 ? '99+' : '$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Painel de notificações (bottom sheet) ──────────────────────────────────

class _PainelNotificacoes extends StatelessWidget {
  const _PainelNotificacoes();

  String _tempoAtras(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationService.instance,
      builder: (ctx, __) {
        final lista = NotificationService.instance.lista;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Text('Notificações',
                        style: AppTextStyles.headline.copyWith(fontSize: 18)),
                    const Spacer(),
                    if (lista.any((n) => !n.lida))
                      TextButton(
                        onPressed: () {
                          NotificationService.instance.marcarTodasComoLidas();
                        },
                        child: Text(
                          'Marcar todas como lidas',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none,
                          size: 48,
                          color: AppColors.outline.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('Nenhuma notificação',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final n = lista[i];
                      final nome = n.usuarioNome;
                      final titulo = n.itemTitulo;

                      return ListTile(
                        tileColor: n.lida
                            ? null
                            : AppColors.primaryContainer.withOpacity(0.06),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(nome,
                            style: AppTextStyles.input
                                .copyWith(fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (titulo.isNotEmpty)
                              Text(titulo,
                                  style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary, fontSize: 10)),
                            Text(
                              n.mensagem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Text(
                          _tempoAtras(n.criadoEm),
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.outline, fontSize: 10),
                        ),
                        onTap: () async {
                          final nav = Navigator.of(ctx, rootNavigator: true);
                          Navigator.of(ctx).pop();
                          await NotificationService.instance.marcarComoLida(n.id);
                          nav.pushNamed(
                            '/chat',
                            arguments: {
                              'solicitacaoId': n.solicitacaoId,
                              'meuId': n.meuId,
                              'nomeOutroUsuario': nome,
                              'tituloItem': titulo,
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

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
      // Começa a checar notificações periodicamente.
      NotificationService.instance.iniciarPolling();
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
    NotificationService.instance.pararPolling();
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
                if (route == '/doar' || route == '/conversas') {
                  Navigator.pushNamed(context, route);
                } else {
                  Navigator.pushReplacementNamed(context, route);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: '/feed',       child: Text('Feed',       style: _navStyle('/feed'))),
                PopupMenuItem(value: '/doar',       child: Text('Doar',       style: _navStyle('/doar'))),
                PopupMenuItem(value: '/conversas',  child: Text('Chat',       style: _navStyle('/conversas'))),
                PopupMenuItem(value: '/dashboard',  child: Text('Dashboard',  style: _navStyle('/dashboard'))),
                PopupMenuItem(value: '/profile',    child: Text('Perfil',     style: _navStyle('/profile'))),
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
                    onPressed: () => Navigator.pushNamed(context, '/conversas'),
                    child: Text('Chat', style: _navStyle('/conversas')),
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
            _SinoBadge(context: context),
            const SizedBox(width: 4),
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