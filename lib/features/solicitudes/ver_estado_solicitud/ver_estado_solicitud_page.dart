import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/emergencia_service.dart';
import 'package:taller_movil/services/api_helper.dart';

/// CU10 – Ver estado de solicitud (mis incidentes, taller, ETA, actualización periódica).
class VerEstadoSolicitudPage extends StatefulWidget {
  const VerEstadoSolicitudPage({super.key});

  @override
  State<VerEstadoSolicitudPage> createState() => _VerEstadoSolicitudPageState();
}

class _VerEstadoSolicitudPageState extends State<VerEstadoSolicitudPage> {
  final _svc = EmergenciaService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _error = '';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _cargar();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso && mounted) {
      setState(() { _loading = true; _error = ''; });
    }
    try {
      final data = await _svc.listarMisSolicitudes();
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
        _error = '';
      });
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _labelIncidente(String? e) {
    const m = {
      'pendiente': 'Pendiente',
      'en_proceso': 'En proceso',
      'resuelto': 'Atendido',
      'cancelado': 'Cancelado',
    };
    return m[e] ?? (e ?? '—');
  }

  String _labelAsignacion(String? e) {
    const m = {
      'aceptado': 'Aceptado',
      'en_camino': 'En camino',
      'en_sitio': 'En sitio',
      'en_reparacion': 'En reparación',
      'finalizado': 'Finalizado',
      'cancelado': 'Cancelado',
    };
    return m[e] ?? (e ?? '—');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Mis solicitudes', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _cargar(),
          ),
        ],
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error.isNotEmpty && _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_error, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: () => _cargar(), child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Text('No tienes solicitudes registradas.',
                          style: TextStyle(color: Color(0xFF6B7280))),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _cargar(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final row = _items[i];
                          final inc = row['incidente'] as Map<String, dynamic>? ?? {};
                          final asig = row['asignacion'] as Map<String, dynamic>?;
                          final fotos = (row['fotos_urls'] as List<dynamic>?)?.cast<String>() ?? [];
                          final id = inc['id'] as int? ?? 0;
                          final est = inc['estado'] as String? ?? '';
                          final pri = inc['prioridad'] as String? ?? '';
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Solicitud #$id',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text)),
                                const SizedBox(height: 8),
                                _RowInfo(icon: Icons.flag_outlined, text: 'Estado: ${_labelIncidente(est)}'),
                                _RowInfo(icon: Icons.priority_high, text: 'Prioridad: $pri'),
                                if (asig != null) ...[
                                  const SizedBox(height: 6),
                                  _RowInfo(
                                    icon: Icons.build_outlined,
                                    text: 'Taller: ${asig['taller_nombre'] ?? '—'}',
                                  ),
                                  _RowInfo(
                                    icon: Icons.local_shipping_outlined,
                                    text: 'Servicio: ${_labelAsignacion(asig['estado'] as String?)}',
                                  ),
                                  if (asig['eta'] != null)
                                    _RowInfo(
                                      icon: Icons.schedule,
                                      text: 'ETA: ${asig['eta']} min',
                                    ),
                                ] else
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Aún no hay taller asignado.',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                    ),
                                  ),
                                if ((inc['descripcion'] as String?)?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    inc['descripcion'] as String,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                                  ),
                                ],
                                if (fotos.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text('Evidencias',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 72,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: fotos.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemBuilder: (_, j) {
                                        final u = fotos[j];
                                        final full = u.startsWith('http')
                                            ? u
                                            : '${EmergenciaService.apiOrigin}${u.startsWith('/') ? '' : '/'}$u';
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(full, width: 96, height: 72, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                    width: 96,
                                                    height: 72,
                                                    color: const Color(0xFFF3F4F6),
                                                    child: const Icon(Icons.broken_image_outlined),
                                                  )),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  const _RowInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ),
        ],
      ),
    );
  }
}
