import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/theme/app_colors.dart';

/// Tab 4 — PROGRESO
class ProgresoPage extends StatefulWidget {
  const ProgresoPage({super.key});

  @override
  State<ProgresoPage> createState() => _ProgresoPageState();
}

class _ProgresoPageState extends State<ProgresoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 195,
            pinned: true,
            backgroundColor: Colors.black,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.black,
                child: SafeArea(top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo_icono.png',
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Mi Progreso',
                                style: TextStyle(
                                  color: AppColors.blanco,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                )),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('14 días en keto 💪',
                                  style: TextStyle(color: AppColors.blanco, fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppColors.verdeOs,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppColors.oro,
                  indicatorWeight: 3,
                  labelColor: AppColors.blanco,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Peso'),
                    Tab(text: 'Medidas'),
                    Tab(text: 'Logros'),
                    Tab(text: 'Fotos'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: const [
            _PesoTab(),
            _MedidasTab(),
            _LogrosTab(),
            _FotosTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — PESO
// ─────────────────────────────────────────────────────────────────────────────
class _PesoTab extends StatefulWidget {
  const _PesoTab();

  @override
  State<_PesoTab> createState() => _PesoTabState();
}

class _PesoTabState extends State<_PesoTab> {
  List<Map<String, dynamic>> _registros = [];
  bool _cargando = true;
  final TextEditingController _pesoCtrl = TextEditingController();

  final _db  = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() { super.initState(); _cargar(); }

  @override
  void dispose() { _pesoCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    if (_uid.isEmpty) { setState(() => _cargando = false); return; }
    final snap = await _db.collection('users').doc(_uid).collection('peso')
        .orderBy('timestamp').get();
    final lista = snap.docs.map((d) {
      final data = d.data();
      return {'id': d.id, 'kg': (data['kg'] as num).toDouble(), 'timestamp': (data['timestamp'] as Timestamp).toDate()};
    }).toList();
    if (mounted) setState(() { _registros = lista; _cargando = false; });
  }

  List<FlSpot> get _spots {
    if (_registros.isEmpty) return [];
    final inicio = (_registros.first['timestamp'] as DateTime);
    return _registros.asMap().entries.map((e) {
      final dias = (e.value['timestamp'] as DateTime).difference(inicio).inDays + 1.0;
      return FlSpot(dias, e.value['kg'] as double);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: AppColors.verdeMedio));

    final spots = _spots;
    final inicio = spots.isNotEmpty ? spots.first.y : 0.0;
    final actual = spots.isNotEmpty ? spots.last.y : 0.0;
    final perdido = inicio - actual;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_registros.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text('Aún no tienes registros de peso.\nToca el botón de abajo para empezar 👇',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF1A5C2A))),
          )
        else
        // Stats row
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Inicio', valor: '${inicio.toStringAsFixed(1)} kg', icon: Icons.flag_outlined, color: Color(0xFF1A5C2A))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Actual', valor: '${actual.toStringAsFixed(1)} kg', icon: Icons.monitor_weight_outlined, color: AppColors.verde)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Perdido', valor: '${perdido >= 0 ? "-" : "+"}${perdido.abs().toStringAsFixed(1)} kg', icon: Icons.trending_down_rounded, color: AppColors.success)),
          ],
        ),
        const SizedBox(height: 16),

        // Gráfica fl_chart
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Evolución del peso',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D3B1E))),
              const SizedBox(height: 4),
              const Text('Últimos 14 días',
                style: TextStyle(fontSize: 15, color: Color(0xFF1A5C2A))),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minY: spots.isEmpty ? 0 : spots.map((s) => s.y).reduce((a,b) => a < b ? a : b) - 1,
                    maxY: spots.isEmpty ? 100 : spots.map((s) => s.y).reduce((a,b) => a > b ? a : b) + 1,
                    minX: spots.isEmpty ? 1 : spots.first.x,
                    maxX: spots.isEmpty ? 14 : spots.last.x,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.divider,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}kg',
                            style: const TextStyle(fontSize: 15, color: Color(0xFF1A5C2A)),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 3,
                          getTitlesWidget: (v, _) => Text(
                            'D${v.toInt()}',
                            style: const TextStyle(fontSize: 15, color: Color(0xFF1A5C2A)),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.isEmpty ? [const FlSpot(1, 0)] : spots,
                        isCurved: true,
                        curveSmoothness: 0.4,
                        color: AppColors.verde,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.verde,
                            strokeWidth: 2,
                            strokeColor: AppColors.blanco,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.verde.withValues(alpha: 0.25),
                              AppColors.verde.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Historial
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Historial', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D3B1E))),
              const SizedBox(height: 12),
              ..._registros.reversed.take(5).toList().asMap().entries.map((e) {
                final r = e.value;
                final ts = r['timestamp'] as DateTime;
                final fecha = '${ts.day.toString().padLeft(2,'0')}/${ts.month.toString().padLeft(2,'0')}';
                final idx = _registros.indexOf(r);
                final diff = idx == 0 ? null : (r['kg'] as double) - (_registros[idx-1]['kg'] as double);
                return _PesoHistorialItem(dia: fecha, kg: r['kg'] as double, diff: diff);
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Botón registrar
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verde,
            foregroundColor: AppColors.blanco,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Registrar peso de hoy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          onPressed: () => _showPesoDialog(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showPesoDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cuánto pesas hoy?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: _pesoCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ej. 89.2',
            suffixText: 'kg',
            filled: true,
            fillColor: AppColors.fondoGris,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verde, foregroundColor: AppColors.blanco,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final pesoStr = _pesoCtrl.text.trim();
              final kg = double.tryParse(pesoStr.replaceAll(',', '.'));
              Navigator.pop(dialogCtx);
              _pesoCtrl.clear();
              if (kg == null) return;
              final ahora = DateTime.now();
              final doc = await _db.collection('users').doc(_uid).collection('peso')
                  .add({'kg': kg, 'timestamp': Timestamp.fromDate(ahora)});
              setState(() {
                _registros.add({'id': doc.id, 'kg': kg, 'timestamp': ahora});
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Peso registrado: $kg kg ✓'),
                backgroundColor: AppColors.verde,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _PesoHistorialItem extends StatelessWidget {
  final String dia;
  final double kg;
  final double? diff;
  const _PesoHistorialItem({required this.dia, required this.kg, this.diff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.fondoVerde,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.monitor_weight_outlined, color: AppColors.verde, size: 18),
          ),
          const SizedBox(width: 12),
          Text(dia, style: const TextStyle(fontSize: 16, color: Color(0xFF1A5C2A))),
          const Spacer(),
          Text('${kg.toStringAsFixed(1)} kg',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D3B1E))),
          if (diff != null) ...[
            const SizedBox(width: 8),
            Text(
              diff! < 0 ? '${diff!.toStringAsFixed(1)}' : '+${diff!.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: diff! < 0 ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — MEDIDAS
// ─────────────────────────────────────────────────────────────────────────────
class _MedidasTab extends StatefulWidget {
  const _MedidasTab();
  @override
  State<_MedidasTab> createState() => _MedidasTabState();
}

class _MedidasTabState extends State<_MedidasTab> {
  Map<String, double>? _inicio;
  Map<String, double>? _actual;
  bool _cargando = true;

  final _db  = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static const _campos = [
    {'emoji': '👕', 'label': 'Cintura',  'key': 'cintura'},
    {'emoji': '🩲', 'label': 'Cadera',   'key': 'cadera'},
    {'emoji': '💪', 'label': 'Brazo',    'key': 'brazo'},
    {'emoji': '🦵', 'label': 'Muslo',    'key': 'muslo'},
    {'emoji': '👔', 'label': 'Pecho',    'key': 'pecho'},
  ];

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    if (_uid.isEmpty) { setState(() => _cargando = false); return; }
    final snap = await _db.collection('users').doc(_uid).collection('medidas')
        .orderBy('timestamp').get();
    if (snap.docs.isEmpty) { setState(() => _cargando = false); return; }
    Map<String, double> toMap(Map<String, dynamic> d) => {
      for (final c in _campos) c['key']!: (d[c['key']] as num?)?.toDouble() ?? 0.0,
    };
    setState(() {
      _inicio  = toMap(snap.docs.first.data());
      _actual  = toMap(snap.docs.last.data());
      _cargando = false;
    });
  }

  Future<void> _mostrarDialog() async {
    final ctrls = { for (final c in _campos) c['key']!: TextEditingController(
      text: _actual != null ? _actual![c['key']]!.toStringAsFixed(1) : '') };

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF182318),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Actualizar medidas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _campos.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: ctrls[c['key']],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '${c['emoji']} ${c['label']} (cm)',
                  labelStyle: const TextStyle(color: Color(0xFF8FAF8F)),
                  filled: true,
                  fillColor: const Color(0xFF0D1510),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixText: 'cm',
                  suffixStyle: const TextStyle(color: Color(0xFF8FAF8F)),
                ),
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8FAF8F)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verde, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final data = <String, dynamic>{'timestamp': Timestamp.now()};
              for (final c in _campos) {
                final v = double.tryParse(ctrls[c['key']]!.text.replaceAll(',', '.'));
                if (v != null) data[c['key']!] = v;
              }
              Navigator.pop(ctx);
              await _db.collection('users').doc(_uid).collection('medidas').add(data);
              await _cargar();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('✓ Medidas actualizadas'),
                backgroundColor: AppColors.verde,
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    for (final c in ctrls.values) c.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: AppColors.verdeMedio));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A472A), AppColors.verde],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.white70, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Toma tus medidas 1 vez por semana, a la misma hora',
                style: TextStyle(color: Colors.white, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 16),
        if (_actual == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text('Aún no tienes medidas.\nToca "Registrar medidas" para empezar 👇',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFF1A5C2A))),
          )
        else
          ..._campos.map((c) {
            final key = c['key']!;
            final act = _actual![key] ?? 0.0;
            final ini = _inicio![key] ?? act;
            return _MedidaCard(data: _MedidaData(
              emoji: c['emoji']!, label: c['label']!, unidad: 'cm', actual: act, inicio: ini));
          }),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.verde, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
          ),
          icon: const Icon(Icons.edit_outlined),
          label: Text(_actual == null ? 'Registrar medidas' : 'Actualizar medidas',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          onPressed: _mostrarDialog,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _MedidaData {
  final String emoji;
  final String label;
  final double actual;
  final double inicio;
  final String unidad;
  const _MedidaData({
    required this.emoji,
    required this.label,
    required this.actual,
    required this.inicio,
    required this.unidad,
  });
}

class _MedidaCard extends StatelessWidget {
  final _MedidaData data;
  const _MedidaCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final diff = data.actual - data.inicio;
    final buen = diff <= 0;
    final pct = (data.actual / data.inicio).clamp(0.6, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(data.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D3B1E))),
                    Text('Inicio: ${data.inicio.toStringAsFixed(1)} ${data.unidad}',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF1A5C2A))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${data.actual.toStringAsFixed(1)} ${data.unidad}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D3B1E))),
                  Text(
                    diff == 0 ? 'Sin cambio' : (buen ? '${diff.toStringAsFixed(1)} ${data.unidad}' : '+${diff.toStringAsFixed(1)} ${data.unidad}'),
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: diff == 0 ? AppColors.textSecondary : (buen ? AppColors.success : AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(height: 6, decoration: BoxDecoration(color: AppColors.fondoGris, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: buen || diff == 0 ? AppColors.verde : AppColors.error,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — LOGROS
// ─────────────────────────────────────────────────────────────────────────────
class _LogrosTab extends StatelessWidget {
  const _LogrosTab();

  static const _logros = [
    _LogroData(emoji: '🔥', titulo: 'Primera semana', desc: 'Completaste 7 días en keto', alcanzado: true),
    _LogroData(emoji: '💧', titulo: 'Hidratado', desc: 'Bebiste 2L de agua 5 días seguidos', alcanzado: true),
    _LogroData(emoji: '⚡', titulo: 'Cetosis activa', desc: 'Superaste el umbral de cetosis', alcanzado: true),
    _LogroData(emoji: '⏱️', titulo: 'Ayuno 16h', desc: 'Completaste tu primer ayuno 16:8', alcanzado: true),
    _LogroData(emoji: '🏆', titulo: 'Mes keto', desc: '30 días consecutivos en keto', alcanzado: false),
    _LogroData(emoji: '📉', titulo: '-5 kg', desc: 'Pierde 5 kilogramos desde tu inicio', alcanzado: false),
    _LogroData(emoji: '💪', titulo: 'Cintura -10cm', desc: 'Reduce 10 cm de cintura', alcanzado: false),
    _LogroData(emoji: '🥑', titulo: 'Experto keto', desc: 'Completa el quiz de keto con 100%', alcanzado: false),
  ];

  @override
  Widget build(BuildContext context) {
    final alcanzados = _logros.where((l) => l.alcanzado).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Barra general
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF78350F), AppColors.oro],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tus logros',
                          style: TextStyle(color: AppColors.blanco, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('$alcanzados de ${_logros.length} desbloqueados',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('${(alcanzados / _logros.length * 100).round()}%',
                    style: const TextStyle(color: AppColors.blanco, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 14),
              Stack(
                children: [
                  Container(height: 8, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(
                    widthFactor: alcanzados / _logros.length,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Alcanzados
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Desbloqueados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A5C2A))),
        ),
        ..._logros.where((l) => l.alcanzado).map((l) => _LogroCard(data: l)),

        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Por desbloquear', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A5C2A))),
        ),
        ..._logros.where((l) => !l.alcanzado).map((l) => _LogroCard(data: l)),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _LogroData {
  final String emoji;
  final String titulo;
  final String desc;
  final bool alcanzado;
  const _LogroData({required this.emoji, required this.titulo, required this.desc, required this.alcanzado});
}

class _LogroCard extends StatelessWidget {
  final _LogroData data;
  const _LogroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.alcanzado ? AppColors.blanco : AppColors.fondoGris,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: data.alcanzado ? AppColors.verdeClaro : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: data.alcanzado ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))] : [],
      ),
      child: Row(
        children: [
          Text(
            data.emoji,
            style: TextStyle(fontSize: 28, color: data.alcanzado ? null : const Color(0xFFCCCCCC)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.titulo,
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: data.alcanzado ? const Color(0xFF0D3B1E) : const Color(0xFF4A6B4A),
                  )),
                const SizedBox(height: 2),
                Text(data.desc,
                  style: TextStyle(
                    fontSize: 15,
                    color: data.alcanzado ? const Color(0xFF1A5C2A) : const Color(0xFF4A6B4A),
                  )),
              ],
            ),
          ),
          if (data.alcanzado)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppColors.fondoVerde, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.verde, size: 16),
            )
          else
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF4A6B4A), size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — FOTOS DE PROGRESO
// ─────────────────────────────────────────────────────────────────────────────
class _FotasTab extends StatefulWidget {
  const _FotasTab();
  @override
  State<_FotasTab> createState() => _FotasTabState();
}

class _FotasTabState extends State<_FotasTab> {
  // Datos: [{path, fecha, dias}]
  List<Map<String, dynamic>> _fotos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  String get _prefKey => 'ketora_progress_photos_$_uid';

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .where((m) => File(m['path'] as String).existsSync())
          .toList();
      if (mounted) setState(() => _fotos = list);
    }
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(_fotos));
  }

  Future<void> _agregarFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(color: AppColors.blanco, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Añadir foto de progreso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.fondoVerde, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: AppColors.verde, size: 20)),
            title: const Text('Tomar una foto', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.fondoAzul, shape: BoxShape.circle),
              child: const Icon(Icons.photo_library_rounded, color: AppColors.info, size: 20)),
            title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source, maxWidth: 900, maxHeight: 1600, imageQuality: 88,
    );
    if (photo == null || !mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final destPath = '${dir.path}/progress_${_uid}_$ts.jpg';
    await File(photo.path).copy(destPath);

    final now = DateTime.now();
    final nuevaFoto = {
      'path': destPath,
      'fecha': '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}',
      'timestamp': now.millisecondsSinceEpoch,
    };

    setState(() => _fotos.add(nuevaFoto));
    await _guardar();
  }

  Future<void> _eliminarFoto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Seguro que quieres eliminar esta foto de progreso?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final path = _fotos[index]['path'] as String;
    try { await File(path).delete(); } catch (_) {}
    setState(() => _fotos.removeAt(index));
    await _guardar();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1510),
      child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card con tip de frecuencia
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📸', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Registro fotográfico', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'Tómate una foto de cuerpo completo cada 2 semanas. Con keto, los cambios visibles inician a partir de la semana 3-4.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
              const SizedBox(height: 12),
              Row(children: [
                _ChipFrecuencia('Semana 2', '💧 Agua'),
                const SizedBox(width: 6),
                _ChipFrecuencia('Semana 4', '🔥 Grasa'),
                const SizedBox(width: 6),
                _ChipFrecuencia('Semana 8', '💪 Músculo'),
              ]),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Botón añadir + contador
        Row(children: [
          Text(
            _fotos.isEmpty ? 'Sin fotos aún' : '${_fotos.length} foto${_fotos.length > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verde,
              foregroundColor: AppColors.blanco,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _agregarFoto,
            icon: const Icon(Icons.add_a_photo_rounded, size: 18),
            label: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 14),

        // Estado vacío
        if (_fotos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF182318),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.verde.withOpacity(0.3)),
            ),
            child: Column(children: [
              const Text('📸', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text('Tu primera foto de progreso',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 10),
              const Text(
                'Tómate una foto cada 2 semanas y compara tu evolución. Los cambios con keto se notan a partir de la semana 3.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF8FAF8F), height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verde,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _agregarFoto,
                  icon: const Icon(Icons.camera_alt_rounded, size: 22),
                  label: const Text('Tomar mi primera foto',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ]),
          ),

        // Grid de fotos
        if (_fotos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.65,
            ),
            itemCount: _fotos.length,
            itemBuilder: (ctx, i) {
              final foto = _fotos[_fotos.length - 1 - i]; // más reciente primero
              final isFirst = i == 0;
              return GestureDetector(
                onLongPress: () => _eliminarFoto(_fotos.length - 1 - i),
                child: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(foto['path'] as String),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // Fecha en la parte inferior
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Text(
                        foto['fecha'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  // Badge "Reciente"
                  if (isFirst)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.verde,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Reciente', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ]),
              );
            },
          ),

        const SizedBox(height: 8),
        if (_fotos.isNotEmpty)
          const Text(
            'Mantén presionada una foto para eliminarla',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF4A6B4A)),
          ),
        const SizedBox(height: 80),
      ],
      ),
    );
  }
}

class _FotosTab extends StatelessWidget {
  const _FotosTab();
  @override
  Widget build(BuildContext context) => const _FotasTab();
}

class _ChipFrecuencia extends StatelessWidget {
  final String semana;
  final String cambio;
  const _ChipFrecuencia(this.semana, this.cambio);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(semana, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
        Text(cambio, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets compartidos
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.valor, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(valor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF1A5C2A))),
        ],
      ),
    );
  }
}
