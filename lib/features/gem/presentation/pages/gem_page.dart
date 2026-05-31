import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/services/gemini_service.dart';

/// Tab 5 — GEM (Coach IA powered by Gemini)
class GemPage extends StatefulWidget {
  const GemPage({super.key});

  @override
  State<GemPage> createState() => _GemPageState();
}

class _GemPageState extends State<GemPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GeminiService _gemini = GetIt.instance<GeminiService>();
  bool _cargando = false;

  final List<_Mensaje> _mensajes = [
    _Mensaje(
      texto: '¡Hola! Soy GEM, tu coach keto 🥑\n\n'
          'Puedo ayudarte con dudas sobre la dieta, recetas fáciles, síntomas de adaptación y tu lista del súper.\n\n'
          '¿En qué te ayudo hoy?',
      esGem: true,
    ),
  ];

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _cargando) return;

    setState(() {
      _mensajes.add(_Mensaje(texto: texto, esGem: false));
      _cargando = true;
      _ctrl.clear();
    });
    _scrollAlFinal();

    final respuesta = await _gemini.enviarMensaje(texto);

    if (!mounted) return;
    setState(() {
      _mensajes.add(_Mensaje(texto: respuesta, esGem: true));
      _cargando = false;
    });
    _scrollAlFinal();
  }

  Future<void> _enviarTexto(String texto) async {
    _ctrl.text = texto;
    await _enviar();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.negro,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            Image.asset('assets/images/logo_icono.png', height: 48, fit: BoxFit.contain),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GEM',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.verdeMedio, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('Coach IA · en línea',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8FAF8F), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8FAF8F)),
            onPressed: () {
              setState(() {
                _gemini.reiniciarChat();
                _mensajes.clear();
                _mensajes.add(_Mensaje(
                  texto: '¡Chat reiniciado! ¿En qué te ayudo? 🥑',
                  esGem: true,
                ));
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Shortcuts ────────────────────────────────────
          Container(
            color: Colors.black,
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _ShortcutChip(label: '🍳 Recetas',    query: 'Dame una receta keto fácil para hoy',      onTap: _enviarTexto),
                  _ShortcutChip(label: '🛒 Súper',      query: 'Arma mi lista del súper keto para la semana', onTap: _enviarTexto),
                  _ShortcutChip(label: '😴 Keto gripe', query: 'Tengo dolor de cabeza, ¿es la keto gripe?', onTap: _enviarTexto),
                  _ShortcutChip(label: '⚡ Electrolitos', query: '¿Cómo y cuándo tomo los electrolitos en keto?', onTap: _enviarTexto),
                  _ShortcutChip(label: '🏋️ Ejercicio',  query: 'Qué ejercicios me recomiendas siendo principiante keto', onTap: _enviarTexto),
                ],
              ),
            ),
          ),

          // ── Chat ─────────────────────────────────────────
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollStartNotification) {
                  FocusScope.of(context).unfocus();
                }
                return false;
              },
              child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              itemCount: _mensajes.length + (_cargando ? 1 : 0),
              itemBuilder: (context, i) {
                if (_cargando && i == _mensajes.length) {
                  return const _BurbujaTyping();
                }
                return _BurbujaMensaje(mensaje: _mensajes[i]);
              },
            ),
            ),
          ),

          // ── Input ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D1510),
              border: Border(top: BorderSide(color: Color(0xFF1E3A1E), width: 1)),
            ),
            padding: EdgeInsets.only(
              left: 16, right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              top: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF182318),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFF2A3D2A)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Pregúntale a GEM...',
                        hintStyle: TextStyle(color: Color(0xFF4A6B4A), fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _enviar,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.verde, AppColors.verdeOs],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verde.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: AppColors.blanco, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Mensaje {
  final String texto;
  final bool esGem;
  const _Mensaje({required this.texto, required this.esGem});
}

class _BurbujaMensaje extends StatelessWidget {
  final _Mensaje mensaje;
  const _BurbujaMensaje({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esGem = mensaje.esGem;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: esGem ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (esGem) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.verde, AppColors.verdeOs],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.blanco, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: esGem ? const Color(0xFF1E2E1E) : AppColors.verde,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(esGem ? 4 : 20),
                  bottomRight: Radius.circular(esGem ? 20 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: esGem
                  ? MarkdownBody(
                      data: mensaje.texto,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16, color: Colors.white, height: 1.6),
                        strong: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
                        em: const TextStyle(fontSize: 16, color: Colors.white, fontStyle: FontStyle.italic),
                        listBullet: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    )
                  : Text(
                      mensaje.texto,
                      style: const TextStyle(fontSize: 16, color: AppColors.blanco, height: 1.6),
                    ),
            ),
          ),
          if (!esGem) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.fondoGris,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _BurbujaTyping extends StatelessWidget {
  const _BurbujaTyping();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.verde, AppColors.verdeOs],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.blanco, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.blanco,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                SizedBox(width: 6),
                _Dot(delay: 200),
                SizedBox(width: 6),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10, height: 10,
        decoration: const BoxDecoration(
          color: AppColors.verde,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final String label;
  final String query;
  final Future<void> Function(String) onTap;
  const _ShortcutChip({required this.label, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTap(query),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.verdeOs,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
