import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';

// CU03 - Registrar Vehículo
class RegistrarVehiculoPage extends StatefulWidget {
  const RegistrarVehiculoPage({super.key});

  @override
  State<RegistrarVehiculoPage> createState() => _RegistrarVehiculoPageState();
}

class _RegistrarVehiculoPageState extends State<RegistrarVehiculoPage> {
  final _formKey     = GlobalKey<FormState>();
  final _placaCtrl   = TextEditingController();
  final _modeloCtrl  = TextEditingController();
  final _authService = AuthService();

  static const _baseUrl = 'http://10.0.2.2:8000/api/acceso';

  static const _marcas = [
    'Toyota', 'Hyundai', 'Chevrolet', 'Nissan', 'Ford',
    'Honda', 'Kia', 'Volkswagen', 'Mazda', 'Suzuki', 'Otro',
  ];
  static const _colores = [
    'Blanco', 'Negro', 'Gris', 'Plata', 'Rojo',
    'Azul', 'Verde', 'Amarillo', 'Naranja', 'Café',
  ];

  String? _marcaSel;
  String? _colorSel;
  int _anio = DateTime.now().year;
  bool _loading = false;
  String _serverError = '';

  @override
  void dispose() {
    _placaCtrl.dispose();
    _modeloCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _serverError = ''; });

    try {
      final token = await _authService.getToken();
      final res = await http.post(
        Uri.parse('$_baseUrl/vehiculos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'placa':  _placaCtrl.text.trim().toUpperCase(),
          'marca':  _marcaSel,
          'modelo': _modeloCtrl.text.trim(),
          'anio':   _anio,
          'color':  _colorSel,
        }),
      );

      if (res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehículo registrado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final err = jsonDecode(res.body);
        setState(() => _serverError = err['detail'] ?? 'Error al registrar vehículo');
      }
    } catch (e) {
      setState(() => _serverError = 'Error de conexión');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          'Registrar Vehículo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_car, color: AppColors.primary, size: 28),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CU03 — Registrar Vehículo',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Agrega un vehículo a tu cuenta',
                          style: TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                      ],
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
                    // Placa
                    _FieldLabel(text: 'Placa *'),
                    TextFormField(
                      controller: _placaCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDec('ABC-1234'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo requerido';
                        if (v.length < 5 || v.length > 8) return 'Entre 5 y 8 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Marca
                    _FieldLabel(text: 'Marca *'),
                    DropdownButtonFormField<String>(
                      value: _marcaSel,
                      decoration: _inputDec('Selecciona marca'),
                      items: _marcas
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _marcaSel = v),
                      validator: (v) => v == null ? 'Selecciona una marca' : null,
                    ),
                    const SizedBox(height: 16),

                    // Modelo
                    _FieldLabel(text: 'Modelo *'),
                    TextFormField(
                      controller: _modeloCtrl,
                      decoration: _inputDec('Corolla, Spark...'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    // Año
                    _FieldLabel(text: 'Año *'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_anio > 1990) setState(() => _anio--);
                          },
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.primary),
                        ),
                        Expanded(
                          child: Text(
                            '$_anio',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_anio < DateTime.now().year + 1) {
                              setState(() => _anio++);
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Color
                    _FieldLabel(text: 'Color *'),
                    DropdownButtonFormField<String>(
                      value: _colorSel,
                      decoration: _inputDec('Selecciona color'),
                      items: _colores
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _colorSel = v),
                      validator: (v) => v == null ? 'Selecciona un color' : null,
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
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Registrar Vehículo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
