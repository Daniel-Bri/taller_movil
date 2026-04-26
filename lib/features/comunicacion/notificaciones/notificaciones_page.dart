import 'package:flutter/material.dart';
import 'package:taller_movil/services/notificacion_service.dart';
import 'package:taller_movil/services/api_helper.dart';

// CU19 - Recibir Notificaciones
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final _svc = NotificacionService();
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _svc.listarMias();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _marcarLeida(int id) async {
    try {
      await _svc.marcarLeida(id);
      if (!mounted) return;
      setState(() {
        final i = _items.indexWhere((x) => x['id'] == id);
        if (i >= 0) _items[i]['leida'] = true;
      });
    } catch (_) {}
  }

  Future<void> _marcarTodas() async {
    final pendientes = _items.where((n) => n['leida'] != true).toList();
    for (final n in pendientes) {
      await _marcarLeida(n['id'] as int);
    }
  }

  String _tiempoRelativo(String? iso) {
    if (iso == null || iso.isEmpty) return 'Hace un momento';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Hace un momento';
    final d = DateTime.now().difference(dt.toLocal());
    if (d.inMinutes < 1) return 'Hace unos segundos';
    if (d.inMinutes < 60) return 'Hace ${d.inMinutes} minutos';
    if (d.inHours < 24) return 'Hace ${d.inHours} horas';
    return 'Hace ${d.inDays} días';
  }

  Color _tipoColor(String? tipo) {
    final t = (tipo ?? '').toLowerCase();
    if (t.contains('cancel') || t.contains('rechaz')) return const Color(0xFFDC2626);
    if (t.contains('acept') || t.contains('resuelto') || t.contains('solucion')) return const Color(0xFF059669);
    return const Color(0xFFD97706);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF051D72),
        foregroundColor: Colors.white,
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_items.where((x) => x['leida'] != true).isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: const BoxDecoration(color: Color(0xFFEF2B2D), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${_items.where((x) => x['leida'] != true).length}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _items.isEmpty
                  ? const Center(child: Text('Sin notificaciones'))
                  : Stack(
                      children: [
                        ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            final leida = n['leida'] == true;
                            final colorTipo = _tipoColor(n['tipo']?.toString());
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _marcarLeida(n['id'] as int),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: leida ? const Color(0xFFF8FAFC) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: leida ? const Color(0xFFE5E7EB) : colorTipo.withValues(alpha: 0.6),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Opacity(
                                  opacity: leida ? 0.58 : 1,
                                  child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: leida ? const Color(0xFFE5E7EB) : colorTipo.withValues(alpha: 0.15),
                                      child: Icon(
                                        leida ? Icons.notifications_none : Icons.notifications_active_outlined,
                                        color: leida ? const Color(0xFF9CA3AF) : colorTipo,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n['mensaje']?.toString() ?? n['titulo']?.toString() ?? 'Notificación',
                                            style: TextStyle(
                                              fontSize: 17,
                                              height: 1.4,
                                              color: leida ? const Color(0xFF9CA3AF) : const Color(0xFF1E293B),
                                              fontWeight: leida ? FontWeight.w600 : FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 17, color: Colors.grey.shade500),
                                              const SizedBox(width: 6),
                                              Text(
                                                _tiempoRelativo(n['created_at']?.toString()),
                                                style: TextStyle(color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!leida)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: colorTipo,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                )),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 12,
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _marcarTodas,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E89D9),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                              ),
                              child: const Text('Marcar todas como leídas'),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
