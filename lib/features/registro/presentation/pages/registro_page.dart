import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Tab 2 — REGISTRO (bitácora de alimentos del día)
class RegistroPage extends StatelessWidget {
  const RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1510),
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: Colors.black,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.black,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                children: [
                                  const Text('Mi Registro',
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, color: AppColors.blanco, size: 13),
                                        const SizedBox(width: 6),
                                        Text(_fechaHoy(),
                                          style: const TextStyle(color: AppColors.blanco, fontSize: 14, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Toca + en una comida para agregar 👆',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
          ),

          // ── Resumen del día ────────────────────────────────────
          const SliverToBoxAdapter(child: _ResumenDia()),

          // ── Secciones de comida ────────────────────────────────
          const SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 16),
                _ComidaSection(
                  titulo: 'Desayuno',
                  emoji: '🌅',
                  kcalMeta: 500,
                  alimentos: [
                    _AlimentoItem(emoji: '🥚', nombre: 'Huevos revueltos', cantidad: '2 huevos', kcal: 156),
                    _AlimentoItem(emoji: '🥑', nombre: 'Aguacate', cantidad: '80g', kcal: 128),
                  ],
                ),
                SizedBox(height: 12),
                _ComidaSection(
                  titulo: 'Almuerzo',
                  emoji: '☀️',
                  kcalMeta: 700,
                  alimentos: [
                    _AlimentoItem(emoji: '🐟', nombre: 'Salmón al horno', cantidad: '150g', kcal: 312),
                    _AlimentoItem(emoji: '🥦', nombre: 'Brócoli salteado', cantidad: '100g', kcal: 34),
                  ],
                ),
                SizedBox(height: 12),
                _ComidaSection(titulo: 'Cena', emoji: '🌙', kcalMeta: 600, alimentos: []),
                SizedBox(height: 12),
                _ComidaSection(titulo: 'Snacks', emoji: '⚡', kcalMeta: 200, alimentos: []),
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fechaHoy() {
    final d = DateTime.now();
    const meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${meses[d.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resumen del día (macros totales)
// ─────────────────────────────────────────────────────────────────────────────
class _ResumenDia extends StatelessWidget {
  const _ResumenDia();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF182318),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total consumido', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0F2B18), borderRadius: BorderRadius.circular(10)),
                child: const Text('630 / 2100 kcal', style: TextStyle(fontSize: 15, color: AppColors.verde, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _MacroPill(label: 'Grasas', valor: '42g', meta: '163g', color: AppColors.macroGrasas, pct: 0.26)),
              SizedBox(width: 10),
              Expanded(child: _MacroPill(label: 'Proteína', valor: '55g', meta: '131g', color: AppColors.macroProtein, pct: 0.42)),
              SizedBox(width: 10),
              Expanded(child: _MacroPill(label: 'Carbos', valor: '8g', meta: '26g', color: AppColors.macroCarbos, pct: 0.31)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String valor;
  final String meta;
  final Color color;
  final double pct;
  const _MacroPill({required this.label, required this.valor, required this.meta, required this.color, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              Text('/ $meta', style: const TextStyle(fontSize: 15, color: Color(0xFF4A6B4A))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF1A5C2A), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sección de comida
// ─────────────────────────────────────────────────────────────────────────────
class _AlimentoItem {
  final String emoji;
  final String nombre;
  final String cantidad;
  final int kcal;
  const _AlimentoItem({required this.emoji, required this.nombre, required this.cantidad, required this.kcal});
}

class _ComidaSection extends StatelessWidget {
  final String titulo;
  final String emoji;
  final int kcalMeta;
  final List<_AlimentoItem> alimentos;

  const _ComidaSection({
    required this.titulo,
    required this.emoji,
    required this.kcalMeta,
    required this.alimentos,
  });

  int get _totalKcal => alimentos.fold(0, (sum, a) => sum + a.kcal);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF182318),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // Header de la sección
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                Text('$_totalKcal / $kcalMeta kcal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _totalKcal > kcalMeta ? AppColors.error : AppColors.textSecondary,
                  )),
              ],
            ),
          ),

          // Barra de progreso
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                Container(height: 4, decoration: BoxDecoration(color: AppColors.fondoGris, borderRadius: BorderRadius.circular(2))),
                FractionallySizedBox(
                  widthFactor: (_totalKcal / kcalMeta).clamp(0.0, 1.0),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _totalKcal > kcalMeta ? AppColors.error : AppColors.verde,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alimentos
          if (alimentos.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...alimentos.map((a) => _AlimentoRow(item: a)),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],

          // Botón agregar
          InkWell(
            onTap: () => _abrirPicker(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2B18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: AppColors.verde, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Agregar a $titulo',
                    style: const TextStyle(color: AppColors.verde, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegistroFoodPicker(comida: titulo),
    );
  }
}

class _AlimentoRow extends StatelessWidget {
  final _AlimentoItem item;
  const _AlimentoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(item.cantidad, style: const TextStyle(fontSize: 14, color: Color(0xFF1A5C2A))),
              ],
            ),
          ),
          Text('${item.kcal} kcal',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.verde)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.close_rounded, color: Color(0xFF4A6B4A), size: 16),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Picker rápido (ícono grid) desde RegistroPage
// ─────────────────────────────────────────────────────────────────────────────
class _RegistroFoodPicker extends StatefulWidget {
  final String comida;
  const _RegistroFoodPicker({required this.comida});

  @override
  State<_RegistroFoodPicker> createState() => _RegistroFoodPickerState();
}

class _RegistroFoodPickerState extends State<_RegistroFoodPicker> {
  int _catIndex = 0;

  static const _cats = [
    _Cat('Proteínas', [
      _Food('🥩', 'Carne res',  190, 0, 26, 9),
      _Food('🍗', 'Pollo',      165, 0, 31, 4),
      _Food('🐟', 'Salmón',     208, 0, 20, 13),
      _Food('🥚', 'Huevo',       78, 0, 6,  5),
      _Food('🥓', 'Tocino',     541, 0, 37, 42),
      _Food('🐷', 'Cerdo',      242, 0, 27, 14),
    ]),
    _Cat('Lácteos', [
      _Food('🧀', 'Queso',       400, 1, 25, 33),
      _Food('🧈', 'Mantequilla', 717, 0,  1, 81),
      _Food('🫙', 'Queso crema', 342, 4,  6, 34),
      _Food('🥛', 'Crema',       193, 3,  2, 19),
    ]),
    _Cat('Verduras', [
      _Food('🥑', 'Aguacate',  160, 2, 2, 15),
      _Food('🥦', 'Brócoli',    34, 4, 3,  0),
      _Food('🥬', 'Espinaca',   23, 1, 3,  0),
      _Food('🥒', 'Pepino',     16, 2, 1,  0),
      _Food('🫑', 'Pimiento',   31, 5, 1,  0),
      _Food('🥗', 'Lechuga',    15, 1, 1,  0),
    ]),
    _Cat('Grasas', [
      _Food('🫒', 'Aceite oliva', 884, 0, 0, 100),
      _Food('🌰', 'Nueces',       654, 3,15,  65),
      _Food('🥜', 'Almendras',    579, 3,21,  50),
    ]),
    _Cat('Bebidas', [
      _Food('☕', 'Café',     2, 0, 0, 0),
      _Food('🍵', 'Té',       2, 0, 0, 0),
      _Food('💧', 'Agua',     0, 0, 0, 0),
    ]),
  ];

  _Food? _sel;
  double _cantidad = 100;

  @override
  Widget build(BuildContext context) {
    final cat = _cats[_catIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1510),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFF2A3D2A), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(children: [
                  Image.asset('assets/images/logo_icono.png', height: 36),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Agregar a ${widget.comida}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Text('Toca un alimento para seleccionar',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8FAF8F))),
                  ]),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8FAF8F)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cats.length,
                    itemBuilder: (_, i) {
                      final activo = i == _catIndex;
                      return GestureDetector(
                        onTap: () => setState(() { _catIndex = i; _sel = null; }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: activo ? AppColors.verde : const Color(0xFF182318),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(_cats[i].label,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: activo ? Colors.white : const Color(0xFF8FAF8F))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.85,
              ),
              itemCount: cat.items.length,
              itemBuilder: (_, i) {
                final f = cat.items[i];
                final sel = _sel == f;
                return GestureDetector(
                  onTap: () => setState(() => _sel = sel ? null : f),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF0F3020) : const Color(0xFF182318),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? AppColors.verde : const Color(0xFF2A3D2A), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(f.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 3),
                        Text(f.nombre, textAlign: TextAlign.center, maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? AppColors.verdeMedio : const Color(0xFF8FAF8F))),
                        Text('${f.kcal} kcal',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, color: Color(0xFF4A6B4A))),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_sel != null)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF182318),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 18,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Text(_sel!.emoji, style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_sel!.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('${(_sel!.kcal * _cantidad / 100).round()} kcal · ${(_sel!.grasas * _cantidad / 100).round()}g G · ${(_sel!.proteina * _cantidad / 100).round()}g P · ${(_sel!.carbos * _cantidad / 100).round()}g C',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8FAF8F))),
                    ])),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Text('Cantidad:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _QBtn(Icons.remove, () { if (_cantidad > 25) setState(() => _cantidad -= 25); }),
                    const SizedBox(width: 14),
                    Text('${_cantidad.round()}g',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 14),
                    _QBtn(Icons.add, () => setState(() => _cantidad += 25)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verde, foregroundColor: AppColors.blanco,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${_sel!.nombre} agregado a ${widget.comida} ✓'),
                          backgroundColor: AppColors.verde,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      },
                      child: const Text('Agregar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

class _QBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: AppColors.fondoGris, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 16, color: Colors.white),
    ),
  );
}

class _Cat {
  final String label;
  final List<_Food> items;
  const _Cat(this.label, this.items);
}

class _Food {
  final String emoji;
  final String nombre;
  final int kcal;
  final int carbos;
  final int proteina;
  final int grasas;
  const _Food(this.emoji, this.nombre, this.kcal, this.carbos, this.proteina, this.grasas);
}
