import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/emergencia_service.dart';

// CU06 - Enviar Ubicación GPS
class EnviarUbicacionPage extends StatefulWidget {
  final int incidenteId;

  const EnviarUbicacionPage({super.key, required this.incidenteId});

  @override
  State<EnviarUbicacionPage> createState() => _EnviarUbicacionPageState();
}

class _EnviarUbicacionPageState extends State<EnviarUbicacionPage> {
  final _emergService = EmergenciaService();

  double? _latitud;
  double? _longitud;
  String _preciscion = '';

  bool _obteniendo = false;
  bool _enviando   = false;
  bool _exito      = false;
  String _errorGps    = '';
  String _errorServer = '';

  Future<void> _obtenerUbicacion() async {
    setState(() { _obteniendo = true; _errorGps = ''; });

    try {
      // Verificar si el servicio de ubicación está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorGps = 'El GPS está desactivado. Actívalo en los ajustes.';
          _obteniendo = false;
        });
        return;
      }

      // Verificar / solicitar permisos
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          setState(() {
            _errorGps = 'Permiso de ubicación denegado.';
            _obteniendo = false;
          });
          return;
        }
      }
      if (permiso == LocationPermission.deniedForever) {
        setState(() {
          _errorGps = 'Permiso denegado permanentemente. '
              'Habilítalo en los ajustes del dispositivo.';
          _obteniendo = false;
        });
        return;
      }

      // Obtener posición
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _latitud   = pos.latitude;
        _longitud  = pos.longitude;
        _preciscion = '±${pos.accuracy.toStringAsFixed(0)} m';
        _obteniendo = false;
      });
    } catch (e) {
      setState(() {
        _errorGps = 'No se pudo obtener la ubicación. Intenta de nuevo.';
        _obteniendo = false;
      });
    }
  }

  Future<void> _enviar() async {
    if (_latitud == null || _longitud == null) return;
    setState(() { _enviando = true; _errorServer = ''; });
    try {
      await _emergService.enviarUbicacion(
        incidenteId: widget.incidenteId,
        latitud: _latitud!,
        longitud: _longitud!,
      );
      setState(() { _exito = true; _enviando = false; });
    } catch (e) {
      setState(() {
        _errorServer = e.toString().replaceFirst('Exception: ', '');
        _enviando = false;
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
        elevation: 0,
        title: const Text(
          'Enviar Ubicación GPS',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _exito ? _buildExito() : _buildContenido(),
    );
  }

  // ── Pantalla de éxito ──────────────────────────────────────
  Widget _buildExito() {
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
              child: const Icon(Icons.location_on,
                  color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Ubicación enviada!',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 10),
            Text(
              'Incidente #${widget.incidenteId}\nLat: ${_latitud!.toStringAsFixed(6)}\nLng: ${_longitud!.toStringAsFixed(6)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.grey, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Volver',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Contenido principal ────────────────────────────────────
  Widget _buildContenido() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Encabezado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CU06 — Enviar Ubicación GPS',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Incidente #${widget.incidenteId}',
                        style: const TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tarjeta de ubicación
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

                // Visualización de coordenadas
                if (_latitud == null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.location_searching,
                            size: 40, color: AppColors.grey),
                        SizedBox(height: 10),
                        Text(
                          'Ubicación no obtenida',
                          style: TextStyle(color: AppColors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Presiona el botón para obtener tu posición',
                          style: TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.location_on,
                            size: 36, color: AppColors.success),
                        const SizedBox(height: 8),
                        const Text(
                          'Ubicación obtenida',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CoordRow(
                            label: 'Latitud',
                            value: _latitud!.toStringAsFixed(7)),
                        const SizedBox(height: 6),
                        _CoordRow(
                            label: 'Longitud',
                            value: _longitud!.toStringAsFixed(7)),
                        if (_preciscion.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _CoordRow(label: 'Precisión', value: _preciscion),
                        ],
                      ],
                    ),
                  ),

                // Error GPS
                if (_errorGps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorGps,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Botón obtener GPS
                OutlinedButton.icon(
                  onPressed: _obteniendo ? null : _obtenerUbicacion,
                  icon: _obteniendo
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _obteniendo
                        ? 'Obteniendo ubicación...'
                        : (_latitud != null
                            ? 'Actualizar ubicación'
                            : 'Obtener mi ubicación'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                // Error servidor
                if (_errorServer.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorServer,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 16),

                // Botón enviar
                ElevatedButton.icon(
                  onPressed: (_latitud == null || _enviando) ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _enviando ? 'Enviando...' : 'Enviar ubicación',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Tu ubicación solo se comparte con el taller asignado y se usa exclusivamente para coordinar la asistencia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                fontFamily: 'monospace')),
      ],
    );
  }
}
