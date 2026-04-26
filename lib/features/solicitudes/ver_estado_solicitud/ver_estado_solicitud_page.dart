import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/emergencia_service.dart';
import 'package:taller_movil/services/api_helper.dart';
import 'package:taller_movil/features/solicitudes/ver_estado_solicitud/ver_estado_solicitud_detalle_page.dart';

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
  String _estadoFiltro = 'todos';
  int _page = 1;
  static const int _pageSize = 4;

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
        _page = 1;
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

  Color _estadoColorBg(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFFFFBEB);
      case 'en_proceso':
        return const Color(0xFFEFF6FF);
      case 'resuelto':
        return const Color(0xFFECFDF5);
      case 'cancelado':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _estadoColorText(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFB45309);
      case 'en_proceso':
        return const Color(0xFF1D4ED8);
      case 'resuelto':
        return const Color(0xFF047857);
      case 'cancelado':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF6B7280);
    }
  }

  int _pasoDesdeAsignacion(String? asigEstado, String incEstado) {
    final a = (asigEstado ?? '').toLowerCase();
    if (a == 'finalizado' || incEstado == 'resuelto') return 3;
    if (a == 'en_camino' || a == 'en_sitio' || a == 'en_reparacion' || incEstado == 'en_proceso') return 2;
    return 1;
  }

  DateTime _createdAt(Map<String, dynamic> row) {
    final inc = row['incidente'] as Map<String, dynamic>? ?? {};
    final raw = inc['created_at']?.toString();
    return DateTime.tryParse(raw ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<Map<String, dynamic>> _filtrarOrdenar() {
    final base = _items.where((row) {
      final inc = row['incidente'] as Map<String, dynamic>? ?? {};
      final estado = (inc['estado'] as String?) ?? '';
      // Excluir canceladas por el cliente (estado cancelado)
      if (estado == 'cancelado') return false;
      if (_estadoFiltro == 'todos') return true;
      return estado == _estadoFiltro;
    }).toList()
      ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
    return base;
  }

  int get _totalPages {
    final total = _filtrarOrdenar().length;
    return (total / _pageSize).ceil().clamp(1, 9999);
  }

  List<Map<String, dynamic>> _pageItems() {
    final rows = _filtrarOrdenar();
    final total = rows.length;
    final start = (_page - 1) * _pageSize;
    if (start >= total) return [];
    final end = (start + _pageSize).clamp(0, total);
    return rows.sublist(start, end);
  }

  void _setPage(int p) {
    final maxP = _totalPages;
    final next = p.clamp(1, maxP);
    setState(() => _page = next);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _pageItems();
    final totalPages = _totalPages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Ver estado de solicitud', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  : _filtrarOrdenar().isEmpty
                  ? const Center(
                      child: Text(
                        'No tienes solicitudes activas recientes.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _cargar(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _FiltrosEstado(
                            value: _estadoFiltro,
                            onChanged: (v) => setState(() {
                              _estadoFiltro = v;
                              _page = 1;
                            }),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(rows.length, (i) {
                          final row = rows[i];
                          final inc = row['incidente'] as Map<String, dynamic>? ?? {};
                          final asig = row['asignacion'] as Map<String, dynamic>?;
                          final id = inc['id'] as int? ?? 0;
                          final estado = (inc['estado'] as String?) ?? '';
                          final paso = _pasoDesdeAsignacion(asig?['estado']?.toString(), estado);
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VerEstadoSolicitudDetallePage(item: row),
                                ),
                              );
                              if (mounted) _cargar(silencioso: true);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '#EMG-${id.toString().padLeft(3, '0')}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _estadoColorBg(estado),
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                        child: Text(
                                          _labelIncidente(estado),
                                          style: TextStyle(
                                            color: _estadoColorText(estado),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _StepStatusRow(step: paso),
                                  const SizedBox(height: 12),
                                  Text(
                                    asig?['taller_nombre']?.toString() ?? 'Sin taller asignado',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Toca para ver el detalle',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                          );
                          }).expand((w) => [w, const SizedBox(height: 12)]).toList()
                            ..removeLast(),
                          const SizedBox(height: 8),
                          _PaginationFooter(
                            page: _page,
                            totalPages: totalPages,
                            onPage: _setPage,
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _FiltrosEstado extends StatelessWidget {
  const _FiltrosEstado({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String v, String label) => ChoiceChip(
          selected: value == v,
          label: Text(label),
          onSelected: (_) => onChanged(v),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('todos', 'Todos'),
        chip('pendiente', 'Pendiente'),
        chip('en_proceso', 'En proceso'),
        chip('resuelto', 'Finalizado'),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.page,
    required this.totalPages,
    required this.onPage,
  });
  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;

  List<int> _visiblePages() {
    if (totalPages <= 7) return List.generate(totalPages, (i) => i + 1);
    final set = <int>{1, 2, totalPages - 1, totalPages, page - 1, page, page + 1};
    final pages = set.where((p) => p >= 1 && p <= totalPages).toList()..sort();
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _visiblePages();
    final buttons = <Widget>[];

    void addEllipsis() {
      buttons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('…', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
      ));
    }

    int? prev;
    for (final p in pages) {
      if (prev != null && p - prev > 1) addEllipsis();
      buttons.add(_PageBtn(
        label: '$p',
        selected: p == page,
        onTap: () => onPage(p),
      ));
      prev = p;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _PageBtn(
            label: '‹',
            selected: false,
            onTap: page <= 1 ? null : () => onPage(page - 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: buttons),
            ),
          ),
          const SizedBox(width: 8),
          _PageBtn(
            label: '›',
            selected: false,
            onTap: page >= totalPages ? null : () => onPage(page + 1),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(color: selected ? AppColors.primary : const Color(0xFFE5E7EB)),
          backgroundColor: selected ? const Color(0xFFEFF6FF) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.primary : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _StepStatusRow extends StatelessWidget {
  const _StepStatusRow({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    Widget circle(int n, String label) {
      final done = n < step;
      final current = n == step;
      return Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? const Color(0xFF10B981) : (current ? AppColors.primary : const Color(0xFFE5E7EB)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$n',
                      style: TextStyle(
                        color: current ? Colors.white : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      );
    }

    Widget divider(int idx) {
      final active = idx < step;
      return Expanded(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 2,
          color: active ? AppColors.primary : const Color(0xFFD1D5DB),
        ),
      );
    }

    return Row(
      children: [
        circle(1, 'Solicitado'),
        divider(1),
        circle(2, 'En camino'),
        divider(2),
        circle(3, 'Finalizado'),
      ],
    );
  }
}
