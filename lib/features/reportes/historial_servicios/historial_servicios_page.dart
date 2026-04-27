import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/emergencia_service.dart';
import 'package:taller_movil/services/api_helper.dart';

/// CU29 – Historial de servicios realizados (cliente y taller ven su propio historial).
class HistorialServiciosPage extends StatefulWidget {
  const HistorialServiciosPage({super.key});

  @override
  State<HistorialServiciosPage> createState() => _HistorialServiciosPageState();
}

class _HistorialServiciosPageState extends State<HistorialServiciosPage> {
  final _svc = EmergenciaService();

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await _svc.listarHistorial();
      if (!mounted) return;
      setState(() { _items = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Historial de Servicios', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar, tooltip: 'Actualizar'),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    if (_error.isNotEmpty) return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Text(_error, style: const TextStyle(color: AppColors.danger, fontSize: 13), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
      ]),
    ));

    if (_items.isEmpty) return const Center(child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history, size: 60, color: Color(0xFFD1D5DB)),
        SizedBox(height: 16),
        Text('No hay servicios en el historial.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 15), textAlign: TextAlign.center),
      ]),
    ));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _HistorialCard(_items[i]),
    );
  }
}

class _HistorialCard extends StatefulWidget {
  const _HistorialCard(this.item);
  final Map<String, dynamic> item;

  @override
  State<_HistorialCard> createState() => _HistorialCardState();
}

class _HistorialCardState extends State<_HistorialCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final incId    = it['incidente_id']?.toString() ?? '?';
    final tipo     = it['tipo_incidente'] as String? ?? '';
    final trabajo  = it['descripcion_trabajo'] as String? ?? '';
    final monto    = (it['monto_cotizacion'] as num?)?.toStringAsFixed(2);
    final fechaStr = it['fecha_cierre'] as String? ?? '';
    final fecha    = fechaStr.length >= 10 ? fechaStr.substring(0, 10) : fechaStr;

    List<dynamic> repuestos = [];
    try {
      final raw = it['repuestos'];
      if (raw is String && raw.isNotEmpty) repuestos = jsonDecode(raw) as List;
      else if (raw is List) repuestos = raw;
    } catch (_) {}

    final observaciones = it['observaciones'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Incidente #$incId',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
                    const SizedBox(width: 8),
                    if (tipo.isNotEmpty) _TipoBadge(tipo),
                  ]),
                  const SizedBox(height: 4),
                  Text(fecha, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ])),
                if (monto != null)
                  Text('Bs. $monto',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF9CA3AF)),
              ]),
            ),
          ),

          // Trabajo siempre visible
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(trabajo,
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis),
          ),

          // Detalles expandibles
          if (_expanded) ...[
            if (repuestos.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Repuestos utilizados:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  ...repuestos.map((r) {
                    final desc = r['descripcion'] ?? r['nombre'] ?? '';
                    final qty  = r['cantidad'] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        const Icon(Icons.circle, size: 6, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Text('$desc  ×$qty', style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                      ]),
                    );
                  }),
                ]),
              ),
            ],
            if (observaciones != null && observaciones.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Observaciones:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                  const SizedBox(height: 6),
                  Text(observaciones, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                ]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  const _TipoBadge(this.tipo);
  final String tipo;

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (tipo.toLowerCase()) {
      case 'alta':  bg = AppColors.danger; break;
      case 'media': bg = const Color(0xFFF59E0B); break;
      default:      bg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(tipo, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: bg)),
    );
  }
}
