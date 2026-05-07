import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/state/auth_controller.dart';
import '../../../../core/state/cart_scope.dart';
import '../../../../core/state/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/state/auth_controller.dart';

class NavbarWidget extends StatefulWidget {
  const NavbarWidget({super.key});

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  int? _hoveredIndex;

  static const _links = [
    ('Smartphones',  AppRoutes.catalog),
    ('Computadoras', AppRoutes.catalog),
    ('Accesorios',   AppRoutes.catalog),
    ('Componentes',  AppRoutes.catalog),
    ('Ofertas',      AppRoutes.catalog),
  ];

  @override
  Widget build(BuildContext context) {
    final cart  = CartController();
    final auth  = AuthController();
    final width = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        return Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.lightBorder)),
          ),
          padding: EdgeInsets.symmetric(
              horizontal: width < 900 ? 16 : 40),
          child: Row(
            children: [
              // Logo
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(text: 'Celu',
                          style: AppTextStyles.logoText()),
                      TextSpan(text: 'Center',
                          style: AppTextStyles.logoText()
                              .copyWith(color: AppColors.primary)),
                    ]),
                  ),
                ),
              ),

              // Links — solo en pantallas anchas
              if (width >= 900) ...[
                const SizedBox(width: 24),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_links.length, (i) {
                        final (label, route) = _links[i];
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) =>
                              setState(() => _hoveredIndex = i),
                          onExit:  (_) =>
                              setState(() => _hoveredIndex = null),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: GestureDetector(
                              onTap: () => context.go(route),
                              child: Text(label,
                                  style: AppTextStyles.navLink().copyWith(
                                    color: _hoveredIndex == i
                                        ? AppColors.primary
                                        : const Color(0xFF555555),
                                  )),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ] else
                const Spacer(),

              // Buscador
              if (width >= 1100) ...[
                SizedBox(
                  width: 180, height: 36,
                  child: TextField(
                    onSubmitted: (_) => context.go(AppRoutes.catalog),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: Color(0xFFAAAAAA)),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: AppTextStyles.body(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Admin badge
              if (auth.isLoggedIn && auth.isAdmin && width >= 900) ...[
                _NavBtn(
                  label: 'Admin',
                  icon: Icons.admin_panel_settings_outlined,
                  color: AppColors.primary,
                  onTap: () => context.go(AppRoutes.admin),
                ),
                const SizedBox(width: 8),
              ],

              // Usuario logueado o botón Mi cuenta
              if (auth.isLoggedIn) ...[
                _UserMenu(
                  userName: auth.userName ?? '',
                  isAdmin: auth.isAdmin,
                  onLogout: () => auth.logout(),
                  onAdmin: () => context.go(AppRoutes.admin),
                ),
                const SizedBox(width: 8),
              ] else if (width >= 900) ...[
                _NavBtn(
                  label: 'Mi cuenta',
                  icon: Icons.person_outline,
                  onTap: () => context.go(AppRoutes.login),
                ),
                const SizedBox(width: 8),
              ],

              // Carrito
              _CartButton(
                  itemCount: cart.itemCount, onTap: cart.toggleCart),
            ],
          ),
        );
      },
    );
  }
}

// ── Menú de usuario logueado ───────────────────────────────────────────────
class _UserMenu extends StatefulWidget {
  final String userName;
  final bool isAdmin;
  final VoidCallback onLogout;
  final VoidCallback onAdmin;

  const _UserMenu({
    required this.userName,
    required this.isAdmin,
    required this.onLogout,
    required this.onAdmin,
  });

  @override
  State<_UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<_UserMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.userName,
                  style: AppTextStyles.body(
                      fontSize: 14, weight: FontWeight.w600)),
              if (widget.isAdmin)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.g9,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Administrador',
                      style: AppTextStyles.body(
                          fontSize: 11, color: AppColors.primary,
                          weight: FontWeight.w500)),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: Row(children: [
            Icon(Icons.person_outline, size: 16),
            SizedBox(width: 10),
            Text('Mi perfil y pedidos'),
          ]),
        ),
        if (widget.isAdmin) ...[
          const PopupMenuItem(
            value: 'admin',
            child: Row(children: [
              Icon(Icons.admin_panel_settings_outlined, size: 16),
              SizedBox(width: 10),
              Text('Panel admin'),
            ]),
          ),
          const PopupMenuItem(
            value: 'warehouse',
            child: Row(children: [
              Icon(Icons.warehouse_outlined, size: 16),
              SizedBox(width: 10),
              Text('Vista de bodega'),
            ]),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(children: [
            Icon(Icons.logout, size: 16, color: Color(0xFFE57373)),
            SizedBox(width: 10),
            Text('Cerrar sesión',
                style: TextStyle(color: Color(0xFFE57373))),
          ]),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout')    widget.onLogout();
        if (value == 'admin')     widget.onAdmin();
        if (value == 'profile')   context.go(AppRoutes.profile);
        if (value == 'warehouse') context.go(AppRoutes.warehouse);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightBorder),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.g9,
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : '?',
              style: AppTextStyles.body(
                  fontSize: 12, color: AppColors.primary,
                  weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.userName.split(' ').first,
            style: AppTextStyles.body(
                fontSize: 13, weight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.midGray),
        ]),
      ),
    );
  }
}

// ── Botón genérico ─────────────────────────────────────────────────────────
class _NavBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _NavBtn({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? const Color(0xFF555555);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.lightBorder : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 16, color: c),
            const SizedBox(width: 5),
            Text(widget.label,
                style: AppTextStyles.btnLabel(fontSize: 13)
                    .copyWith(color: c)),
          ]),
        ),
      ),
    );
  }
}

// ── Carrito ────────────────────────────────────────────────────────────────
class _CartButton extends StatefulWidget {
  final int itemCount;
  final VoidCallback onTap;
  const _CartButton({required this.itemCount, required this.onTap});

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.itemCount;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _anim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_CartButton old) {
    super.didUpdateWidget(old);
    if (widget.itemCount != _prev) {
      _ctrl.forward(from: 0);
      _prev = widget.itemCount;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.g2 : AppColors.primary,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.shopping_cart_outlined,
                color: AppColors.white, size: 15),
            const SizedBox(width: 5),
            Text('Carrito',
                style: AppTextStyles.btnLabel(fontSize: 13)
                    .copyWith(color: AppColors.white)),
            if (widget.itemCount > 0) ...[
              const SizedBox(width: 6),
              ScaleTransition(
                scale: _anim,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${widget.itemCount}',
                      style: AppTextStyles.badge(
                          color: AppColors.primary)),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class NavBarDelegate extends SliverPersistentHeaderDelegate {
  @override double get minExtent => 68;
  @override double get maxExtent => 68;
  @override
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) => const NavbarWidget();
  @override
  bool shouldRebuild(NavBarDelegate old) => false;
}
