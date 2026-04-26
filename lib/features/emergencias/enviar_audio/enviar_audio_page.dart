import 'dart:typed_data';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/api_helper.dart';
import 'package:taller_movil/services/emergencia_service.dart';

// CU08 - Enviar Audio
class EnviarAudioPage extends StatefulWidget {
  const EnviarAudioPage({super.key, required this.incidenteId});
  final int incidenteId;

  @override
  State<EnviarAudioPage> createState() => _EnviarAudioPageState();
}

class _EnviarAudioPageState extends State<EnviarAudioPage> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _svc = EmergenciaService();

  String? _audioPath;
  Uint8List? _audioBytes;
  bool _grabando = false;
  bool _subiendo = false;
  bool _reproduciendo = false;
  String _error = '';
  Duration _duracion = Duration.zero;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _iniciarGrabacion() async {
    setState(() => _error = '');
    final ok = await _recorder.hasPermission();
    if (!ok) {
      setState(() => _error = 'Permiso de micrófono denegado');
      return;
    }
    if (kIsWeb) {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: 'recording_${widget.incidenteId}.webm',
      );
    } else {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/incidente_${widget.incidenteId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: path,
      );
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duracion = Duration(seconds: _duracion.inSeconds + 1));
    });
    setState(() {
      _grabando = true;
      _audioPath = null;
      _audioBytes = null;
      _duracion = Duration.zero;
    });
  }

  Future<void> _detenerGrabacion() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    if (!kIsWeb && path == null) {
      setState(() {
        _grabando = false;
        _error = 'Error al finalizar grabación';
      });
      return;
    }
    Uint8List bytes;
    String? localPath = path;
    if (kIsWeb) {
      if (path == null || !path.startsWith('blob:')) {
        setState(() {
          _grabando = false;
          _error = 'No se pudo obtener el audio grabado.';
        });
        return;
      }
      final res = await http.get(Uri.parse(path));
      if (res.statusCode >= 400 || res.bodyBytes.isEmpty) {
        setState(() {
          _grabando = false;
          _error = 'No se capturó audio. Intenta nuevamente.';
        });
        return;
      }
      bytes = res.bodyBytes;
      localPath = path;
    } else {
      bytes = await XFile(path!).readAsBytes();
    }
    setState(() {
      _grabando = false;
      _audioPath = localPath;
      _audioBytes = bytes;
    });
  }

  String get _duracionFmt {
    final m = _duracion.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _duracion.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _reproducirPreview() async {
    if (_audioPath == null && _audioBytes == null) return;
    await _player.stop();
    Source source;
    if (_audioPath != null) {
      source = _audioPath!.startsWith('http') || _audioPath!.startsWith('blob:')
          ? UrlSource(_audioPath!)
          : DeviceFileSource(_audioPath!);
    } else {
      source = BytesSource(_audioBytes!);
    }
    await _player.play(source);
    setState(() => _reproduciendo = true);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _reproduciendo = false);
    });
  }

  Future<void> _detenerPreview() async {
    await _player.stop();
    setState(() => _reproduciendo = false);
  }

  Future<void> _subir() async {
    final bytes = _audioBytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _error = 'Audio corrupto o vacío');
      return;
    }
    setState(() {
      _subiendo = true;
      _error = '';
    });
    try {
      final filename = kIsWeb
          ? 'incidente_${widget.incidenteId}.webm'
          : 'incidente_${widget.incidenteId}.m4a';
      final mimeType = kIsWeb ? 'audio/webm' : 'audio/mp4';
      await _svc.subirAudio(
        incidenteId: widget.incidenteId,
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
        duracionSegundos: _duracion.inSeconds > 0 ? _duracion.inSeconds : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio enviado'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      if (e is TokenExpiradoException) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Enviar audio', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: _grabando ? const Color(0xFF5E89D9) : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                _grabando ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _duracionFmt,
              style: const TextStyle(
                fontSize: 62,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5E89D9),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            _WaveBars(active: _grabando || _audioPath != null),
            const SizedBox(height: 28),
            if (_grabando)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _subiendo ? null : _detenerGrabacion,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Detener'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA1D25),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else if (_audioPath == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _subiendo ? null : _iniciarGrabacion,
                  icon: const Icon(Icons.mic_none_rounded),
                  label: const Text('Grabar audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _reproduciendo ? _detenerPreview : _reproducirPreview,
                  icon: Icon(_reproduciendo ? Icons.stop : Icons.play_arrow_rounded),
                  label: Text(_reproduciendo ? 'Detener audio' : 'Reproducir audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E89D9),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_subiendo || _audioPath == null) ? null : _subir,
                  icon: _subiendo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_subiendo ? 'Enviando...' : 'Enviar audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _audioPath = null;
                  _audioBytes = null;
                  _duracion = Duration.zero;
                }),
                child: const Text('Descartar audio'),
              ),
            ],
            const SizedBox(height: 22),
            Text(
              _grabando
                  ? 'Grabando... Describe el problema con tu vehículo'
                  : (_audioPath != null
                      ? 'Audio listo para enviar'
                      : 'Presiona el botón para iniciar la grabación'),
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 24),
              textAlign: TextAlign.center,
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(_error, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
    );
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bars = [30, 46, 24, 55, 34, 28, 40, 48, 43, 45, 56, 41, 19, 23, 22, 36, 46, 20, 24, 32, 43, 52, 39, 29, 47, 19, 37, 45, 30, 53, 40, 48, 42, 18, 24, 42, 31, 27, 40, 29, 46, 21, 33, 23, 26, 44];
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: bars
            .map(
              (h) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: active ? h.toDouble() : 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF6F95DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
