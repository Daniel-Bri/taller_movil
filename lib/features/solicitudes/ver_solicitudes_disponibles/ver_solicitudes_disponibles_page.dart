import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/solicitud_taller_service.dart';
import 'package:taller_movil/services/api_helper.dart';

/// CU13 – Listar disponibles · CU15 – Aceptar (crea asignación).
class VerSolicitudesDisponiblesPage extends StatefulWidget {
  const VerSolicitudesDisponiblesPage({super.key});

  @override
  State<VerSolicitudesDisponiblesPage> createState() => _VerSolicitudesDisponiblesPageState();
}

class _VerSolicitudesDisponiblesPageState extends State<VerSolicitudesDisponiblesPage> {
  final _svc = SolicitudTallerService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _error = '';
  int? _aceptandoId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await _svc.listarDisponibles();
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
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _aceptar(Map<String, dynamic> row) async {
    final id = row['incidente_id'] as int;
    final etaCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aceptar solicitud #$id'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Opcional: ETA en minutos para llegar al lugar.'),
            const SizedBox(height: 12),
            TextField(
              controller: etaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ETA (min)',
                hintText: 'Ej. 30',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      etaCtrl.dispose();
      return;
    }

    int? eta;
    final t = etaCtrl.text.trim();
    if (t.isNotEmpty) eta = int.tryParse(t);
    etaCtrl.dispose();

    setState(() => _aceptandoId = id);
    try {
      await _svc.aceptar(id, etaMinutos: eta);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud aceptada'), backgroundColor: AppColors.success),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _aceptandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Solicitudes disponibles', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? const Center(child: Text('No hay solicitudes disponibles.', style: TextStyle(color: Color(0xFF6B7280))))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final s = _items[i];
                        final id = s['incidente_id'] as int;
                        final tipo = s['tipo_problema'] as String? ?? '';
                        final pri = s['prioridad'] as String? ?? '';
                        final nFotos = (s['fotos_urls'] as List<dynamic>?)?.length ?? 0;
                        final busy = _aceptandoId == id;
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('#$id', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(pri, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(tipo, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                                const SizedBox(height: 6),
                                Text(
                                  '${s['latitud']}, ${s['longitud']}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                                if (nFotos > 0)
                                  Text('$nFotos foto(s)', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: busy ? null : () => _aceptar(s),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: busy
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Aceptar solicitud'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
