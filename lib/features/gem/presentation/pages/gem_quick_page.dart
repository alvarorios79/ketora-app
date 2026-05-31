import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/services/gemini_service.dart';

/// Pantalla GEM de acción rápida — abre con un mensaje pre-enviado.
/// Se usa para /app/gem/recetas y /app/gem/supermercado.
class GemQuickPage extends StatefulWidget {
  final String titulo;
  final String emoji;
  final String mensajeInicial;
  final List<String> sugerencias;

  const GemQuickPage({
    super.key,
    required this.titulo,
    required this.emoji,
    required this.mensajeInicial,
    required this.sugerencias,
  });

  @override
  State<GemQuickPage> createState() => _GemQuickPageState();
}

class _GemQuickPageState extends State<GemQuickPage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GeminiService _gemini = GetIt.instance<GeminiService>();
  bool _cargando = false;

  final List<_Msg> _mensajes = [];

  @override
  void initState() {
    super.initState();
    // Enviar el mensaje inicial automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) => _enviarTexto(widget.mensajeInicial));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty || _cargando) return;
    _ctrl.clear();
    await _enviarTexto(txt);
  }

  Future<void> _enviarTexto(String txt) async {
    setState(() {
      _mensajes.add(_Msg(texto: txt, esGem: false));
      _cargando = true;
    });
    _scrollFinal();
    final resp = await _gemini.enviarMensaje(txt);
    if (!mounted) return;
    setState(() {
      _mensajes.add(_Msg(texto: resp, esGem: true));
      _cargando = false;
    });
    _scrollFinal();
  }

  void _scrollFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: AppColors.blanco,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const Text('GEM Coach IA',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          // Sugerencias rápidas
          if (widget.sugerencias.isNotEmpty)
            Container(
              color: AppColors.blanco,
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: widget.sugerencias.map((s) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: AppColors.fondoVerde,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _enviarTexto(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text(s,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.verdeOs)),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),

          // Mensajes
          Expanded(
            child: _mensajes.isEmpty && _cargando
                ? const Center(child: CircularProgressIndicator(color: AppColors.verde))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: _mensajes.length + (_cargando ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_cargando && i == _mensajes.length) {
                        return _buildTyping();
                      }
                      final m = _mensajes[i];
                      return _buildBubble(m);
                    },
                  ),
          ),

          // Input
          Container(
            color: AppColors.blanco,
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F0),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      maxLines: 4, minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu pregunta...',
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
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.verde, AppColors.verdeOs],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
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

  Widget _buildBubble(_Msg m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: m.esGem ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (m.esGem) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.verde, AppColors.verdeOs]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.blanco, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: m.esGem ? AppColors.blanco : AppColors.verde,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(m.esGem ? 4 : 20),
                  bottomRight: Radius.circular(m.esGem ? 20 : 4),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: m.esGem
                  ? MarkdownBody(
                      data: m.texto,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
                        strong: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        listBullet: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      ),
                    )
                  : Text(m.texto,
                      style: const TextStyle(fontSize: 15, color: AppColors.blanco, height: 1.5)),
            ),
          ),
          if (!m.esGem) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.fondoGris, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.verde, AppColors.verdeOs]),
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
              topLeft: Radius.circular(20), topRight: Radius.circular(20),
              bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4),
            ),
          ),
          child: const Text('GEM está pensando...', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
        ),
      ]),
    );
  }
}

class _Msg {
  final String texto;
  final bool esGem;
  const _Msg({required this.texto, required this.esGem});
}
