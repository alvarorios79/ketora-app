import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';

class GlucosaPage extends StatefulWidget {
  const GlucosaPage({super.key});
  @override
  State<GlucosaPage> createState() => _GlucosaPageState();
}

class _GlucosaPageState extends State<GlucosaPage> {
  final _ctrl = TextEditingController();
  String _momento = 'Ayunas';
  List<_Lectura> _lecturas = [];
  bool _cargando = true;

  final _db   = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // ── Firestore ─────────────────────────────────────────────────────────────

  Future<void> _cargar() async {
    if (_uid.isEmpty) { setState(() => _cargando = false); return; }
    final snap = await _db
        .collection('users').doc(_uid).collection('glucosa')
        .orderBy('timestamp')
        .get();
    final lista = snap.docs.map((d) {
      final data = d.data();
      final ts = (data['timestamp'] as Timestamp).toDate();
      final fecha = '${ts.day.toString().padLeft(2,'0')}/${ts.month.toString().padLeft(2,'0')}';
      return _Lectura(fecha, data['momento'] ?? 'Ayunas', (data['valor'] as num).toInt(), id: d.id);
    }).toList();
    if (mounted) setState(() { _lecturas = lista; _cargando = false; });
  }

  Future<void> _guardar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    final valor = int.tryParse(texto);
    if (valor == null) return;

    _ctrl.clear();
    final ahora = DateTime.now();
    final fecha = '${ahora.day.toString().padLeft(2,'0')}/${ahora.month.toString().padLeft(2,'0')}';

    // Guardar en Firestore
    final doc = await _db
        .collection('users').doc(_uid).collection('glucosa')
        .add({'valor': valor, 'momento': _momento, 'timestamp': Timestamp.fromDate(ahora)});

    setState(() {
      _lecturas.add(_Lectura(fecha, _momento, valor, id: doc.id));
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✓ $valor mg/dL guardado ($_momento)'),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _eliminar(String id) async {
    await _db.collection('users').doc(_uid).collection('glucosa').doc(id).delete();
    setState(() => _lecturas.removeWhere((l) => l.id == id));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _color(int v) {
    if (v < 70)  return AppColors.warning;
    if (v < 100) return AppColors.success;
    if (v < 126) return AppColors.warning;
    return AppColors.error;
  }

  String _estado(int v) {
    if (v < 70)  return 'Hipoglucemia';
    if (v < 100) return 'Normal ✅';
    if (v < 126) return 'Prediabetes';
    return 'Alta';
  }

  @override
  Widget build(BuildContext context) {
    final ayunas  = _lecturas.where((l) => l.momento == 'Ayunas').toList();
    final ultima  = ayunas.isNotEmpty ? ayunas.last : (_lecturas.isNotEmpty ? _lecturas.last : null);
    final bajada  = _lecturas.isNotEmpty && ultima != null ? _lecturas.first.valor - ultima.valor : 0;
    final promedio = ayunas.isEmpty ? 0
        : (ayunas.fold(0, (s, l) => s + l.valor) / ayunas.length).round();
    final recientes = _lecturas.reversed.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1510),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Control Glucémico 🩸',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.verdeMedio))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [

                // ── Stats ──────────────────────────────────────────
                if (ultima != null) ...[
                  Row(children: [
                    Expanded(child: _StatCard('Última\nayunas', '${ultima.valor}', 'mg/dL', _color(ultima.valor))),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard('Promedio\nayunas', '$promedio', 'mg/dL', _color(promedio))),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard('Bajada\ntotal',
                        bajada >= 0 ? '-$bajada' : '+${bajada.abs()}', 'mg/dL',
                        bajada >= 0 ? AppColors.success : AppColors.error)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _color(ultima.valor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Estado: ${_estado(ultima.valor)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _color(ultima.valor))),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF182318), borderRadius: BorderRadius.circular(16)),
                    child: const Text('Aún no tienes lecturas. Registra tu primera medición 👇',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Color(0xFF8FAF8F))),
                  ),
                const SizedBox(height: 16),

                // ── Formulario ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182318),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📝 Registrar nueva lectura',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Escribe el número que muestra tu glucómetro',
                          style: TextStyle(fontSize: 13, color: Color(0xFF8FAF8F))),
                      const SizedBox(height: 14),
                      const Text('¿Cuándo mediste?',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _MomentoBtn('Ayunas',     _momento == 'Ayunas',       () => setState(() => _momento = 'Ayunas'))),
                        const SizedBox(width: 8),
                        Expanded(child: _MomentoBtn('Post-comida', _momento == 'Postprandial', () => setState(() => _momento = 'Postprandial'))),
                        const SizedBox(width: 8),
                        Expanded(child: _MomentoBtn('Noche',      _momento == 'Noche',        () => setState(() => _momento = 'Noche'))),
                      ]),
                      const SizedBox(height: 14),
                      const Text('Valor en mg/dL',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '105',
                          hintStyle: const TextStyle(color: Color(0xFF4A6B4A), fontSize: 28),
                          suffixText: 'mg/dL',
                          suffixStyle: const TextStyle(fontSize: 16, color: Color(0xFF8FAF8F)),
                          filled: true,
                          fillColor: const Color(0xFF0D1510),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('Guardar lectura',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Gráfica ────────────────────────────────────────
                if (ayunas.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF182318), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tendencia glucosa en ayunas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _GlucosaChart(valores: ayunas.map((l) => l.valor.toDouble()).toList()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Historial ──────────────────────────────────────
                if (recientes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF182318), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Últimas lecturas',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 10),
                        for (final l in recientes)
                          Dismissible(
                            key: Key(l.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.delete_outline, color: AppColors.error),
                            ),
                            onDismissed: (_) => _eliminar(l.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                Container(width: 12, height: 12,
                                    decoration: BoxDecoration(color: _color(l.valor), shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                                Text(l.fecha, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF8FAF8F))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFF0D1510), borderRadius: BorderRadius.circular(8)),
                                  child: Text(l.momento, style: const TextStyle(fontSize: 12, color: Color(0xFF8FAF8F), fontWeight: FontWeight.w600)),
                                ),
                                const Spacer(),
                                Text('${l.valor} mg/dL',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _color(l.valor))),
                              ]),
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

class _Lectura {
  final String fecha, momento, id;
  final int valor;
  _Lectura(this.fecha, this.momento, this.valor, {this.id = ''});
}

class _StatCard extends StatelessWidget {
  final String titulo, valor, unidad;
  final Color color;
  const _StatCard(this.titulo, this.valor, this.unidad, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(color: const Color(0xFF182318), borderRadius: BorderRadius.circular(16)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(titulo, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8FAF8F), fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(valor, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      Text(unidad, style: const TextStyle(fontSize: 10, color: Color(0xFF4A6B4A), fontWeight: FontWeight.w500)),
    ]),
  );
}

class _MomentoBtn extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _MomentoBtn(this.label, this.activo, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFF3B82F6) : const Color(0xFF0D1510),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: activo ? Colors.white : const Color(0xFF8FAF8F))),
    ),
  );
}

// ── Gráfica ───────────────────────────────────────────────────────────────────

class _GlucosaChart extends CustomPainter {
  final List<double> valores;
  _GlucosaChart({required this.valores});

  static const double minY = 80, maxY = 180;
  static const double lp = 40, rp = 10, tp = 10, bp = 6;

  double px(int i, double w) => valores.length <= 1
      ? lp + (w - lp - rp) / 2
      : lp + (w - lp - rp) * i / (valores.length - 1);

  double py(double v, double h) =>
      tp + (h - tp - bp) * (1 - (v.clamp(minY, maxY) - minY) / (maxY - minY));

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty) return;
    final w = size.width, h = size.height;

    final gridP = Paint()..color = const Color(0xFF2A3D2A)..strokeWidth = 1;
    for (final yv in [80.0, 100.0, 126.0, 160.0]) {
      final yp = py(yv, h);
      canvas.drawLine(Offset(lp, yp), Offset(w - rp, yp), gridP);
      final tp2 = TextPainter(
        text: TextSpan(text: '${yv.toInt()}', style: const TextStyle(fontSize: 9, color: Color(0xFF4A6B4A))),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: 32);
      tp2.paint(canvas, Offset(lp - tp2.width - 3, yp - tp2.height / 2));
    }

    void dash(double yv, Color c) {
      final yp = py(yv, h);
      final p = Paint()..color = c.withOpacity(0.5)..strokeWidth = 1.5;
      for (double x = lp; x < w - rp; x += 10) {
        canvas.drawLine(Offset(x, yp), Offset((x + 6).clamp(0.0, w - rp), yp), p);
      }
    }
    dash(100, const Color(0xFF7CB518));
    dash(126, const Color(0xFFEF4444));

    final area = Path()..moveTo(px(0, w), h - bp)..lineTo(px(0, w), py(valores[0], h));
    for (int i = 1; i < valores.length; i++) {
      final x0 = px(i-1,w), y0 = py(valores[i-1],h), x1 = px(i,w), y1 = py(valores[i],h);
      area.cubicTo((x0+x1)/2, y0, (x0+x1)/2, y1, x1, y1);
    }
    area..lineTo(px(valores.length-1, w), h - bp)..close();
    canvas.drawPath(area, Paint()
      ..shader = ui.Gradient.linear(Offset(w/2, tp), Offset(w/2, h),
          [const Color(0x303B82F6), const Color(0x003B82F6)]));

    final line = Path()..moveTo(px(0, w), py(valores[0], h));
    for (int i = 1; i < valores.length; i++) {
      final x0 = px(i-1,w), y0 = py(valores[i-1],h), x1 = px(i,w), y1 = py(valores[i],h);
      line.cubicTo((x0+x1)/2, y0, (x0+x1)/2, y1, x1, y1);
    }
    canvas.drawPath(line, Paint()..color = const Color(0xFF3B82F6)..strokeWidth = 2.5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    for (int i = 0; i < valores.length; i++) {
      final x = px(i,w), y = py(valores[i],h), v = valores[i];
      final Color c = v < 100 ? const Color(0xFF7CB518) : v < 126 ? const Color(0xFFC9A227) : const Color(0xFFEF4444);
      canvas.drawCircle(Offset(x, y), 5.5, Paint()..color = const Color(0xFF182318));
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_GlucosaChart old) => old.valores != valores;
}
