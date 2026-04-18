import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/taller_service.dart';
import 'package:taller_movil/shared/app_drawer.dart';

class RegistrarServicioRealizadoPage extends StatefulWidget {
  const RegistrarServicioRealizadoPage({super.key});

  @override
  State<RegistrarServicioRealizadoPage> createState() =>
      _RegistrarServicioRealizadoPageState();
}

class _RegistrarServicioRealizadoPageState
    extends State<RegistrarServicioRealizadoPage>
    with SingleTickerProviderStateMixin {
  final _svc = TallerService();
  late TabController _tabController;

  // ── Pestaña "Pendientes" ────────────────────────────────
  List<AsignacionModel> _asignaciones = [];
  bool _loadingAsig = false;
  String? _errorAsig;

  // ── Pestaña "Historial" ─────────────────────────────────
  List<ServicioRealizadoModel> _historial = [];
  bool _loadingHist = false;
  bool _histCargado = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.index == 1 && !_histCargado) _cargarHistorial();
      });
    _cargarAsignaciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarAsignaciones() async {
    setState(() { _loadingAsig = true; _errorAsig = null; });
    try {
      final data = await _svc.listarAsignacionesListas();
      setState(() { _asignaciones = data; _loadingAsig = false; });
    } catch (e) {
      setState(() {
        _errorAsig = e.toString().replaceFirst('Exception: ', '');
        _loadingAsig = false;
      });
    }
  }

  Future<void> _cargarHistorial() async {
    setState(() { _loadingHist = true; });
    try {
      final data = await _svc.listarServiciosRealizados();
      setState(() { _historial = data; _histCargado = true; _loadingHist = false; });
    } catch (_) {
      setState(() { _loadingHist = false; });
    }
  }

  Future<void> _abrirFormulario(AsignacionModel a) async {
    final cerrado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _FormServicioPage(asignacion: a, svc: _svc)),
    );
    if (cerrado == true) {
      _cargarAsignaciones();
      _histCargado = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Servicio', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(color: AppColors.border, height: 1),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Listos para cerrar'),
                  Tab(text: 'Historial'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadingAsig ? null : _cargarAsignaciones,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPendientes(), _buildHistorial()],
      ),
    );
  }

  // ── Tab 1: Pendientes ────────────────────────────────────
  Widget _buildPendientes() {
    if (_loadingAsig) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_errorAsig != null) {
      return _ErrorWidget(msg: _errorAsig!, onRetry: _cargarAsignaciones);
    }
    if (_asignaciones.isEmpty) {
      return const _EmptyWidget(
        icon: Icons.build_circle_outlined,
        msg: 'No hay servicios en estado "En reparación".',
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarAsignaciones,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _asignaciones.length,
        itemBuilder: (_, i) => _AsignacionCard(
          asignacion: _asignaciones[i],
          onRegistrar: () => _abrirFormulario(_asignaciones[i]),
        ),
      ),
    );
  }

  // ── Tab 2: Historial ─────────────────────────────────────
  Widget _buildHistorial() {
    if (_loadingHist) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_historial.isEmpty) {
      return const _EmptyWidget(
        icon: Icons.history_outlined,
        msg: 'No hay servicios cerrados en el historial.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historial.length,
      itemBuilder: (_, i) => _HistorialCard(servicio: _historial[i]),
    );
  }
}

// ── Formulario de cierre (pantalla separada) ─────────────────
class _FormServicioPage extends StatefulWidget {
  const _FormServicioPage({required this.asignacion, required this.svc});
  final AsignacionModel asignacion;
  final TallerService svc;

  @override
  State<_FormServicioPage> createState() => _FormServicioPageState();
}

class _FormServicioPageState extends State<_FormServicioPage> {
  final _descCtrl = TextEditingController();
  final _obsCtrl  = TextEditingController();
  final List<Map<String, dynamic>> _repuestos = [];

  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _descCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _agregarRepuesto() {
    setState(() => _repuestos.add({'desc': TextEditingController(), 'cant': 1}));
  }

  void _eliminarRepuesto(int i) {
    (_repuestos[i]['desc'] as TextEditingController).dispose();
    setState(() => _repuestos.removeAt(i));
  }

  Future<void> _guardar() async {
    final desc = _descCtrl.text.trim();
    if (desc.length < 5) {
      setState(() => _error = 'La descripción debe tener al menos 5 caracteres');
      return;
    }
    setState(() { _guardando = true; _error = null; });

    final repuestos = _repuestos
        .map((r) => RepuestoItem(
              descripcion: (r['desc'] as TextEditingController).text.trim(),
              cantidad:    r['cant'] as int,
            ))
        .where((r) => r.descripcion.isNotEmpty && r.cantidad > 0)
        .toList();

    try {
      await widget.svc.registrarServicio(
        asignacionId:        widget.asignacion.id,
        descripcionTrabajo:  desc,
        repuestos:           repuestos.isNotEmpty ? repuestos : null,
        observaciones:       _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Servicio registrado y cerrado correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _error     = e.toString().replaceFirst('Exception: ', '');
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Cierre · Asignación #${widget.asignacion.id}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Incidente #${widget.asignacion.incidenteId}  ·  Asignación #${widget.asignacion.id}',
                style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
              )),
            ]),
          ),

          const SizedBox(height: 20),

          // Descripción
          _Label('Descripción del trabajo realizado *'),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: _inputDeco('Describe detalladamente el trabajo ejecutado, diagnóstico y solución aplicada...'),
          ),

          const SizedBox(height: 20),

          // Repuestos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Label('Repuestos / Materiales'),
              TextButton.icon(
                onPressed: _agregarRepuesto,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),

          if (_repuestos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Sin repuestos agregados.',
                  style: const TextStyle(fontSize: 13, color: AppColors.grey)),
            )
          else
            ...List.generate(_repuestos.length, (i) => _RepuestoRow(
              ctrl:   _repuestos[i]['desc'] as TextEditingController,
              cant:   _repuestos[i]['cant'] as int,
              onCant: (v) => setState(() => _repuestos[i]['cant'] = v),
              onDel:  () => _eliminarRepuesto(i),
            )),

          const SizedBox(height: 20),

          // Observaciones
          _Label('Observaciones finales (opcional)'),
          const SizedBox(height: 6),
          TextField(
            controller: _obsCtrl,
            maxLines: 2,
            decoration: _inputDeco('Ej. Se recomienda revisión de frenos en 3 meses...'),
          ),

          const SizedBox(height: 16),

          // Nota
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFBBF24)),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Al confirmar, la asignación pasará a "Finalizado" y el técnico quedará disponible.',
                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              )),
            ]),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.verified_outlined, size: 18),
              label: Text(_guardando ? 'Registrando...' : 'Confirmar cierre del servicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.all(12),
      );
}

// ── Widgets auxiliares ──────────────────────────────────────

class _AsignacionCard extends StatelessWidget {
  const _AsignacionCard({required this.asignacion, required this.onRegistrar});
  final AsignacionModel asignacion;
  final VoidCallback onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEA580C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.build_outlined, color: Color(0xFFEA580C), size: 22),
        ),
        title: Text('Asignación #${asignacion.id}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text('Incidente #${asignacion.incidenteId}  ·  En reparación',
              style: const TextStyle(fontSize: 12, color: AppColors.grey)),
        ),
        trailing: ElevatedButton(
          onPressed: onRegistrar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          child: const Text('Registrar'),
        ),
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  const _HistorialCard({required this.servicio});
  final ServicioRealizadoModel servicio;

  @override
  Widget build(BuildContext context) {
    final repuestos = servicio.repuestosParsed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Servicio #${servicio.id}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Finalizado',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Asignación #${servicio.asignacionId}',
            style: const TextStyle(fontSize: 11, color: AppColors.grey)),
        const SizedBox(height: 10),
        Text(servicio.descripcionTrabajo,
            style: const TextStyle(fontSize: 13, color: AppColors.text)),
        if (repuestos.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Repuestos:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey)),
          const SizedBox(height: 4),
          ...repuestos.map((r) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text('· ${r.descripcion} (x${r.cantidad})',
                    style: const TextStyle(fontSize: 12, color: AppColors.text)),
              )),
        ],
        if (servicio.observaciones != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.comment_outlined, size: 13, color: AppColors.grey),
            const SizedBox(width: 5),
            Expanded(child: Text(servicio.observaciones!,
                style: const TextStyle(fontSize: 12, color: AppColors.grey))),
          ]),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            servicio.fechaCierre.substring(0, 10),
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ),
      ]),
    );
  }
}

class _RepuestoRow extends StatelessWidget {
  const _RepuestoRow({required this.ctrl, required this.cant, required this.onCant, required this.onDel});
  final TextEditingController ctrl;
  final int cant;
  final void Function(int) onCant;
  final VoidCallback onDel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              hintText: 'Nombre del repuesto',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            controller: TextEditingController(text: cant.toString()),
            onChanged: (v) => onCant(int.tryParse(v) ?? 1),
            decoration: InputDecoration(
              hintText: 'Cant.',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
          onPressed: onDel,
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text));
}

class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget({required this.icon, required this.msg});
  final IconData icon;
  final String msg;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 52, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.grey)),
        ]),
      );
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.msg, required this.onRetry});
  final String msg;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 44),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
}
