import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../features/hoy/domain/entities/alimento_registrado_entity.dart';

/// Pantalla de búsqueda de alimentos con semáforo keto
class BuscarAlimentoPage extends StatefulWidget {
  final void Function(AlimentoRegistradoEntity) onAgregar;
  const BuscarAlimentoPage({super.key, required this.onAgregar});

  @override
  State<BuscarAlimentoPage> createState() => _BuscarAlimentoPageState();
}

class _BuscarAlimentoPageState extends State<BuscarAlimentoPage> {
  final _ctrl = TextEditingController();
  final _dio = Dio();
  List<_Alimento> _resultados = [];
  bool _cargando = false;
  bool _buscado = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final query = _ctrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _cargando = true; _buscado = true; _resultados = []; });

    try {
      final resp = await _dio.get(
        'https://world.openfoodfacts.org/cgi/search.pl',
        queryParameters: {
          'search_terms': query,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': 20,
          'fields': 'product_name,brands,nutriments,serving_size',
          'lc': 'es',
        },
        options: Options(sendTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)),
      );

      final products = (resp.data['products'] as List? ?? []);
      final lista = <_Alimento>[];

      for (final p in products) {
        final nombre = (p['product_name'] ?? '').toString().trim();
        if (nombre.isEmpty) continue;
        final n = p['nutriments'] ?? {};
        final carbos = _num(n['carbohydrates_100g']);
        final grasas = _num(n['fat_100g']);
        final proteina = _num(n['proteins_100g']);
        final kcal = _num(n['energy-kcal_100g']);
        if (kcal <= 0 && carbos <= 0) continue;

        lista.add(_Alimento(
          nombre: nombre,
          marca: (p['brands'] ?? '').toString().trim(),
          carbos: carbos,
          grasas: grasas,
          proteina: proteina,
          kcal: kcal,
        ));
      }

      setState(() { _resultados = lista; _cargando = false; });
    } catch (_) {
      setState(() { _cargando = false; });
    }
  }

  double _num(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  // ── Semáforo keto basado en carbos por 100g ──────────────────
  _KetoNivel _keto(_Alimento a) {
    if (a.carbos <= 5)  return _KetoNivel.verde;
    if (a.carbos <= 15) return _KetoNivel.amarillo;
    if (a.carbos <= 25) return _KetoNivel.naranja;
    return _KetoNivel.rojo;
  }

  String _comidaActual() {
    final h = DateTime.now().hour;
    if (h < 11) return 'desayuno';
    if (h < 15) return 'almuerzo';
    if (h < 20) return 'cena';
    return 'snack';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1510),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF2A3D2A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Text('🔍 Buscar alimento',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8FAF8F)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Leyenda semáforo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                _Chip('≤5g Keto ✅', const Color(0xFF7CB518)),
                const SizedBox(width: 6),
                _Chip('5-15g Moderado 🟡', const Color(0xFFC9A227)),
                const SizedBox(width: 6),
                _Chip('>25g Evitar 🔴', const Color(0xFFEF4444)),
              ],
            ),
          ),

          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF182318),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A3D2A)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _buscar(),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ej: aguacate, pollo, queso...',
                        hintStyle: TextStyle(color: Color(0xFF4A6B4A), fontSize: 16),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Color(0xFF4A6B4A)),
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _buscar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.verde,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Buscar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),

          // Resultados
          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator(color: AppColors.verdeMedio))
              : !_buscado
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('🥑', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Escribe un alimento para buscarlo',
                          style: TextStyle(fontSize: 16, color: Color(0xFF8FAF8F))),
                      ],
                    ),
                  )
                : _resultados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('😔', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('No encontramos ese alimento',
                            style: TextStyle(fontSize: 16, color: Color(0xFF8FAF8F))),
                          SizedBox(height: 4),
                          Text('Prueba con otro nombre o en inglés',
                            style: TextStyle(fontSize: 14, color: Color(0xFF4A6B4A))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: _resultados.length,
                      itemBuilder: (context, i) {
                        final a = _resultados[i];
                        final nivel = _keto(a);
                        return _TarjetaAlimento(
                          alimento: a,
                          nivel: nivel,
                          onAgregar: () {
                            final entidad = AlimentoRegistradoEntity(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              nombre: a.nombre,
                              cantidadG: 100,
                              unidad: 'g',
                              calorias: a.kcal,
                              grasasG: a.grasas,
                              proteinaG: a.proteina,
                              carbosNetosG: a.carbos,
                              comida: _comidaActual(),
                              horaRegistro: DateTime.now(),
                              fuenteRegistro: 'busqueda',
                            );
                            Navigator.pop(context);
                            widget.onAgregar(entidad);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('✓ ${a.nombre} agregado al registro'),
                              backgroundColor: AppColors.verde,
                              behavior: SnackBarBehavior.floating,
                            ));
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de resultado ───────────────────────────────────────────────────────

class _TarjetaAlimento extends StatelessWidget {
  final _Alimento alimento;
  final _KetoNivel nivel;
  final VoidCallback onAgregar;
  const _TarjetaAlimento({required this.alimento, required this.nivel, required this.onAgregar});

  Color get _color {
    switch (nivel) {
      case _KetoNivel.verde:   return const Color(0xFF7CB518);
      case _KetoNivel.amarillo:return const Color(0xFFC9A227);
      case _KetoNivel.naranja: return const Color(0xFFF97316);
      case _KetoNivel.rojo:    return const Color(0xFFEF4444);
    }
  }

  String get _etiqueta {
    switch (nivel) {
      case _KetoNivel.verde:   return 'KETO ✅';
      case _KetoNivel.amarillo:return 'MODERADO 🟡';
      case _KetoNivel.naranja: return 'CUIDADO 🟠';
      case _KetoNivel.rojo:    return 'EVITAR 🔴';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF182318),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alimento.nombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (alimento.marca.isNotEmpty)
                      Text(alimento.marca,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8FAF8F))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _color.withOpacity(0.4)),
                ),
                child: Text(_etiqueta,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Macros por 100g
          Row(
            children: [
              _MacroPill('🔥 ${alimento.kcal.round()} kcal', const Color(0xFF8FAF8F)),
              const SizedBox(width: 6),
              _MacroPill('🥩 P: ${alimento.proteina.toStringAsFixed(1)}g', const Color(0xFF3B82F6)),
              const SizedBox(width: 6),
              _MacroPill('🫒 G: ${alimento.grasas.toStringAsFixed(1)}g', const Color(0xFFC9A227)),
              const SizedBox(width: 6),
              _MacroPill('🍞 C: ${alimento.carbos.toStringAsFixed(1)}g', _color),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Por 100g', style: TextStyle(fontSize: 11, color: Color(0xFF4A6B4A))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onAgregar,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.verde,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('+ Agregar al registro',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets y modelos auxiliares ──────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

class _MacroPill extends StatelessWidget {
  final String text;
  final Color color;
  const _MacroPill(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

class _Alimento {
  final String nombre, marca;
  final double carbos, grasas, proteina, kcal;
  const _Alimento({
    required this.nombre, required this.marca,
    required this.carbos, required this.grasas,
    required this.proteina, required this.kcal,
  });
}

enum _KetoNivel { verde, amarillo, naranja, rojo }
