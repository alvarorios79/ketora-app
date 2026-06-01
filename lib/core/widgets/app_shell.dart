import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme/app_colors.dart';
import '../../app/router/app_router.dart';
import '../../core/di/injection_container.dart';
import '../../features/hoy/domain/entities/alimento_registrado_entity.dart';
import '../../features/hoy/presentation/bloc/hoy_bloc.dart';
import '../../features/registro/presentation/pages/buscar_alimento_page.dart';
import '../../features/registro/presentation/pages/foto_ia_page.dart';

/// AppShell: contenedor principal con Bottom Navigation Bar de 5 tabs.
/// Provee HoyBloc a nivel Shell para que el picker y el scanner puedan
/// despachar eventos sin importar desde qué modal se abran.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const List<_TabItem> _tabs = [
    _TabItem(label: 'Hoy',     icon: Icons.home_outlined,       activeIcon: Icons.home_rounded,        path: AppRoutes.hoy),
    _TabItem(label: 'Registro', icon: Icons.menu_book_outlined,  activeIcon: Icons.menu_book,           path: AppRoutes.registro),
    _TabItem(label: '',         icon: Icons.add,                  activeIcon: Icons.add,                 path: '', isFab: true),
    _TabItem(label: 'Progreso', icon: Icons.bar_chart_outlined,  activeIcon: Icons.bar_chart_rounded,   path: AppRoutes.progreso),
    _TabItem(label: 'GEM',      icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome,      path: AppRoutes.gem),
  ];

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.registro)) return 1;
    if (location.startsWith(AppRoutes.progreso)) return 3;
    if (location.startsWith(AppRoutes.gem))      return 4;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    final tab = _tabs[index];
    if (tab.isFab) {
      _showAddAlimentoSheet(context);
      return;
    }
    if (tab.path.isNotEmpty) {
      context.go(tab.path);
    }
  }

  void _showAddAlimentoSheet(BuildContext context) {
    // Capturamos el bloc ANTES de abrir el modal para poder despacharlo
    // después de await sin preocuparnos por el mounted del context del modal.
    final hoyBloc = context.read<HoyBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAlimentoSheet(
        onAgregar: (alimento) {
          hoyBloc.add(HoyGuardarAlimento(alimento));
        },
        onScannerTap: () async {
          // Cerramos el sheet primero
          if (context.mounted) Navigator.of(context).pop();
          // Esperamos el resultado del scanner
          final alimento = await context.push<AlimentoRegistradoEntity?>(
            '${AppRoutes.scanner}?tipo=General',
          );
          if (alimento != null) {
            hoyBloc.add(HoyGuardarAlimento(alimento));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid   = FirebaseAuth.instance.currentUser?.uid ?? '';
    final fecha = DateTime.now();
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return BlocProvider<HoyBloc>(
      create: (_) => sl<HoyBloc>()..add(HoyIniciarEscucha(uid: uid, fecha: fecha)),
      child: Builder(
        builder: (innerCtx) => Scaffold(
          body: child,
          bottomNavigationBar: _KetoraBotomNav(
            currentIndex: currentIndex,
            tabs: _tabs,
            onTap: (i) => _onTabTapped(innerCtx, i),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Navigation premium con FAB central elevado
// ─────────────────────────────────────────────────────────────────────────────
class _KetoraBotomNav extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _KetoraBotomNav({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: AppColors.verdeMedio.withValues(alpha: 0.3), width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(tabs.length, (i) {
              if (tabs[i].isFab) return _buildFabTab(i);
              return _buildRegularTab(i, tabs[i]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildRegularTab(int index, _TabItem tab) {
    final isActive = index == currentIndex;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: AppColors.verdeClaro,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.verdeMedio.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                color: isActive ? AppColors.verdeMedio : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.verdeMedio : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabTab(int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(0, -14),
              child: Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4B84A), Color(0xFFC9A227)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.verde.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.blanco, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modal: Agregar Alimento
// ─────────────────────────────────────────────────────────────────────────────
class _AddAlimentoSheet extends StatelessWidget {
  final void Function(AlimentoRegistradoEntity) onAgregar;
  final VoidCallback onScannerTap;

  const _AddAlimentoSheet({
    required this.onAgregar,
    required this.onScannerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('¿Cómo registras?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AddOption(
            icon: Icons.grid_view_rounded,
            color: AppColors.verde,
            label: 'Toca un alimento',
            subtitle: 'Selecciona con íconos — rápido y fácil',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _IconFoodPicker(onAgregar: onAgregar),
              );
            },
          ),
          const SizedBox(height: 12),
          _AddOption(
            icon: Icons.search_rounded,
            color: AppColors.verdeOs,
            label: 'Buscar alimento',
            subtitle: 'Base de datos de +100,000 alimentos con semáforo keto',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BuscarAlimentoPage(onAgregar: onAgregar),
              );
            },
          ),
          const SizedBox(height: 12),
          _AddOption(
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.oro,
            label: 'Escanear código de barras',
            subtitle: 'Escanea el empaque directamente',
            onTap: onScannerTap,
          ),
          const SizedBox(height: 12),
          _AddOption(
            icon: Icons.camera_alt_rounded,
            color: AppColors.info,
            label: 'Foto con IA (GEM)',
            subtitle: 'GEM identifica el plato y calcula macros',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => FotoIAPage(onAgregar: onAgregar),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon Food Picker — selección rápida por íconos
// ─────────────────────────────────────────────────────────────────────────────
class _IconFoodPicker extends StatefulWidget {
  final void Function(AlimentoRegistradoEntity) onAgregar;
  const _IconFoodPicker({required this.onAgregar});

  @override
  State<_IconFoodPicker> createState() => _IconFoodPickerState();
}

class _IconFoodPickerState extends State<_IconFoodPicker> {
  int _catIndex = 0;
  final List<_FoodCategory> _cats = [
    _FoodCategory(label: 'Proteínas', items: [
      _FoodItem('🥩', 'Carne res',   190, 0, 26, 9),
      _FoodItem('🍗', 'Pollo',        165, 0, 31, 4),
      _FoodItem('🐟', 'Salmón',       208, 0, 20, 13),
      _FoodItem('🥚', 'Huevo',         78, 0, 6,  5),
      _FoodItem('🥓', 'Tocino',       541, 0, 37, 42),
      _FoodItem('🍤', 'Camarón',       99, 0, 24, 1),
      _FoodItem('🐷', 'Cerdo',        242, 0, 27, 14),
      _FoodItem('🥩', 'Atún lata',    132, 0, 29, 1),
    ]),
    _FoodCategory(label: 'Lácteos', items: [
      _FoodItem('🧀', 'Queso',        400, 1, 25, 33),
      _FoodItem('🥛', 'Crema agria',  193, 3, 2,  19),
      _FoodItem('🧈', 'Mantequilla',  717, 0, 1,  81),
      _FoodItem('🫙', 'Queso crema',  342, 4, 6,  34),
      _FoodItem('🥛', 'Leche entera', 61,  5, 3,  3),
    ]),
    _FoodCategory(label: 'Verduras', items: [
      _FoodItem('🥑', 'Aguacate',     160, 2, 2,  15),
      _FoodItem('🥦', 'Brócoli',       34, 4, 3,  0),
      _FoodItem('🥬', 'Espinaca',      23, 1, 3,  0),
      _FoodItem('🫑', 'Pimiento',      31, 5, 1,  0),
      _FoodItem('🥒', 'Pepino',        16, 2, 1,  0),
      _FoodItem('🥗', 'Lechuga',       15, 1, 1,  0),
      _FoodItem('🍆', 'Berenjena',     25, 3, 1,  0),
      _FoodItem('🫛', 'Ejotes',        31, 4, 2,  0),
    ]),
    _FoodCategory(label: 'Grasas', items: [
      _FoodItem('🫒', 'Aceite oliva',  884, 0, 0, 100),
      _FoodItem('🥥', 'Aceite coco',   862, 0, 0,  100),
      _FoodItem('🌰', 'Nueces',        654, 3, 15, 65),
      _FoodItem('🥜', 'Almendras',     579, 3, 21, 50),
      _FoodItem('🫙', 'Aceitunas',     145, 1, 1,  15),
    ]),
    _FoodCategory(label: 'Bebidas', items: [
      _FoodItem('☕', 'Café negro',      2, 0, 0,  0),
      _FoodItem('🍵', 'Té sin azúcar',   2, 0, 0,  0),
      _FoodItem('💧', 'Agua',             0, 0, 0,  0),
      _FoodItem('🧃', 'Electrolitos',    10, 2, 0,  0),
    ]),
  ];

  _FoodItem? _seleccionado;
  double _cantidad = 100;

  /// Deduce la comida según la hora del día
  String _comidaActual() {
    final h = DateTime.now().hour;
    if (h < 11) return 'desayuno';
    if (h < 15) return 'almuerzo';
    if (h < 20) return 'cena';
    return 'snack';
  }

  @override
  Widget build(BuildContext context) {
    final cat = _cats[_catIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1510),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle + título
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFF2A3D2A), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Image.asset('assets/images/logo_icono.png', height: 36),
                    const SizedBox(width: 10),
                    const Text('Elige tu alimento',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8FAF8F)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Categorías
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cats.length,
                    itemBuilder: (_, i) {
                      final activo = i == _catIndex;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _catIndex = i;
                          _seleccionado = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: activo ? AppColors.verde : const Color(0xFF182318),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_cats[i].label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: activo ? Colors.white : const Color(0xFF8FAF8F),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Grid de alimentos
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: cat.items.length,
              itemBuilder: (_, i) {
                final item = cat.items[i];
                final seleccionado = _seleccionado == item;
                return GestureDetector(
                  onTap: () => setState(() => _seleccionado = seleccionado ? null : item),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: seleccionado ? const Color(0xFF0F3020) : const Color(0xFF182318),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: seleccionado ? AppColors.verde : const Color(0xFF2A3D2A),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(item.nombre,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                            color: seleccionado ? AppColors.verdeMedio : const Color(0xFF8FAF8F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('${item.kcal} kcal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, color: Color(0xFF4A6B4A))),
                      ],
                    ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Panel inferior — detalle del seleccionado
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _seleccionado != null ? null : 0,
            child: _seleccionado != null
              ? Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF182318),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 20,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(_seleccionado!.emoji, style: const TextStyle(fontSize: 36)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_seleccionado!.nombre,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  _MacroPill('G: ${(_seleccionado!.grasas * _cantidad / 100).round()}g', AppColors.macroGrasas),
                                  const SizedBox(width: 6),
                                  _MacroPill('P: ${(_seleccionado!.proteina * _cantidad / 100).round()}g', AppColors.macroProtein),
                                  const SizedBox(width: 6),
                                  _MacroPill('C: ${(_seleccionado!.carbos * _cantidad / 100).round()}g', AppColors.macroCarbos),
                                ]),
                              ],
                            ),
                          ),
                          Text('${(_seleccionado!.kcal * _cantidad / 100).round()} kcal',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.verde)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Cantidad
                      Row(
                        children: [
                          const Text('Cantidad (g):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _QtyBtn(icon: Icons.remove, onTap: () {
                            if (_cantidad > 25) setState(() => _cantidad -= 25);
                          }),
                          const SizedBox(width: 12),
                          Text('${_cantidad.round()}g',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(width: 12),
                          _QtyBtn(icon: Icons.add, onTap: () {
                            setState(() => _cantidad += 25);
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.verde,
                            foregroundColor: AppColors.blanco,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final item = _seleccionado!;
                            final cantidad = _cantidad;

                            // Construir la entidad con los macros escalados a la cantidad elegida
                            final alimento = AlimentoRegistradoEntity(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              nombre: item.nombre,
                              cantidadG: cantidad,
                              unidad: 'g',
                              calorias: item.kcal * cantidad / 100,
                              grasasG: item.grasas * cantidad / 100,
                              proteinaG: item.proteina * cantidad / 100,
                              carbosNetosG: item.carbos * cantidad / 100,
                              comida: _comidaActual(),
                              horaRegistro: DateTime.now(),
                              fuenteRegistro: 'manual',
                            );

                            Navigator.pop(context);
                            widget.onAgregar(alimento);
                          },
                          child: const Text('Agregar al registro',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String text;
  final Color color;
  const _MacroPill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.fondoGris,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

// Modelos internos
class _FoodCategory {
  final String label;
  final List<_FoodItem> items;
  const _FoodCategory({required this.label, required this.items});
}

class _FoodItem {
  final String emoji;
  final String nombre;
  final int kcal;     // por 100g
  final int carbos;
  final int proteina;
  final int grasas;
  const _FoodItem(this.emoji, this.nombre, this.kcal, this.carbos, this.proteina, this.grasas);
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fondoGris,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// Modelo simple de tab
class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  final bool isFab;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
    this.isFab = false,
  });
}
