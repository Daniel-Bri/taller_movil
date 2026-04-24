import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taller_movil/core/theme/app_colors.dart';
import 'package:taller_movil/services/auth_service.dart';
import 'package:taller_movil/services/comunicacion_service.dart';

class ChatArgs {
  final int asignacionId;
  final String nombreContacto;
  const ChatArgs({required this.asignacionId, required this.nombreContacto});
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _svc    = ComunicacionService();
  final _auth   = AuthService();
  final _inputCtrl     = TextEditingController();
  final _scrollCtrl    = ScrollController();

  ChatArgs? _args;
  int? _myUserId;
  List<MensajeModel> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ChatArgs) {
        _args = args;
        _init();
      }
    }
  }

  Future<void> _init() async {
    final user = await _auth.getUser();
    _myUserId = user?['id'] as int?;
    await _cargarMensajes();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMensajes());
  }

  Future<void> _cargarMensajes() async {
    if (_args == null) return;
    try {
      final msgs = await _svc.listarMensajes(_args!.asignacionId);
      if (mounted) {
        setState(() {
          _mensajes = msgs;
          _cargando = false;
          _error = null;
        });
        _scrollAlFinal();
      }
    } catch (e) {
      if (mounted) setState(() { _cargando = false; _error = e.toString(); });
    }
  }

  Future<void> _pollMensajes() async {
    if (_args == null || !mounted) return;
    try {
      final msgs = await _svc.listarMensajes(_args!.asignacionId);
      if (mounted && msgs.length != _mensajes.length) {
        setState(() => _mensajes = msgs);
        _scrollAlFinal();
      }
    } catch (_) {}
  }

  Future<void> _enviar() async {
    final texto = _inputCtrl.text.trim();
    if (texto.isEmpty || _args == null || _enviando) return;
    setState(() => _enviando = true);
    try {
      final msg = await _svc.enviarMensaje(
        asignacionId: _args!.asignacionId,
        contenido: texto,
      );
      if (mounted) {
        setState(() {
          _mensajes = [..._mensajes, msg];
          _enviando = false;
        });
        _inputCtrl.clear();
        _scrollAlFinal();
      }
    } catch (_) {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool _esMio(MensajeModel m) => m.usuarioId == _myUserId;

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _args != null ? _args!.nombreContacto : 'Chat';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
            if (_args != null)
              Text('Asignación #${_args!.asignacionId}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
      body: _args == null ? _buildNoArgs() : _buildChat(),
    );
  }

  Widget _buildNoArgs() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Sin servicio activo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 6),
            const Text(
              'El chat está disponible cuando tienes un servicio activo asignado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        // Error banner
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFEF2F2),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ),

        // Mensajes
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _mensajes.isEmpty
                  ? const Center(
                      child: Text('Sin mensajes aún. ¡Escribe el primero!',
                        style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _mensajes.length,
                      itemBuilder: (_, i) => _buildBubble(_mensajes[i]),
                    ),
        ),

        // Input bar
        _buildInputBar(),
      ],
    );
  }

  Widget _buildBubble(MensajeModel m) {
    final mio = _esMio(m);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mio) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                m.remitente.isNotEmpty ? m.remitente[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: mio ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(mio ? 14 : 4),
                  bottomRight: Radius.circular(mio ? 4 : 14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!mio) ...[
                    Text('${m.remitente} · ${_rolLabel(m.rol)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    const SizedBox(height: 2),
                  ],
                  Text(m.contenido,
                    style: TextStyle(
                      fontSize: 14,
                      color: mio ? Colors.white : AppColors.text,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_formatTime(m.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: mio ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (mio) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              maxLines: null,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje…',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
              onSubmitted: (_) => _enviar(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _rolLabel(String rol) {
    const map = {'taller': 'Taller', 'tecnico': 'Técnico', 'cliente': 'Cliente', 'admin': 'Admin'};
    return map[rol] ?? rol;
  }
}
