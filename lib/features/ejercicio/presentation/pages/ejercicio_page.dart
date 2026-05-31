import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';

/// Pantalla de Ejercicio — rutinas keto para principiantes
class EjercicioPage extends StatefulWidget {
  const EjercicioPage({super.key});

  @override
  State<EjercicioPage> createState() => _EjercicioPageState();
}

class _EjercicioPageState extends State<EjercicioPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _equipoSelec = 'Sin equipo';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
            expandedHeight: 150,
            pinned: true,
            backgroundColor: AppColors.verdeOs,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.blanco),
              onPressed: () => context.go(AppRoutes.hoy),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF064E3B), AppColors.verde],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('KETORA',
                              style: TextStyle(color: Colors.white54, fontSize: 12,
                                fontWeight: FontWeight.w700, letterSpacing: 2)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Semana 2 💪',
                                style: TextStyle(color: AppColors.blanco, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('Ejercicio Keto',
                          style: TextStyle(color: AppColors.blanco, fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('Rutinas adaptadas a tu metabolismo keto 🔥',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                color: const Color(0xFF064E3B),
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppColors.oro,
                  indicatorWeight: 3,
                  labelColor: AppColors.blanco,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Rutinas'),
                    Tab(text: 'Keto Tips'),
                    Tab(text: 'Hoy'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _RutinasTab(
              equipoSelec: _equipoSelec,
              onEquipoChange: (v) => setState(() => _equipoSelec = v),
            ),
            const _KetoTipsTab(),
            const _HoyTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — RUTINAS
// ─────────────────────────────────────────────────────────────────────────────
class _RutinasTab extends StatelessWidget {
  final String equipoSelec;
  final ValueChanged<String> onEquipoChange;

  const _RutinasTab({required this.equipoSelec, required this.onEquipoChange});

  static final _rutinas = {
    'Sin equipo': [
      _Rutina(
        nombre: 'HIIT Keto Mañana',
        duracion: '20 min',
        nivel: 'Principiante',
        emoji: '🔥',
        color: AppColors.fondoNaranja,
        descripcion: 'Circuito de 4 ejercicios. Ideal para hacer en cetosis, quema grasa sin músculo.',
        ejercicios: [
          _Ejercicio('Jumping Jacks', '30 seg', '10 seg desc', '🤸'),
          _Ejercicio('Sentadillas', '30 seg', '10 seg desc', '🦵'),
          _Ejercicio('Push-ups', '30 seg', '10 seg desc', '💪'),
          _Ejercicio('Plancha', '30 seg', '10 seg desc', '🧘'),
          _Ejercicio('Burpees modificados', '30 seg', '10 seg desc', '⚡'),
        ],
      ),
      _Rutina(
        nombre: 'Caminata cetogénica',
        duracion: '30 min',
        nivel: 'Principiante',
        emoji: '🚶',
        color: AppColors.fondoVerde,
        descripcion: 'Caminata a paso moderado. El ejercicio más keto-friendly. Máxima quema de grasa.',
        ejercicios: [
          _Ejercicio('Calentamiento', '5 min', 'Camina despacio', '🦶'),
          _Ejercicio('Caminata activa', '20 min', 'Ritmo moderado', '🚶'),
          _Ejercicio('Enfriamiento', '5 min', 'Camina despacio', '🧘'),
        ],
      ),
      _Rutina(
        nombre: 'Yoga keto',
        duracion: '25 min',
        nivel: 'Principiante',
        emoji: '🧘',
        color: AppColors.fondoAzul,
        descripcion: 'Posturas suaves. Reduce cortisol (enemigo de la cetosis) y mejora flexibilidad.',
        ejercicios: [
          _Ejercicio('Perro mirando abajo', '1 min', '', '🐕'),
          _Ejercicio('Guerrero I', '1 min c/lado', '', '⚔️'),
          _Ejercicio('Postura del niño', '2 min', '', '🧒'),
          _Ejercicio('Torsión espinal', '1 min c/lado', '', '🌀'),
          _Ejercicio('Savasana', '5 min', 'Relajación total', '😴'),
        ],
      ),
    ],
    'Mancuernas': [
      _Rutina(
        nombre: 'Fuerza keto — Upper',
        duracion: '35 min',
        nivel: 'Intermedio',
        emoji: '💪',
        color: AppColors.fondoAzul,
        descripcion: 'Tren superior con mancuernas. Preserva músculo mientras quemas grasa keto.',
        ejercicios: [
          _Ejercicio('Press de pecho', '3×12', '60 seg desc', '🏋️'),
          _Ejercicio('Remo con mancuerna', '3×12 c/lado', '60 seg desc', '🚣'),
          _Ejercicio('Press de hombros', '3×10', '60 seg desc', '🏋️'),
          _Ejercicio('Curl de bíceps', '3×12', '60 seg desc', '💪'),
          _Ejercicio('Extensión de tríceps', '3×12', '60 seg desc', '💪'),
        ],
      ),
      _Rutina(
        nombre: 'Fuerza keto — Lower',
        duracion: '35 min',
        nivel: 'Intermedio',
        emoji: '🦵',
        color: AppColors.fondoNaranja,
        descripcion: 'Tren inferior. Los músculos grandes queman más grasa — perfectos para keto.',
        ejercicios: [
          _Ejercicio('Sentadilla goblet', '3×12', '60 seg desc', '🏋️'),
          _Ejercicio('Zancadas', '3×10 c/lado', '60 seg desc', '🦵'),
          _Ejercicio('Peso muerto rumano', '3×12', '60 seg desc', '🏋️'),
          _Ejercicio('Elevación de talones', '3×15', '45 seg desc', '🦶'),
          _Ejercicio('Puente de glúteos', '3×15', '45 seg desc', '🍑'),
        ],
      ),
    ],
    'Gimnasio': [
      _Rutina(
        nombre: 'Full body keto',
        duracion: '45 min',
        nivel: 'Intermedio',
        emoji: '🏟️',
        color: AppColors.fondoVerde,
        descripcion: 'Sesión completa de gimnasio optimizada para keto. Combina fuerza y cardio.',
        ejercicios: [
          _Ejercicio('Sentadilla con barra', '4×8', '90 seg desc', '🏋️'),
          _Ejercicio('Press banca', '4×8', '90 seg desc', '🏋️'),
          _Ejercicio('Peso muerto', '3×6', '2 min desc', '💪'),
          _Ejercicio('Remo en máquina', '3×12', '60 seg desc', '🚣'),
          _Ejercicio('Cardio LISS', '15 min', 'Intensidad baja', '🏃'),
        ],
      ),
    ],
    'Caminadora': [
      _Rutina(
        nombre: 'Cardio LISS keto',
        duracion: '30 min',
        nivel: 'Principiante',
        emoji: '🚶',
        color: AppColors.fondoVerde,
        descripcion: 'Caminata en caminadora a baja intensidad. Zona de quema de grasa ideal para keto.',
        ejercicios: [
          _Ejercicio('Calentamiento', '5 min', '3.5 km/h plano', '🦶'),
          _Ejercicio('Caminata activa', '20 min', '5 km/h inclinación 3%', '🚶'),
          _Ejercicio('Intervalos suaves', '5 min', 'Alterna 4 y 6 km/h', '⚡'),
        ],
      ),
      _Rutina(
        nombre: 'Intervalos caminadora',
        duracion: '25 min',
        nivel: 'Intermedio',
        emoji: '🏃',
        color: AppColors.fondoNaranja,
        descripcion: 'Intervalos de trote y caminata. Potencia la cetosis y quema grasa post-ejercicio.',
        ejercicios: [
          _Ejercicio('Calentamiento', '3 min', '4 km/h', '🦶'),
          _Ejercicio('Trote moderado', '1 min', '7 km/h', '🏃'),
          _Ejercicio('Caminata recuperación', '2 min', '4 km/h', '🚶'),
          _Ejercicio('Repite 6 veces', '18 min', 'Trote + caminata', '🔁'),
          _Ejercicio('Enfriamiento', '4 min', '3 km/h', '🧘'),
        ],
      ),
    ],
    'Bicicleta': [
      _Rutina(
        nombre: 'Pedaleo keto constante',
        duracion: '30 min',
        nivel: 'Principiante',
        emoji: '🚴',
        color: AppColors.fondoAzul,
        descripcion: 'Pedaleo suave y constante. Ideal para quemar grasa en cetosis sin agotar el glucógeno.',
        ejercicios: [
          _Ejercicio('Calentamiento', '5 min', 'Resistencia baja', '🦶'),
          _Ejercicio('Pedaleo constante', '20 min', 'Resistencia media', '🚴'),
          _Ejercicio('Enfriamiento', '5 min', 'Resistencia mínima', '🧘'),
        ],
      ),
      _Rutina(
        nombre: 'Tabata en bici',
        duracion: '20 min',
        nivel: 'Intermedio',
        emoji: '⚡',
        color: AppColors.fondoNaranja,
        descripcion: 'Explosiones de velocidad máxima. Activa hormonas de quema de grasa durante 24h.',
        ejercicios: [
          _Ejercicio('Calentamiento', '5 min', 'Ritmo suave', '🦶'),
          _Ejercicio('Sprint máximo', '20 seg', 'Resistencia alta', '🚴'),
          _Ejercicio('Recuperación', '10 seg', 'Pedaleo suave', '😮‍💨'),
          _Ejercicio('Repite 8 rondas', '4 min', 'Sprint + descanso', '🔁'),
          _Ejercicio('Enfriamiento', '5 min', 'Resistencia mínima', '🧘'),
        ],
      ),
    ],
    'Elíptica': [
      _Rutina(
        nombre: 'Cardio elíptica keto',
        duracion: '35 min',
        nivel: 'Principiante',
        emoji: '🔄',
        color: AppColors.fondoVerde,
        descripcion: 'Sin impacto en articulaciones. Perfecto para empezar keto sin lesionarse.',
        ejercicios: [
          _Ejercicio('Calentamiento', '5 min', 'Resistencia 1-2', '🦶'),
          _Ejercicio('Ritmo constante', '25 min', 'Resistencia 4-5', '🔄'),
          _Ejercicio('Enfriamiento', '5 min', 'Resistencia mínima', '🧘'),
        ],
      ),
      _Rutina(
        nombre: 'Elíptica inversa + intervalos',
        duracion: '28 min',
        nivel: 'Intermedio',
        emoji: '💪',
        color: AppColors.fondoAzul,
        descripcion: 'Combina marcha normal e inversa. Activa más grupos musculares para mayor quema de grasa.',
        ejercicios: [
          _Ejercicio('Marcha normal', '5 min', 'Resistencia 3', '🔄'),
          _Ejercicio('Marcha inversa', '3 min', 'Resistencia 3', '🔁'),
          _Ejercicio('Sprint 30 seg', '30 seg', 'Resistencia máxima', '⚡'),
          _Ejercicio('Recuperación 1 min', '1 min', 'Resistencia 2', '😮‍💨'),
          _Ejercicio('Repite 6 veces', '9 min', 'Sprint + recuperación', '🔁'),
          _Ejercicio('Enfriamiento', '5 min', 'Resistencia 1', '🧘'),
        ],
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final rutinas = _rutinas[equipoSelec] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Selector de equipo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blanco,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Qué equipo tienes?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Sin equipo', 'Mancuernas', 'Caminadora', 'Bicicleta', 'Elíptica', 'Gimnasio'].map((eq) {
                  final sel = eq == equipoSelec;
                  return GestureDetector(
                    onTap: () => onEquipoChange(eq),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.verde : AppColors.fondoGris,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(eq,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? AppColors.blanco : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Aviso keto
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.fondoOro,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.oro.withValues(alpha: 0.4), width: 1),
          ),
          child: const Row(children: [
            Text('⚡', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Expanded(child: Text(
              'En keto tu cuerpo usa grasa como combustible. Ejercicio de baja-media intensidad = máxima quema de grasa.',
              style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.5),
            )),
          ]),
        ),
        const SizedBox(height: 16),

        // Rutinas
        ...rutinas.map((r) => _RutinaCard(rutina: r)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _Rutina {
  final String nombre;
  final String duracion;
  final String nivel;
  final String emoji;
  final Color color;
  final String descripcion;
  final List<_Ejercicio> ejercicios;
  const _Rutina({
    required this.nombre, required this.duracion, required this.nivel,
    required this.emoji, required this.color, required this.descripcion,
    required this.ejercicios,
  });
}

class _Ejercicio {
  final String nombre;
  final String series;
  final String desc;
  final String emoji;
  const _Ejercicio(this.nombre, this.series, this.desc, this.emoji);
}

class _RutinaCard extends StatelessWidget {
  final _Rutina rutina;
  const _RutinaCard({required this.rutina});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RutinaDetalle(rutina: rutina),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.blanco,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: rutina.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Text(rutina.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(rutina.nombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _Chip(rutina.duracion, AppColors.verdeOs),
                      const SizedBox(width: 6),
                      _Chip(rutina.nivel, AppColors.info),
                    ]),
                  ],
                )),
                const Icon(Icons.play_circle_filled_rounded, color: AppColors.verde, size: 36),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Text(rutina.descripcion,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _RutinaDetalle extends StatelessWidget {
  final _Rutina rutina;
  const _RutinaDetalle({required this.rutina});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        Container(
          color: AppColors.blanco,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Text(rutina.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rutina.nombre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Row(children: [
                  _Chip(rutina.duracion, AppColors.verde),
                  const SizedBox(width: 6),
                  _Chip(rutina.nivel, AppColors.info),
                ]),
              ])),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(rutina.descripcion,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
              const SizedBox(height: 16),
              const Text('Ejercicios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              ...rutina.ejercicios.asMap().entries.map((e) => _EjercicioRow(
                num: e.key + 1,
                ejercicio: e.value,
              )),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  foregroundColor: AppColors.blanco,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Iniciar rutina', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ]),
    );
  }
}

class _EjercicioRow extends StatelessWidget {
  final int num;
  final _Ejercicio ejercicio;
  const _EjercicioRow({required this.num, required this.ejercicio});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(color: AppColors.fondoVerde, shape: BoxShape.circle),
          child: Center(child: Text('$num',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.verde))),
        ),
        const SizedBox(width: 12),
        Text(ejercicio.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ejercicio.nombre,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (ejercicio.desc.isNotEmpty)
            Text(ejercicio.desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text(ejercicio.series,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.verde)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — KETO TIPS
// ─────────────────────────────────────────────────────────────────────────────
class _KetoTipsTab extends StatelessWidget {
  const _KetoTipsTab();

  static const _tips = [
    _Tip('⚡', 'Ejercicio en ayunas',
      'Hacer cardio ligero en ayunas potencia la quema de grasa. Tu cuerpo ya está en modo cetosis — aprovéchalo.',
      AppColors.fondoOro),
    _Tip('🕐', 'Timing es todo',
      'El mejor momento para ejercitarte es 1-2 horas antes de romper el ayuno. Tu rendimiento será máximo.',
      AppColors.fondoVerde),
    _Tip('💧', 'Hidratación extra',
      'En keto pierdes más electrolitos al hacer ejercicio. Toma agua con sal, magnesio o electrolitos antes.',
      AppColors.fondoAzul),
    _Tip('🏃', 'LISS > HIIT al principio',
      'Los primeros 4-6 semanas, prefiere cardio de baja intensidad. Tu cuerpo aún se adapta al keto.',
      AppColors.fondoGris),
    _Tip('🥩', 'Proteína post-entreno',
      'Come proteína en la hora siguiente al ejercicio. Evita carbohidratos — no los necesitas en keto.',
      AppColors.fondoNaranja),
    _Tip('😴', 'Recuperación',
      'El sueño es cuando tu cuerpo quema más grasa. 7-9 horas de sueño = mejores resultados keto.',
      AppColors.fondoVerde),
    _Tip('📉', 'No te excedas',
      'Ejercicio excesivo aumenta el cortisol, que bloquea la cetosis. 3-4 sesiones/semana es ideal.',
      AppColors.fondoRojo),
    _Tip('🧠', 'Claridad mental',
      'Las cetonas son el mejor combustible para tu cerebro. Muchos sienten mayor claridad mental al hacer ejercicio en keto.',
      AppColors.fondoAzul),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._tips.map((t) => _TipCard(tip: t)),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _Tip {
  final String emoji;
  final String titulo;
  final String contenido;
  final Color color;
  const _Tip(this.emoji, this.titulo, this.contenido, this.color);
}

class _TipCard extends StatelessWidget {
  final _Tip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: tip.color, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(tip.emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tip.titulo,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(tip.contenido,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — HOY (rutina del día)
// ─────────────────────────────────────────────────────────────────────────────
class _HoyTab extends StatelessWidget {
  const _HoyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rutina del día
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), AppColors.verde],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Rutina de hoy', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 6),
            const Text('HIIT Keto Mañana', style: TextStyle(color: AppColors.blanco, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('20 min · Principiante · Sin equipo',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.oro,
                    foregroundColor: AppColors.verdeOs,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: const Text('▶ Iniciar ahora', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats semanales
        const Text('Esta semana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatBox('2', 'Sesiones', Icons.fitness_center_rounded, AppColors.verde)),
          const SizedBox(width: 12),
          Expanded(child: _StatBox('55 min', 'Total', Icons.timer_rounded, AppColors.info)),
          const SizedBox(width: 12),
          Expanded(child: _StatBox('420', 'kcal', Icons.local_fire_department_rounded, AppColors.oro)),
        ]),
        const SizedBox(height: 20),

        // Días de la semana
        const Text('Registro semanal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].asMap().entries.map((e) {
            final completado = e.key < 2;
            final hoy = e.key == 2;
            return Column(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: completado ? AppColors.verde : (hoy ? AppColors.verdeClaro : AppColors.fondoGris),
                  shape: BoxShape.circle,
                  border: hoy ? Border.all(color: AppColors.verde, width: 2) : null,
                ),
                child: Center(child: completado
                  ? const Icon(Icons.check_rounded, color: AppColors.blanco, size: 18)
                  : Text(e.value, style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: hoy ? AppColors.verde : AppColors.textHint))),
              ),
            ]);
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Consejo del día
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fondoVerde,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.verde.withValues(alpha: 0.2)),
          ),
          child: const Row(children: [
            Text('🥑', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Consejo de GEM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.verdeOs)),
              SizedBox(height: 4),
              Text('Hoy es día de HIIT. Recuerda tomar electrolitos 30 min antes para maximizar tu rendimiento en cetosis.',
                style: TextStyle(fontSize: 12, color: AppColors.verdeOs, height: 1.5)),
            ])),
          ]),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String valor;
  final String label;
  final IconData icon;
  final Color color;
  const _StatBox(this.valor, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}
