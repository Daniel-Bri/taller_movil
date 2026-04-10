import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';

// Acceso y Registro
import 'package:taller_movil/features/acceso_registro/iniciar_sesion/iniciar_sesion_page.dart';
import 'package:taller_movil/features/acceso_registro/registrarse/registrarse_page.dart';
import 'package:taller_movil/features/acceso_registro/registrar_vehiculo/registrar_vehiculo_page.dart';
import 'package:taller_movil/features/acceso_registro/gestionar_vehiculos/gestionar_vehiculos_page.dart';
import 'package:taller_movil/features/acceso_registro/registrar_taller/registrar_taller_page.dart';
import 'package:taller_movil/features/dashboard/dashboard_page.dart';
import 'package:taller_movil/features/emergencias/reportar_emergencia/reportar_emergencia_page.dart';

void main() {
  runApp(const RutaSegura());
}

class RutaSegura extends StatelessWidget {
  const RutaSegura({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RutaSegura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
      routes: {
        '/login':                   (_) => const IniciarSesionPage(),
        '/registro':                (_) => const RegistrarsePage(),
        '/dashboard':               (_) => const DashboardPage(),
        '/acceso/registrar-vehiculo': (_) => const RegistrarVehiculoPage(),
        '/acceso/mis-vehiculos':    (_) => const GestionarVehiculosPage(),
        '/acceso/registrar-taller':    (_) => const RegistrarTallerPage(),
        '/emergencias/reportar':       (_) => const ReportarEmergenciaPage(),
      },
    );
  }
}

// ── Splash Router ────────────────────────────────────────────
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        return snapshot.data! ? const DashboardPage() : const IniciarSesionPage();
      },
    );
  }
}
