import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';
import 'package:taller_movil/services/notificacion_service.dart';
import 'package:taller_movil/shared/app_drawer.dart';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();
  final _notifService = NotificacionService();
  Map<String, dynamic>? _user;
  int _notifsNoLeidas = 0;
  Timer? _notifPoll;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _cargarNotifNoLeidas();
    _notifPoll = Timer.periodic(const Duration(seconds: 20), (_) => _cargarNotifNoLeidas());
  }

  @override
  void dispose() {
    _notifPoll?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUser();
    setState(() => _user = user);
  }

  Future<void> _cargarNotifNoLeidas() async {
    try {
      final rows = await _notifService.listarMias();
      if (!mounted) return;
      setState(() => _notifsNoLeidas = rows.where((x) => x['leida'] != true).length);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  String get _userName    => _user?['full_name'] ?? _user?['username'] ?? 'Usuario';
  String get _role        => _user?['role'] as String? ?? 'cliente';
  bool   get _isAdmin     => _role == 'admin';
  bool   get _isTaller    => _role == 'taller';
  bool   get _isTecnico   => _role == 'tecnico';
  bool   get _isCliente   => _role == 'cliente';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Text('Dashboard', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 4),
            Text('Bienvenido, $_userName', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),

            const SizedBox(height: 24),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _StatCard(
                  icon: Icons.crisis_alert,
                  label: 'Incidentes activos',
                  value: '0',
                  iconBg: Color(0xFFEFF6FF),
                  iconColor: AppColors.primary,
                ),
                _StatCard(
                  icon: Icons.verified_outlined,
                  label: 'Talleres aprobados',
                  value: '0',
                  iconBg: Color(0xFFECFDF5),
                  iconColor: AppColors.success,
                ),
                _StatCard(
                  icon: Icons.pending_actions,
                  label: 'Solicitudes pendientes',
                  value: '0',
                  iconBg: Color(0xFFFEF2F2),
                  iconColor: AppColors.danger,
                ),
                _StatCard(
                  icon: Icons.payments_outlined,
                  label: 'Pagos del mes',
                  value: '\$0',
                  iconBg: Color(0xFFF5F3FF),
                  iconColor: Color(0xFF7C3AED),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Section title — uppercase like web
            const _SectionTitle('Accesos rápidos'),
            const SizedBox(height: 12),

            // Quick cards grid — varía según rol
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                if (_isCliente) ...[
                  _QuickCard(
                    icon: Icons.directions_car,
                    label: 'Mis Vehículos',
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, '/acceso/mis-vehiculos'),
                  ),
                  _QuickCard(
                    icon: Icons.store_outlined,
                    label: 'Registrar Taller',
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: AppColors.success,
                    onTap: () => Navigator.pushNamed(context, '/acceso/registrar-taller'),
                  ),
                  _QuickCard(
                    icon: Icons.warning_amber_outlined,
                    label: 'Reportar Emergencia',
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: AppColors.danger,
                    onTap: () => Navigator.pushNamed(context, '/emergencias/reportar'),
                  ),
                  _QuickCard(
                    icon: Icons.track_changes_outlined,
                    label: 'Mis solicitudes',
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, '/solicitudes/estado'),
                  ),
                  _QuickCard(
                    icon: Icons.history,
                    label: 'Historial',
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () {},
                  ),
                ],
                if (_isTaller) ...[
                  _QuickCard(
                    icon: Icons.assignment_outlined,
                    label: 'Ver Solicitudes',
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, '/solicitudes/disponibles'),
                  ),
                  _QuickCard(
                    icon: Icons.people_outline,
                    label: 'Gestionar Técnicos',
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: AppColors.success,
                    onTap: () {},
                  ),
                  _QuickCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'Cotizaciones',
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: AppColors.danger,
                    onTap: () {},
                  ),
                  _QuickCard(
                    icon: Icons.bar_chart_outlined,
                    label: 'Métricas',
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () {},
                  ),
                ],
                if (_isTecnico) ...[
                  _QuickCard(
                    icon: Icons.build_outlined,
                    label: 'Estado Servicio',
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppColors.primary,
                    onTap: () {},
                  ),
                  _QuickCard(
                    icon: Icons.event_available_outlined,
                    label: 'Disponibilidad',
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: AppColors.success,
                    onTap: () {},
                  ),
                  _QuickCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: AppColors.danger,
                    onTap: () {},
                  ),
                  _QuickCard(
                    icon: Icons.map_outlined,
                    label: 'Mapa',
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () {},
                  ),
                ],
                if (_isAdmin) ...[
                  _QuickCard(
                    icon: Icons.verified_outlined,
                    label: 'Aprobar Talleres',
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: AppColors.success,
                    onTap: () {},
                  ),
                  _QuickCard(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Gestionar Usuarios',
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: AppColors.primary,
                    onTap: () {},
                  ),
                  _QuickCard(
                    icon: Icons.insights_outlined,
                    label: 'Métricas Globales',
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    onTap: () {},
                  ),
                  _QuickCard(
                    icon: Icons.policy_outlined,
                    label: 'Auditoría',
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: AppColors.danger,
                    onTap: () {},
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            // Estado section
            const _SectionTitle('Estado'),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Sin solicitudes activas',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFF3F4F6), height: 1),
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: AppColors.text),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.route, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text('RutaSegura', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text)),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 22),
              if (_notifsNoLeidas > 0)
                Positioned(
                  top: -5,
                  right: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF2B2D),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _notifsNoLeidas > 99 ? '99+' : '$_notifsNoLeidas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Notificaciones',
          onPressed: () async {
            await Navigator.pushNamed(context, '/comunicacion/notificaciones');
            if (mounted) _cargarNotifNoLeidas();
          },
          color: const Color(0xFF6B7280),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, size: 20),
          tooltip: 'Cerrar sesión',
          onPressed: _logout,
          color: const Color(0xFF6B7280),
        ),
      ],
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────
class _AppDrawer extends StatefulWidget {
  const _AppDrawer({
    required this.userInitial,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.onLogout,
  });
  final String userInitial, userName, userEmail, role;
  final VoidCallback onLogout;

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  final _open = <String>{};

  void _toggle(String id) => setState(() =>
    _open.contains(id) ? _open.remove(id) : _open.add(id));

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':   return 'Administrador';
      case 'taller':  return 'Taller';
      case 'tecnico': return 'Técnico';
      default:        return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Brand header ────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.route, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('RutaSegura',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
              ],
            ),
          ),

          // ── Nav ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavLink(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                const _NavDivider(),
                // ── cliente ──────────────────────────────────
                if (widget.role == 'cliente') ...[
                  _NavSection(
                    id: 'acceso', label: 'Mi Cuenta',
                    icon: Icons.manage_accounts_outlined,
                    isOpen: _open.contains('acceso'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Mis Vehículos',    icon: Icons.directions_car_outlined, route: '/acceso/mis-vehiculos'),
                      _NavItem(label: 'Registrar Taller', icon: Icons.store_outlined,          route: '/acceso/registrar-taller'),
                    ],
                  ),
                  _NavSection(
                    id: 'emergencias', label: 'Emergencias',
                    icon: Icons.emergency_outlined,
                    isOpen: _open.contains('emergencias'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Reportar Emergencia', icon: Icons.warning_amber_outlined, route: '/emergencias/reportar'),
                      _NavItem(label: 'Enviar Ubicación',    icon: Icons.location_on_outlined),
                      _NavItem(label: 'Adjuntar Fotos',      icon: Icons.photo_camera_outlined),
                    ],
                  ),
                  _NavSection(
                    id: 'solicitudes', label: 'Solicitudes',
                    icon: Icons.assignment_outlined,
                    isOpen: _open.contains('solicitudes'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Ver Estado',      icon: Icons.track_changes_outlined),
                      _NavItem(label: 'Mis Solicitudes', icon: Icons.history_outlined),
                    ],
                  ),
                  _NavSection(
                    id: 'pagos', label: 'Pagos',
                    icon: Icons.receipt_long_outlined,
                    isOpen: _open.contains('pagos'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Ver Cotización', icon: Icons.receipt_outlined),
                      _NavItem(label: 'Realizar Pago',  icon: Icons.credit_card_outlined),
                    ],
                  ),
                ],

                // ── taller ───────────────────────────────────
                if (widget.role == 'taller') ...[
                  _NavSection(
                    id: 'solicitudes', label: 'Solicitudes',
                    icon: Icons.assignment_outlined,
                    isOpen: _open.contains('solicitudes'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Ver Disponibles',  icon: Icons.list_alt_outlined),
                      _NavItem(label: 'Ver Detalle',      icon: Icons.info_outline),
                      _NavItem(label: 'Aceptar/Rechazar', icon: Icons.rule_outlined),
                    ],
                  ),
                  _NavSection(
                    id: 'talleres', label: 'Talleres y Técnicos',
                    icon: Icons.handyman_outlined,
                    isOpen: _open.contains('talleres'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Gestionar Técnicos',   icon: Icons.people_outline),
                      _NavItem(label: 'Asignar Técnico',      icon: Icons.person_add_outlined),
                      _NavItem(label: 'Servicio Realizado',   icon: Icons.check_circle_outline),
                    ],
                  ),
                  _NavSection(
                    id: 'pagos', label: 'Cotización y Pagos',
                    icon: Icons.receipt_long_outlined,
                    isOpen: _open.contains('pagos'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Generar Cotización', icon: Icons.edit_note_outlined),
                      _NavItem(label: 'Ver Comisiones',     icon: Icons.percent_outlined),
                    ],
                  ),
                  _NavSection(
                    id: 'reportes', label: 'Reportes',
                    icon: Icons.analytics_outlined,
                    isOpen: _open.contains('reportes'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Métricas Taller', icon: Icons.bar_chart_outlined),
                      _NavItem(label: 'Historial',       icon: Icons.history_outlined),
                    ],
                  ),
                ],

                // ── tecnico ──────────────────────────────────
                if (widget.role == 'tecnico') ...[
                  _NavSection(
                    id: 'talleres', label: 'Mi Trabajo',
                    icon: Icons.handyman_outlined,
                    isOpen: _open.contains('talleres'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Actualizar Estado',  icon: Icons.build_outlined),
                      _NavItem(label: 'Disponibilidad',     icon: Icons.event_available_outlined),
                    ],
                  ),
                  _NavSection(
                    id: 'comunicacion', label: 'Comunicación',
                    icon: Icons.forum_outlined,
                    isOpen: _open.contains('comunicacion'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Chat',           icon: Icons.chat_bubble_outline),
                      _NavItem(label: 'Notificaciones', icon: Icons.notifications_outlined),
                      _NavItem(label: 'Ver en Mapa',    icon: Icons.map_outlined),
                    ],
                  ),
                ],

                // ── admin ────────────────────────────────────
                if (widget.role == 'admin') ...[
                  _NavSection(
                    id: 'acceso', label: 'Gestión de Acceso',
                    icon: Icons.manage_accounts_outlined,
                    isOpen: _open.contains('acceso'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Gestionar Usuarios', icon: Icons.people_outline),
                      _NavItem(label: 'Aprobar Talleres',   icon: Icons.verified_outlined),
                    ],
                  ),
                  _NavSection(
                    id: 'reportes', label: 'Reportes',
                    icon: Icons.analytics_outlined,
                    isOpen: _open.contains('reportes'), onToggle: _toggle,
                    items: const [
                      _NavItem(label: 'Métricas Globales', icon: Icons.insights_outlined),
                      _NavItem(label: 'Auditoría',         icon: Icons.policy_outlined),
                    ],
                  ),
                ],

                // ── común a todos ─────────────────────────────
                _NavSection(
                  id: 'comunicacion_comun', label: 'Comunicación',
                  icon: Icons.forum_outlined,
                  isOpen: _open.contains('comunicacion_comun'), onToggle: _toggle,
                  items: const [
                    _NavItem(label: 'Chat',           icon: Icons.chat_bubble_outline),
                    _NavItem(label: 'Notificaciones', icon: Icons.notifications_outlined),
                  ],
                ),
              ],
            ),
          ),

          // ── User footer ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary,
                  child: Text(widget.userInitial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.userName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
                        overflow: TextOverflow.ellipsis),
                      Text(_roleLabel(widget.role),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: Color(0xFF9CA3AF)),
                  tooltip: 'Cerrar sesión',
                  onPressed: widget.onLogout,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer subwidgets ────────────────────────────────────────
class _NavLink extends StatelessWidget {
  const _NavLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: Icon(icon, size: 20, color: AppColors.primary),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text)),
    onTap: onTap,
  );
}

class _NavDivider extends StatelessWidget {
  const _NavDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 0, endIndent: 0);
}

class _NavSection extends StatelessWidget {
  const _NavSection({
    required this.id,
    required this.label,
    required this.icon,
    required this.isOpen,
    required this.onToggle,
    required this.items,
  });
  final String id, label;
  final IconData icon;
  final bool isOpen;
  final void Function(String) onToggle;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF374151))),
          trailing: Icon(
            isOpen ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: const Color(0xFF9CA3AF),
          ),
          onTap: () => onToggle(id),
        ),
        if (isOpen)
          Container(
            color: const Color(0xFFFAFAFA),
            child: Column(
              children: items.map((item) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 52, right: 16),
                leading: Icon(item.icon, size: 16, color: const Color(0xFF9CA3AF)),
                title: Text(item.label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                onTap: () {
                  Navigator.pop(context);
                  if (item.route != null) Navigator.pushNamed(context, item.route!);
                },
              )).toList(),
            ),
          ),
        const Divider(height: 1, color: Color(0xFFF9FAFB)),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, this.route});
  final String label;
  final IconData icon;
  final String? route;
}

// ── Dashboard widgets ─────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Color(0xFF6B7280),
      letterSpacing: 0.8,
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconColor,
  });
  final IconData icon;
  final String label, value;
  final Color iconBg, iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text, height: 1)),
                const SizedBox(height: 2),
                Text(label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color iconBg, iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }
}
