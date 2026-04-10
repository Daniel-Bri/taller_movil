import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/emergencia_service.dart';
import 'package:taller_movil/services/api_helper.dart';

// CU06 - Enviar Ubicación GPS
class EnviarUbicacionPage extends StatefulWidget {
  final int incidenteId;
  const EnviarUbicacionPage({super.key, required this.incidenteId});

  @override
  State<EnviarUbicacionPage> createState() => _EnviarUbicacionPageState();
}

class _EnviarUbicacionPageState extends State<EnviarUbicacionPage> {
  final _formKey = GlobalKey<FormState>();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _service = EmergenciaService();

  bool _loadingGps  = false;
  bool _loading     = false;
  bool _enviado     = false;
  String _error     = '';

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  // ── Obtener ubicación del dispositivo ──────────────────────
  Future<void> _obtenerUbicacion() async {
    setState(() { _loadingGps = true; _error = ''; });

    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'El GPS está desactivado. Actívalo en Ajustes.';
          _loadingGps = false;
        });
        return;
      }

      // 2. Verificar/solicitar permiso
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Permiso de ubicación denegado.';
            _loadingGps = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Permiso denegado permanentemente. Habilítalo en Ajustes de la app.';
          _loadingGps = false;
        });
        return;
      }

      // 3. Obtener posición
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
        _loadingGps   = false;
      });
    } catch (e) {
      setState(() {
        _error      = 'No se pudo obtener la ubicación: ${e.toString()}';
        _loadingGps = false;
      });
    }
  }

  // ── Enviar al backend ──────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });
    try {
      await _service.actualizarUbicacion(
        incidenteId: widget.incidenteId,
        latitud:     double.parse(_latCtrl.text.trim()),
        longitud:    double.parse(_lngCtrl.text.trim()),
      );
      setState(() { _loading = false; _enviado = true; });
    } catch (e) {
      if (e is TokenExpiradoException) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Enviar Ubicación GPS',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        automaticallyImplyLeading: !_enviado,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _enviado
            ? _SuccessView(onDone: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false))
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del incidente
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Emergencia #${widget.incidenteId} creada. '
                'Presiona el botón GPS para detectar tu ubicación automáticamente.',
                style: const TextStyle(fontSize: 13, color: AppColors.primary),
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Botón GPS ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadingGps ? null : _obtenerUbicacion,
              icon: _loadingGps
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.my_location, color: AppColors.primary),
              label: Text(
                _loadingGps ? 'Obteniendo ubicación...' : 'Usar mi ubicación GPS',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Center(
            child: Text('— o ingresa manualmente —',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ),
          const SizedBox(height: 12),

          // ── Campos manuales ────────────────────────────────
          const _Label('Latitud *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _latCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: _inputDeco('Ej: -17.393500'),
            style: const TextStyle(fontSize: 14),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo requerido';
              if (double.tryParse(v.trim()) == null) return 'Número inválido';
              return null;
            },
          ),
          const SizedBox(height: 14),

          const _Label('Longitud *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _lngCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: _inputDeco('Ej: -66.156800'),
            style: const TextStyle(fontSize: 14),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Campo requerido';
              if (double.tryParse(v.trim()) == null) return 'Número inválido';
              return null;
            },
          ),
          const SizedBox(height: 24),

          if (_error.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(
                _loading ? 'Enviando...' : 'Enviar mi ubicación',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
      );
}

// ── Pantalla de éxito ─────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
                color: Color(0xFFECFDF5), shape: BoxShape.circle),
            child: const Icon(Icons.location_on, color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('¡Ubicación enviada!',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text(
            'Tu ubicación fue registrada.\nUn taller cercano recibirá tu solicitud pronto.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Volver al inicio',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text));
}
