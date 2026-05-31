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
                        child: Text('${(calMeta - calConsumidas).round()} kcal restantes',
                          style: const TextStyle(fontSize: 14, color: AppColors.verde, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Anillo de calorías
                      CircularPercentIndicator(
                        radius: 60,
                        lineWidth: 10,
                        percent: pctCal,
                        animation: true,
                        animationDuration: 800,
                        circularStrokeCap: CircularStrokeCap.round,
                        backgroundColor: const Color(0xFFE5E5E5),
                        progressColor: Colors.white,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${calConsumidas.round()}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                            const Text('kcal', style: TextStyle(fontSize: 13, color: Color(0xFF8FAF8F))),
                          ],
                        ),
                      ),
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
                return _AyunoCard(
                  activo: reg.ayunoActivo,
                  duracion: reg.duracionAyuno,
                  onTap: () => bloc.add(reg.ayunoActivo ? HoyRomperAyuno() : HoyIniciarAyuno()),
                );
              },
            ),
          ),

          // ── Agua ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Builder(
              builder: (ctx) {
                final bloc = ctx.read<HoyBloc>();
                return _Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 30,
                        lineWidth: 6,
                        percent: pctAgua,
                        animation: true,
                        circularStrokeCap: CircularStrokeCap.round,
                        backgroundColor: const Color(0xFF3A5A7A),
                        progressColor: const Color(0xFF60C8F5),
                        center: const Icon(Icons.water_drop, color: Color(0xFF60C8F5), size: 16),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Agua', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                            Text('$aguaMl ml de $aguaMeta ml',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF8FAF8F))),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final lleno = (aguaMl / 500) > i;
                          return Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Icon(
                              lleno ? Icons.water_drop : Icons.water_drop_outlined,
                              color: lleno ? AppColors.info : AppColors.textHint,
                              size: 13,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => bloc.add(const HoyAgregarAgua()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.fondoAzul,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('+250ml', style: TextStyle(fontSize: 14, color: AppColors.info, fontWeight: FontWeight.w600)),
                        ),
                      ),
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
                  Text('${reg.alimentos.isEmpty ? 3 : reg.alimentos.length} comidas',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF8FAF8F))),
                ],
              ),
            ),
          ),

          if (reg.alimentos.isEmpty)
            const SliverList(
              delegate: SliverChildListDelegate.fixed([
                _ComidaPlaceholder(emoji: '🍳', titulo: 'Desayuno', desc: 'Huevos revueltos con aguacate', kcal: '420 kcal', hora: '8:00'),
                _ComidaPlaceholder(emoji: '🥗', titulo: 'Almuerzo', desc: 'Ensalada César con pollo', kcal: '580 kcal', hora: '13:30'),
                _ComidaPlaceholder(emoji: '🐟', titulo: 'Cena', desc: 'Salmón con brócoli al vapor', kcal: '620 kcal', hora: '20:00'),
              ]),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final a = reg.alimentos[i];
                  // Emoji según el tipo de comida
                  final emoji = switch (a.comida) {
                    'desayuno' => '🍳',
                    'almuerzo' => '🥗',
                    'cena'     => '🐟',
                    _          => '🍽️',
                  };
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
            Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8FAF8F), fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(valor, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            Text(' / $meta', style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
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
  const _AyunoCard({required this.activo, required this.duracion, required this.onTap});

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer_outlined, color: AppColors.blanco, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ayuno 16:8',
                    style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    widget.activo
                      ? (horasRestantes > 0 ? '$horasRestantes h para la meta' : '¡Meta alcanzada! 🎉')
                      : 'Toca iniciar para activar',
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
