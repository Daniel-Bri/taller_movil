import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';
import 'package:taller_movil/services/emergencia_service.dart';

// CU05 - Reportar Emergencia
class ReportarEmergenciaPage extends StatefulWidget {
  const ReportarEmergenciaPage({super.key});

  @override
  State<ReportarEmergenciaPage> createState() => _ReportarEmergenciaPageState();
}

class _ReportarEmergenciaPageState extends State<ReportarEmergenciaPage> {
  final _formKey       = GlobalKey<FormState>();
  final _descripCtrl   = TextEditingController();
  final _authService   = AuthService();
  final _emergService  = EmergenciaService();

  static const _baseUrl = 'http://10.0.2.2:8000/api/acceso';

  List<Map<String, dynamic>> _vehiculos = [];
  int? _vehiculoSelId;
  String _prioridad = 'media';

  bool _loadingVehiculos = true;
  bool _submitting = false;
  String _errorVehiculos = '';
  String _serverError = '';
  bool _exito = false;
  Map<String, dynamic>? _incidenteCreado;

  static const _prioridades = [
    {'value': 'alta',  'label': 'Alta',  'color': AppColors.danger},
    {'value': 'media', 'label': 'Media', 'color': Color(0xFFF59E0B)},
    {'value': 'baja',  'label': 'Baja',  'color': AppColors.success},
  ];

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  @override
  void dispose() {
    _descripCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarVehiculos() async {
    setState(() { _loadingVehiculos = true; _errorVehiculos = ''; });
    try {
      final token = await _authService.getToken();
      final res = await http.get(
        Uri.parse('$_baseUrl/vehiculos'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _vehiculos = list.cast<Map<String, dynamic>>();
          _loadingVehiculos = false;
        });
      } else {
        setState(() {
          _errorVehiculos = 'No se pudieron cargar los vehículos';
          _loadingVehiculos = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorVehiculos = 'Error de conexión';
        _loadingVehiculos = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _serverError = ''; });
    try {
      final incidente = await _emergService.reportar(
        vehiculoId: _vehiculoSelId!,
        descripcion: _descripCtrl.text.trim(),
        prioridad: _prioridad,
      );
      setState(() {
        _exito = true;
        _incidenteCreado = incidente;
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _serverError = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reportar Emergencia',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _exito ? _buildExito() : _buildForm(),
    );
  }

  // ── Pantalla de éxito ──────────────────────────────────────
  Widget _buildExito() {
    final id       = _incidenteCreado?['id'] ?? '-';
    final prioridad = _incidenteCreado?['prioridad'] ?? '-';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Emergencia reportada!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tu solicitud #$id fue registrada con prioridad $prioridad.\nUn taller te contactará pronto.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/enviar-ubicacion',
                  arguments: _incidenteCreado!['id'] as int,
                ),
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Enviar mi ubicación GPS',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/dashboard')),
                child: const Text('Volver al dashboard',
                    style: TextStyle(color: AppColors.grey, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formulario ─────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Banner de alerta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CU05 — Reportar Emergencia',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Completa los datos para solicitar asistencia en carretera',
                          style: TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tarjeta del formulario
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Vehículo
                  _FieldLabel(text: 'Vehículo afectado *'),
                  if (_loadingVehiculos)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(width: 10),
                          Text('Cargando vehículos...', style: TextStyle(color: AppColors.grey)),
                        ],
                      ),
                    )
                  else if (_errorVehiculos.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_errorVehiculos,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: _cargarVehiculos,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    )
                  else if (_vehiculos.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No tienes vehículos registrados. Registra uno primero.',
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/registrar-vehiculo'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Registrar vehículo'),
                        ),
                      ],
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: _vehiculoSelId,
                      decoration: _inputDec('Selecciona tu vehículo'),
                      items: _vehiculos
                          .map((v) => DropdownMenuItem<int>(
                                value: v['id'] as int,
                                child: Text(
                                  '${v['marca']} ${v['modelo']} · ${v['placa']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _vehiculoSelId = val),
                      validator: (v) => v == null ? 'Selecciona un vehículo' : null,
                    ),
                  const SizedBox(height: 20),

                  // Prioridad
                  _FieldLabel(text: 'Prioridad'),
                  Row(
                    children: _prioridades.map((p) {
                      final val   = p['value'] as String;
                      final label = p['label'] as String;
                      final color = p['color'] as Color;
                      final sel   = _prioridad == val;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _prioridad = val),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? color.withValues(alpha: 0.12) : Colors.transparent,
                              border: Border.all(
                                color: sel ? color : AppColors.border,
                                width: sel ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: sel ? color : AppColors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Descripción
                  _FieldLabel(text: 'Descripción del problema'),
                  TextFormField(
                    controller: _descripCtrl,
                    maxLines: 4,
                    decoration: _inputDec(
                        'Ej: El motor no enciende, tengo una llanta pinchada en la Av. Principal...'),
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cuanto más detalle des, más rápido podremos asignarte asistencia.',
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),

                  if (_serverError.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _serverError,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: (_submitting || _vehiculos.isEmpty) ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.warning_amber_rounded),
                    label: Text(
                      _submitting ? 'Enviando...' : 'Reportar Emergencia',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.45),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    );
  }
}
