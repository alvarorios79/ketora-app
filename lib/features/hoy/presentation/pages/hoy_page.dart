import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/perfil_service.dart';
import '../bloc/hoy_bloc.dart';

class HoyPage extends StatelessWidget {
  const HoyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // HoyBloc es provisto por AppShell (BlocProvider a nivel de ShellRoute).
    // No se crea aquí para evitar dos instancias distintas.
    return const _HoyContent();
  }
}

class _HoyContent extends StatelessWidget {
  const _HoyContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HoyBloc, HoyState>(
      builder: (context, state) {
        if (state is HoyCargando) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(child: CircularProgressIndicator(color: AppColors.verde)),
          );
        }
        if (state is HoyError) {
          return Scaffold(body: Center(child: Text(state.mensaje)));
        }
        return _Dashboard(datos: state as HoyCargado);
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  final HoyCargado datos;
  const _Dashboard({required this.datos});

  String _emojiAlimento(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('aguacate') || n.contains('avocado')) return '🥑';
    if (n.contains('ensalada') || n.contains('salad')) return '🥗';
    if (n.contains('res') || n.contains('carne') || n.contains('bistec') || n.contains('lomo') || n.contains('beef') || n.contains('filete')) return '🥩';
    if (n.contains('pollo') || n.contains('chicken')) return '🍗';
    if (n.contains('cerdo') || n.contains('pork') || n.contains('chicharron') || n.contains('tocineta')) return '🥓';
    if (n.contains('salmon') || n.contains('salmón') || n.contains('atun') || n.contains('atún') || n.contains('pescado') || n.contains('fish') || n.contains('mojarra')) return '🐟';
    if (n.contains('huevo') || n.contains('egg')) return '🍳';
    if (n.contains('tomate') || n.contains('tomato')) return '🍅';
    if (n.contains('brocoli') || n.contains('brócoli') || n.contains('verdura') || n.contains('espinaca') || n.contains('lechuga')) return '🥦';
    if (n.contains('papa') || n.contains('patata') || n.contains('potato')) return '🥔';
    if (n.contains('arroz') || n.contains('rice')) return '🍚';
    if (n.contains('arepa')) return '🫓';
    if (n.contains('aguapanela') || n.contains('panela') || n.contains('jugo') || n.contains('agua') || n.contains('te ') || n.contains('café') || n.contains('cafe')) return '☕';
    if (n.contains('leche') || n.contains('milk') || n.contains('yogur')) return '🥛';
    if (n.contains('queso') || n.contains('cheese')) return '🧀';
    if (n.contains('nuez') || n.contains('almendra') || n.contains('nueces') || n.contains('mani')) return '🥜';
    if (n.contains('mantequilla') || n.contains('butter')) return '🧈';
    if (n.contains('aceite') || n.contains('oil') || n.contains('aceituna')) return '🫒';
    if (n.contains('chocolate') || n.contains('cacao')) return '🍫';
    if (n.contains('fresa') || n.contains('mora') || n.contains('blueberry') || n.contains('fruta') || n.contains('mango') || n.contains('pina') || n.contains('piña')) return '🍓';
    if (n.contains('limon') || n.contains('limón') || n.contains('naranja') || n.contains('citrico')) return '🍋';
    if (n.contains('sancocho') || n.contains('sopa') || n.contains('caldo') || n.contains('ajiaco') || n.contains('mondongo')) return '🍲';
    if (n.contains('bandeja') || n.contains('frijol')) return '🫘';
    if (n.contains('empanada') || n.contains('tamal')) return '🥟';
    if (n.contains('pan') || n.contains('bread') || n.contains('wrap')) return '🍞';
    if (n.contains('pizza')) return '🍕';
    if (n.contains('pasta') || n.contains('espagueti')) return '🍝';
    if (n.contains('hamburguesa') || n.contains('burger')) return '🍔';
    if (n.contains('perro') || n.contains('hot dog')) return '🌭';
    if (n.contains('chorizo') || n.contains('salchicha')) return '🌭';
    if (n.contains('miel') || n.contains('honey')) return '🍯';
    if (n.contains('maiz') || n.contains('mazorca') || n.contains('corn')) return '🌽';
    return '🍽️';
  }

  Future<void> _mostrarConfigVentana(BuildContext context) async {
    final perfil = sl<PerfilService>().perfilActual;

    int horaInicio = perfil?.horaInicioComida ?? 12;
    int minInicio  = perfil?.minInicioComida  ?? 0;
    int horaFin    = perfil?.horaFinComida    ?? 20;
    int minFin     = perfil?.minFinComida     ?? 0;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Color(0xFF182318),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⏱️ Mi ventana de alimentación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('KETORA usará este horario para tu contador de ayuno', style: TextStyle(fontSize: 13, color: Color(0xFF8FAF8F))),
              const SizedBox(height: 20),

              // Hora de inicio (rompo el ayuno)
              _SelectorHora(
                label: '🍽️ Rompo el ayuno a las',
                hora: horaInicio, min: minInicio,
                onChanged: (h, m) => setS(() { horaInicio = h; minInicio = m; }),
              ),
              const SizedBox(height: 16),

              // Hora de fin (última comida)
              _SelectorHora(
                label: '🌙 Última comida a las',
                hora: horaFin, min: minFin,
                onChanged: (h, m) => setS(() { horaFin = h; minFin = m; }),
              ),
              const SizedBox(height: 12),

              // Resumen
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF0D1510), borderRadius: BorderRadius.circular(12)),
                child: Builder(builder: (_) {
                  final ini = '${horaInicio.toString().padLeft(2,'0')}:${minInicio.toString().padLeft(2,'0')}';
                  final fin = '${horaFin.toString().padLeft(2,'0')}:${minFin.toString().padLeft(2,'0')}';
                  final mins = (horaFin * 60 + minFin) <= (horaInicio * 60 + minInicio)
                      ? (horaFin * 60 + minFin + 1440) - (horaInicio * 60 + minInicio)
                      : (horaFin * 60 + minFin) - (horaInicio * 60 + minInicio);
                  final horasComida = (mins / 60).toStringAsFixed(1);
                  final horasAyuno  = (24 - mins / 60).toStringAsFixed(1);
                  return Text(
                    'Ventana de comidas: $ini → $fin ($horasComida h)\nAyuno: $horasAyuno horas',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8FAF8F), height: 1.5),
                  );
                }),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final uid = sl<PerfilService>().perfilActual?.uid ?? '';
                    final base = sl<PerfilService>().perfilActual;
                    if (base == null || uid.isEmpty) { Navigator.pop(ctx); return; }
                    final updated = base.copyWith(
                      horaInicioComida: horaInicio,
                      minInicioComida:  minInicio,
                      horaFinComida:    horaFin,
                      minFinComida:     minFin,
                    );
                    await sl<PerfilService>().guardarPerfil(updated);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('✓ Ventana de alimentación actualizada'),
                        backgroundColor: AppColors.verde,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  child: const Text('Guardar mi ventana'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarLimpiarDia(BuildContext context, HoyBloc bloc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF182318),
        title: const Text('¿Limpiar registro de hoy?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text('Se eliminarán todos los alimentos registrados hoy. Esta acción no se puede deshacer.',
          style: TextStyle(color: Color(0xFF8FAF8F))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8FAF8F)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              // Eliminar uno por uno
              for (final a in datos.registro.alimentos) {
                bloc.add(HoyEliminarAlimento(a.id));
              }
            },
            child: const Text('Limpiar todo'),
          ),
        ],
      ),
    );
  }

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return '¡Buenos días';
    if (h < 19) return '¡Buenas tardes';
    return '¡Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final reg = datos.registro;
    final obj = datos.objetivos;

    // Calcular porcentajes de macros
    final calConsumidas = reg.caloriasTotal.toDouble();
    final calMeta = obj.caloriasObjetivo.toDouble();
    final pctCal = (calMeta > 0) ? (calConsumidas / calMeta).clamp(0.0, 1.0) : 0.0;

    final grasMeta = obj.grasasObjetivoG.toDouble();
    final protMeta = obj.proteinaObjetivoG.toDouble();
    final carbMeta = obj.carbosObjetivoG.toDouble();
    final pctGras = (grasMeta > 0) ? (reg.grasasTotal / grasMeta).clamp(0.0, 1.0) : 0.0;
    final pctProt = (protMeta > 0) ? (reg.proteinaTotal / protMeta).clamp(0.0, 1.0) : 0.0;
    final pctCarb = (carbMeta > 0) ? (reg.carbosTotal / carbMeta).clamp(0.0, 1.0) : 0.0;

    final aguaMl = reg.aguaMl;
    final aguaMeta = obj.aguaObjetivoMl;
    final pctAgua = (aguaMeta > 0) ? (aguaMl / aguaMeta).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.negro,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 195,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF000000),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        // Logo ocupa todo — desde arriba
                        Positioned.fill(
                          top: -20,
                          bottom: 20,
                          right: 12,
                          child: Image.asset(
                            'assets/images/logo_horizontal.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.topLeft,
                          ),
                        ),
                        // Íconos flotando arriba a la derecha
                        Positioned(
                          top: 0,
                          right: 12,
                          child: Row(
                            children: [
                              _HeaderIcon(icon: Icons.notifications_outlined),
                              const SizedBox(width: 6),
                              _HeaderIcon(
                                icon: Icons.person_outline,
                                onTap: () => context.push(AppRoutes.perfil),
                              ),
                            ],
                          ),
                        ),
                        // Saludo abajo
                        Positioned(
                          bottom: 20,
                          left: 16,
                          child: Text(
                            '${_saludo()}, ${sl<PerfilService>().perfilActual?.nombre ?? FirebaseAuth.instance.currentUser?.displayName ?? 'amigo'}! 👋',
                            style: const TextStyle(
                              color: AppColors.blanco,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Card Calorías + Macros ───────────────────────────
          SliverToBoxAdapter(
            child: _Card(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Resumen del día',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.fondoVerde,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Builder(builder: (context) {
                          final restantes = (calMeta - calConsumidas).round();
                          final excedido = restantes < 0;
                          return Text(
                            excedido ? '${restantes.abs()} kcal excedidas' : '$restantes kcal disponibles',
                            style: TextStyle(fontSize: 13, color: excedido ? const Color(0xFFEF4444) : AppColors.verde, fontWeight: FontWeight.w700),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Anillo de calorías — muestra las que quedan
                      Builder(builder: (context) {
                        final restantes = calMeta - calConsumidas;
                        final excedido = restantes < 0;
                        final pctRestante = excedido ? 1.0 : (restantes / calMeta).clamp(0.0, 1.0);
                        final colorAnillo = excedido ? const Color(0xFFEF4444) : Colors.white;
                        return CircularPercentIndicator(
                          radius: 60,
                          lineWidth: 10,
                          percent: pctRestante,
                          animation: true,
                          animationDuration: 800,
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: const Color(0xFF3A5A3A),
                          progressColor: colorAnillo,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(excedido ? '+${restantes.abs().round()}' : '${restantes.round()}',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: colorAnillo)),
                              Text(excedido ? 'excedido' : 'kcal left',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8FAF8F))),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(width: 20),
                      // Barras de macros
                      Expanded(
                        child: Column(
                          children: [
                            _MacroBar(
                              label: 'Grasas',
                              valor: '${reg.grasasTotal.round()}g',
                              meta: '${grasMeta.round()}g',
                              pct: pctGras,
                              color: AppColors.macroGrasas,
                            ),
                            const SizedBox(height: 10),
                            _MacroBar(
                              label: 'Proteína',
                              valor: '${reg.proteinaTotal.round()}g',
                              meta: '${protMeta.round()}g',
                              pct: pctProt,
                              color: AppColors.macroProtein,
                            ),
                            const SizedBox(height: 10),
                            _MacroBar(
                              label: 'Carbos netos',
                              valor: '${reg.carbosTotal.round()}g',
                              meta: '${carbMeta.round()}g',
                              pct: pctCarb,
                              color: AppColors.macroCarbos,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Timer de Ayuno ───────────────────────────────────
          SliverToBoxAdapter(
            child: Builder(
              builder: (ctx) {
                final bloc = ctx.read<HoyBloc>();
                final perfil = sl<PerfilService>().perfilActual;
                return _AyunoCard(
                  activo: reg.ayunoActivo,
                  duracion: reg.duracionAyuno,
                  onTap: () => bloc.add(reg.ayunoActivo ? HoyRomperAyuno() : HoyIniciarAyuno()),
                  horaInicioComida: perfil?.horaInicioComida ?? 12,
                  minInicioComida:  perfil?.minInicioComida  ?? 0,
                  horaFinComida:    perfil?.horaFinComida    ?? 20,
                  minFinComida:     perfil?.minFinComida     ?? 0,
                  onEditarVentana: () => _mostrarConfigVentana(ctx),
                );
              },
            ),
          ),

          // ── Hidratación ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Builder(
              builder: (ctx) {
                final bloc = ctx.read<HoyBloc>();
                return _Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircularPercentIndicator(
                          radius: 28,
                          lineWidth: 6,
                          percent: pctAgua,
                          animation: true,
                          circularStrokeCap: CircularStrokeCap.round,
                          backgroundColor: const Color(0xFF3A5A7A),
                          progressColor: const Color(0xFF60C8F5),
                          center: const Icon(Icons.water_drop, color: Color(0xFF60C8F5), size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hidratación del día', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('$aguaMl ml de $aguaMeta ml',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
                          ],
                        )),
                      ]),
                      const SizedBox(height: 12),
                      // Botones de bebidas
                      Row(children: [
                        _BebidaBtn('💧', 'Agua', 250, () => bloc.add(const HoyAgregarAgua(mililitros: 250))),
                        const SizedBox(width: 8),
                        _BebidaBtn('☕', 'Café', 240, () => bloc.add(const HoyAgregarAgua(mililitros: 240))),
                        const SizedBox(width: 8),
                        _BebidaBtn('🍵', 'Té', 240, () => bloc.add(const HoyAgregarAgua(mililitros: 240))),
                        const SizedBox(width: 8),
                        _BebidaBtn('🥥', 'L.Coco', 200, () => bloc.add(const HoyAgregarAgua(mililitros: 200))),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Comidas ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Text('Registrado hoy',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  const Spacer(),
                  if (reg.alimentos.isNotEmpty) ...[
                    Text('${reg.alimentos.length} items',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8FAF8F))),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _confirmarLimpiarDia(context, context.read<HoyBloc>()),
                      child: const Text('Limpiar todo',
                        style: TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                    ),
                  ] else
                    const Text('Desliza ← para eliminar',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4A6B4A))),
                ],
              ),
            ),
          ),

          if (reg.alimentos.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF182318),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A3D2A)),
                ),
                child: const Column(
                  children: [
                    Text('🍽️', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 12),
                    Text('Aún no has registrado nada hoy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 6),
                    Text('Toca el botón + para agregar tu primera comida del día',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF8FAF8F), height: 1.4)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final a = reg.alimentos[i];
                  // Emoji según el tipo de comida
                  final emoji = _emojiAlimento(a.nombre);
                  return Dismissible(
                    key: ValueKey(a.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
                    ),
                    onDismissed: (_) {
                      ctx.read<HoyBloc>().add(HoyEliminarAlimento(a.id));
                    },
                    child: _ComidaPlaceholder(
                      emoji: emoji,
                      titulo: a.nombre,
                      desc: '${a.cantidadG.round()}g · ${a.comida}',
                      kcal: '${a.calorias.round()} kcal',
                      hora: '',
                    ),
                  );
                },
                childCount: reg.alimentos.length,
              ),
            ),

          // ── Acceso rápido ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Text('Acceso rápido',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _AccesoRapidoCard(
                      emoji: '💪',
                      titulo: 'Ejercicio',
                      subtitulo: 'Rutinas keto',
                      color: AppColors.fondoNaranja,
                      borderColor: AppColors.oro,
                      onTap: () => context.go(AppRoutes.ejercicio),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AccesoRapidoCard(
                      emoji: '🤖',
                      titulo: 'Pregunta a GEM',
                      subtitulo: 'Coach IA 24/7',
                      color: AppColors.fondoVerde,
                      borderColor: AppColors.verde,
                      onTap: () => context.go(AppRoutes.gem),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _AccesoRapidoCard(
                      emoji: '🩸',
                      titulo: 'Glucosa',
                      subtitulo: 'Control glucémico',
                      color: AppColors.fondoAzul,
                      borderColor: AppColors.info,
                      onTap: () => context.push(AppRoutes.glucosa),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AccesoRapidoCard(
                      emoji: '📈',
                      titulo: 'Mi Progreso',
                      subtitulo: 'Peso y medidas',
                      color: AppColors.fondoGris,
                      borderColor: AppColors.textSecondary,
                      onTap: () => context.go(AppRoutes.progreso),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _AccesoRapidoCard extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const _AccesoRapidoCard({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(subtitulo, style: const TextStyle(fontSize: 14, color: Color(0xFF8FAF8F))),
          ],
        ),
      ),
    );
  }
}

// ── Widgets de apoyo ─────────────────────────────────────────────────────────

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _HeaderIcon({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.blanco, size: 20),
      ),
    );
  }
}

class _SelectorHora extends StatelessWidget {
  final String label;
  final int hora, min;
  final void Function(int h, int m) onChanged;
  const _SelectorHora({required this.label, required this.hora, required this.min, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 8),
      Row(children: [
        // Hora
        Expanded(child: GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: hora, minute: min),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: Color(0xFF7CB518)),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked.hour, picked.minute);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1510),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7CB518).withOpacity(0.4)),
            ),
            child: Text(
              '${hora.toString().padLeft(2,'0')}:${min.toString().padLeft(2,'0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF7CB518)),
            ),
          ),
        )),
        const SizedBox(width: 12),
        const Text('Toca para cambiar', style: TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
      ]),
    ],
  );
}

class _BebidaBtn extends StatelessWidget {
  final String emoji, label;
  final int ml;
  final VoidCallback onTap;
  const _BebidaBtn(this.emoji, this.label, this.ml, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1510),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF60C8F5).withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
          Text('${ml}ml', style: const TextStyle(fontSize: 10, color: Color(0xFF60C8F5))),
        ]),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  const _Card({required this.child, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF182318),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A3D2A), width: 1),
      ),
      child: child,
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final String valor;
  final String meta;
  final double pct;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.valor,
    required this.meta,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8FAF8F), fontWeight: FontWeight.w500)),
            ),
            Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            Text(' / $meta', style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
          ],
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          lineHeight: 6,
          percent: pct,
          padding: EdgeInsets.zero,
          animation: true,
          animationDuration: 800,
          backgroundColor: AppColors.fondoGris,
          progressColor: color,
          barRadius: const Radius.circular(4),
        ),
      ],
    );
  }
}

class _AyunoCard extends StatefulWidget {
  final bool activo;
  final Duration? duracion;
  final VoidCallback onTap;
  final int horaInicioComida, minInicioComida, horaFinComida, minFinComida;
  final VoidCallback onEditarVentana;
  const _AyunoCard({
    required this.activo,
    required this.duracion,
    required this.onTap,
    required this.onEditarVentana,
    this.horaInicioComida = 12,
    this.minInicioComida  = 0,
    this.horaFinComida    = 20,
    this.minFinComida     = 0,
  });

  @override
  State<_AyunoCard> createState() => _AyunoCardState();
}

class _AyunoCardState extends State<_AyunoCard> {
  late Timer _timer;
  late Duration _duracion;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _activo = widget.activo;
    _duracion = widget.duracion ?? Duration.zero;
    _aplicarTimer();
  }

  void _aplicarTimer() {
    if (_activo) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _duracion += const Duration(seconds: 1));
      });
    } else {
      _timer = Timer(Duration.zero, () {});
    }
  }

  void _handleTap() {
    _timer.cancel();
    setState(() {
      _activo = !_activo;
      _duracion = Duration.zero;
    });
    _aplicarTimer();
    widget.onTap(); // persiste en Firestore en background
  }

  @override
  void didUpdateWidget(_AyunoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincroniza solo si Firestore devuelve un valor diferente al local
    if (widget.activo != oldWidget.activo && widget.activo != _activo) {
      _timer.cancel();
      _activo = widget.activo;
      _duracion = widget.duracion ?? Duration.zero;
      _aplicarTimer();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fechaHoy() {
    final d = DateTime.now();
    const dias = ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
    const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${dias[d.weekday % 7]}, ${d.day} ${meses[d.month - 1]}';
  }

  String _formato(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    const metaHoras = 16;
    final pct = (_duracion.inSeconds / (metaHoras * 3600)).clamp(0.0, 1.0);
    final horasRestantes = metaHoras - _duracion.inHours;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.verdeOs.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onEditarVentana,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timer_outlined, color: Color(0xFFEF4444), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ayuno intermitente',
                    style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(_fechaHoy(),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(
                    '🍽️ ${widget.horaInicioComida.toString().padLeft(2,'0')}:${widget.minInicioComida.toString().padLeft(2,'0')} — 🌙 ${widget.horaFinComida.toString().padLeft(2,'0')}:${widget.minFinComida.toString().padLeft(2,'0')}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _handleTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _activo ? Colors.white.withValues(alpha: 0.15) : AppColors.oro,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _activo ? 'Romper' : 'Iniciar',
                    style: TextStyle(
                      color: _activo ? AppColors.blanco : AppColors.verdeOs,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timer grande
          Center(
            child: Text(_formato(_duracion),
              style: const TextStyle(
                color: AppColors.blanco,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Barra de progreso con milestones
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              LinearPercentIndicator(
                lineHeight: 8,
                percent: pct,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                progressColor: AppColors.oro,
                barRadius: const Radius.circular(4),
              ),
              // Milestones
              ...[12, 14, 16].map((h) {
                final pos = h / metaHoras;
                return Positioned(
                  left: MediaQuery.of(context).size.width * pos * 0.72,
                  child: Column(
                    children: [
                      Container(width: 2, height: 8, color: Colors.white.withValues(alpha: 0.4)),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MilestoneLabel(horas: 0, label: 'Inicio'),
              _MilestoneLabel(horas: 12, label: 'Cetosis'),
              _MilestoneLabel(horas: 14, label: 'Óptimo'),
              _MilestoneLabel(horas: 16, label: 'Meta'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneLabel extends StatelessWidget {
  final int horas;
  final String label;
  const _MilestoneLabel({required this.horas, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${horas}h', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ComidaPlaceholder extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String desc;
  final String kcal;
  final String hora;
  const _ComidaPlaceholder({
    required this.emoji,
    required this.titulo,
    required this.desc,
    required this.kcal,
    required this.hora,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.fondoVerde,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D3B1E))),
                    if (hora.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(hora, style: const TextStyle(fontSize: 13, color: Color(0xFF4A6B4A))),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF1A5C2A))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(kcal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.verde)),
              const SizedBox(height: 2),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
