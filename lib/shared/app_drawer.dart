import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _auth = AuthService();
  Map<String, dynamic>? _user;
  final Set<String> _expanded = {'emergencias'};

  @override
  void initState() {
    super.initState();
    _auth.getUser().then((u) => setState(() => _user = u));
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigate(String route) {
    Navigator.pop(context); // cerrar drawer
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final name    = _user?['full_name'] ?? _user?['username'] ?? '...';
    final email   = _user?['email'] ?? '';
    final role    = _user?['role'] as String? ?? 'cliente';
    final isAdmin = role == 'admin';
    final isTaller  = role == 'taller';
    final isTecnico = role == 'tecnico';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Cabecera de usuario ──────────────────────────
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            accountName: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            accountEmail: Row(
              children: [
                Text(email, style: const TextStyle(fontSize: 12)),
                if (role != 'cliente') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isAdmin ? 'Admin' : isTaller ? 'Taller' : 'Técnico',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Ítems de navegación ──────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [

                // Dashboard
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Inicio',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/dashboard', (r) => false);
                  },
                ),

                const _SectionDivider(),

                // ── cliente ──────────────────────────────────
                if (!isTaller && !isTecnico && !isAdmin) ...[
                  _NavSection(
                    id: 'acceso',
                    icon: Icons.manage_accounts_outlined,
                    label: 'Mi Cuenta',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Mis vehículos',
                          onTap: () => _navigate('/acceso/mis-vehiculos')),
                      _NavChild(label: 'Registrar taller',
                          onTap: () => _navigate('/acceso/registrar-taller')),
                    ],
                  ),
                  _NavSection(
                    id: 'emergencias',
                    icon: Icons.warning_amber_rounded,
                    label: 'Emergencias',
                    expanded: _expanded,
                    onToggle: _toggle,
                    iconColor: AppColors.danger,
                    children: [
                      _NavChild(label: 'Reportar emergencia',
                          onTap: () => _navigate('/emergencias/reportar')),
                      _NavChild(label: 'Enviar ubicación GPS',
                          onTap: () => _navigate('/emergencias/ubicacion')),
                      _NavChild(label: 'Adjuntar fotos',
                          onTap: () => _navigate('/emergencias/fotos')),
                      _NavChild(label: 'Enviar audio',
                          onTap: () => _navigate('/emergencias/audio')),
                    ],
                  ),
                  _NavSection(
                    id: 'solicitudes',
                    icon: Icons.assignment_outlined,
                    label: 'Mis Solicitudes',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Ver estado',
                          onTap: () => _navigate('/solicitudes/estado')),
                      _NavChild(label: 'Cancelar solicitud',
                          onTap: () => _navigate('/solicitudes/cancelar')),
                    ],
                  ),
                  _NavSection(
                    id: 'pagos',
                    icon: Icons.payments_outlined,
                    label: 'Pagos',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Ver cotización',
                          onTap: () => _navigate('/pagos/ver')),
                      _NavChild(label: 'Realizar pago',
                          onTap: () => _navigate('/pagos/realizar')),
                    ],
                  ),
                  _NavSection(
                    id: 'mantenimiento',
                    icon: Icons.build_circle_outlined,
                    label: 'Mantenimiento',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(
                        label: 'Recordatorios preventivos',
                        onTap: () => _navigate('/mantenimiento/recordatorios'),
                      ),
                    ],
                  ),
                ],

                // ── taller ───────────────────────────────────
                if (isTaller) ...[
                  _NavSection(
                    id: 'solicitudes',
                    icon: Icons.assignment_outlined,
                    label: 'Solicitudes',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Solicitudes disponibles',
                          onTap: () => _navigate('/solicitudes/disponibles')),
                      _NavChild(label: 'Detalle de incidente',
                          onTap: () => _navigate('/solicitudes/detalle')),
                      _NavChild(label: 'Aceptar solicitud',
                          onTap: () => _navigate('/solicitudes/aceptar')),
                      _NavChild(label: 'Rechazar solicitud',
                          onTap: () => _navigate('/solicitudes/rechazar')),
                    ],
                  ),
                  _NavSection(
                    id: 'talleres',
                    icon: Icons.build_outlined,
                    label: 'Talleres y Técnicos',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Actualizar estado servicio',
                          onTap: () => _navigate('/talleres/estado-servicio')),
                      _NavChild(label: 'Registrar servicio realizado',
                          onTap: () => _navigate('/talleres/servicio-realizado')),
                    ],
                  ),
                  _NavSection(
                    id: 'pagos',
                    icon: Icons.payments_outlined,
                    label: 'Cotización y Pagos',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Generar cotización',
                          onTap: () => _navigate('/pagos/generar')),
                      _NavChild(label: 'Confirmar cotización',
                          onTap: () => _navigate('/pagos/confirmar')),
                      _NavChild(label: 'Ver comisiones',
                          onTap: () => _navigate('/pagos/comisiones')),
                    ],
                  ),
                  _NavSection(
                    id: 'reportes',
                    icon: Icons.bar_chart_outlined,
                    label: 'Reportes',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Métricas del taller',
                          onTap: () => _navigate('/reportes/metricas-taller')),
                      _NavChild(label: 'Historial de servicios',
                          onTap: () => _navigate('/reportes/historial')),
                    ],
                  ),
                ],

                // ── tecnico ──────────────────────────────────
                if (isTecnico) ...[
                  _NavSection(
                    id: 'talleres',
                    icon: Icons.build_outlined,
                    label: 'Mi Trabajo',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Actualizar estado servicio',
                          onTap: () => _navigate('/talleres/estado-servicio')),
                      _NavChild(label: 'Registrar servicio realizado',
                          onTap: () => _navigate('/talleres/servicio-realizado')),
                    ],
                  ),
                ],

                // ── admin ────────────────────────────────────
                if (isAdmin) ...[
                  _NavSection(
                    id: 'acceso',
                    icon: Icons.manage_accounts_outlined,
                    label: 'Gestión',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Aprobar talleres',
                          onTap: () => _navigate('/aprobar-talleres')),
                      _NavChild(label: 'Gestionar usuarios',
                          onTap: () => _navigate('/gestionar-usuarios')),
                    ],
                  ),
                  _NavSection(
                    id: 'reportes',
                    icon: Icons.bar_chart_outlined,
                    label: 'Reportes',
                    expanded: _expanded,
                    onToggle: _toggle,
                    children: [
                      _NavChild(label: 'Métricas globales',
                          onTap: () => _navigate('/reportes/metricas-globales')),
                      _NavChild(label: 'Auditoría',
                          onTap: () => _navigate('/reportes/auditoria')),
                    ],
                  ),
                ],

                // ── común a todos ─────────────────────────────
                _NavSection(
                  id: 'comunicacion',
                  icon: Icons.chat_bubble_outline,
                  label: 'Comunicación',
                  expanded: _expanded,
                  onToggle: _toggle,
                  children: [
                    _NavChild(label: 'Chat',
                        onTap: () => _navigate('/comunicacion/chat')),
                    _NavChild(label: 'Notificaciones',
                        onTap: () => _navigate('/comunicacion/notificaciones')),
                    _NavChild(label: 'Ver técnico en mapa',
                        onTap: () => _navigate('/comunicacion/mapa')),
                  ],
                ),
                _NavSection(
                  id: 'reportes_comun',
                  icon: Icons.history_outlined,
                  label: 'Historial',
                  expanded: _expanded,
                  onToggle: _toggle,
                  children: [
                    _NavChild(label: 'Historial de servicios',
                        onTap: () => _navigate('/reportes/historial')),
                    _NavChild(label: 'Calificar servicio',
                        onTap: () => _navigate('/reportes/calificar')),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Pie con logout ───────────────────────────────
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger, size: 22),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }
}

// ── Widgets internos ─────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }
}

class _NavSection extends StatelessWidget {
  const _NavSection({
    required this.id,
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.iconColor,
  });

  final String id;
  final IconData icon;
  final String label;
  final Set<String> expanded;
  final void Function(String) onToggle;
  final List<Widget> children;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isOpen = expanded.contains(id);
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
          title: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text)),
          trailing: AnimatedRotation(
            turns: isOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more, color: AppColors.grey, size: 20),
          ),
          horizontalTitleGap: 8,
          onTap: () => onToggle(id),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: const Color(0xFFF9FAFB),
            child: Column(children: children),
          ),
          crossFadeState:
              isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        const _SectionDivider(),
      ],
    );
  }
}

class _NavChild extends StatelessWidget {
  const _NavChild({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: AppColors.text)),
      dense: true,
      onTap: onTap,
    );
  }
}
