import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/perfil_service.dart';
import '../../../../features/gem/data/services/gemini_service.dart';

/// Onboarding KETORA — 10 pasos con cálculo real de macros
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _paso = 0;
  static const int _total = 10;

  // Datos del usuario
  String _nombre     = '';
  String _objetivo   = '';
  int    _edad       = 0;
  double _pesoKg     = 0;
  double _alturaCm   = 0;
  String _actividad  = '';
  String _experiencia  = '';
  String _tipoAyuno    = 'sin_ayuno';
  String _condicion    = 'Ninguna';
  String _sexo       = 'Masculino';

  // Macros calculados
  int _kcal = 0;
  int _grasasG = 0;
  int _proteinaG = 0;
  int _carbosG = 0;

  Future<void> _siguiente() async {
    if (_paso < _total - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Último paso — guardar perfil y navegar
      await _guardarPerfilYNavegar();
    }
  }

  Future<void> _guardarPerfilYNavegar() async {
    _calcularMacros();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    final perfil = PerfilUsuario(
      uid:          uid,
      nombre:       _nombre.isNotEmpty ? _nombre : 'Usuario',
      objetivo:     _objetivo.isNotEmpty ? _objetivo : 'Perder peso',
      sexo:         _sexo,
      edad:         _edad > 0 ? _edad : 30,
      pesoKg:       _pesoKg > 0 ? _pesoKg : 80,
      alturaCm:     _alturaCm > 0 ? _alturaCm : 170,
      actividad:    _actividad.isNotEmpty ? _actividad : 'Ligero',
      experiencia:  _experiencia.isNotEmpty ? _experiencia : 'Primera vez',
      tipoAyuno:    _tipoAyuno,
      kcal:         _kcal > 0 ? _kcal : 2100,
      grasasG:      _grasasG > 0 ? _grasasG : 163,
      proteinaG:    _proteinaG > 0 ? _proteinaG : 131,
      carbosG:      _carbosG > 0 ? _carbosG : 26,
      fechaRegistro: DateTime.now(),
    );

    try {
      // Guardar en Firestore
      await sl<PerfilService>().guardarPerfil(perfil);

      // Actualizar GEM con el perfil real
      sl<GeminiService>().actualizarPerfil(
        nombre:     perfil.nombre,
        objetivo:   perfil.objetivo,
        kcal:       perfil.kcal,
        grasasG:    perfil.grasasG,
        proteinaG:  perfil.proteinaG,
        carbosG:    perfil.carbosG,
        nivel:      _mapearNivel(perfil.experiencia),
      );
    } catch (_) {
      // Si falla Firestore (sin auth o sin conexión), seguimos igual
    }

    if (mounted) context.go(AppRoutes.hoy);
  }

  String _mapearNivel(String experiencia) {
    switch (experiencia) {
      case 'Tengo experiencia': return 'intermedio';
      case 'Lo intenté':        return 'retomador';
      default:                  return 'principiante';
    }
  }

  void _anterior() {
    if (_paso > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Mifflin-St Jeor + factor actividad + déficit keto
  void _calcularMacros() {
    if (_pesoKg <= 0 || _alturaCm <= 0 || _edad <= 0) return;

    // TMB base
    double tmb = _sexo == 'Masculino'
        ? (10 * _pesoKg) + (6.25 * _alturaCm) - (5 * _edad) + 5
        : (10 * _pesoKg) + (6.25 * _alturaCm) - (5 * _edad) - 161;

    // Factor actividad
    final factores = {
      'Sedentario': 1.2,
      'Ligero': 1.375,
      'Moderado': 1.55,
      'Activo': 1.725,
      'Muy activo': 1.9,
    };
    final factor = factores[_actividad] ?? 1.375;
    final tdee = tmb * factor;

    // Déficit del 20% para pérdida de peso keto
    _kcal = (tdee * 0.8).round();

    // Distribución keto: 70% grasas, 25% proteína, 5% carbos
    _grasasG    = (_kcal * 0.70 / 9).round();
    _proteinaG  = (_kcal * 0.25 / 4).round();
    _carbosG    = (_kcal * 0.05 / 4).round();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo negro sólido para toda la pantalla
          Positioned.fill(child: Container(color: Colors.black)),

          // Contenido
          SafeArea(
            child: Column(
              children: [
                // Barra de progreso y controles
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Row(
                    children: [
                      if (_paso > 0)
                        GestureDetector(
                          onTap: _anterior,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: AppColors.blanco, size: 20),
                          ),
                        )
                      else
                        const SizedBox(width: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_paso + 1) / _total,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.oro),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${_paso + 1} de $_total',
                              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_paso > 0)
                        TextButton(
                          onPressed: () => context.go(AppRoutes.hoy),
                          child: const Text('Omitir', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        )
                      else
                        const SizedBox(width: 50),
                    ],
                  ),
                ),

                // Páginas
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) {
                      setState(() => _paso = i);
                      if (i == 9) _calcularMacros();
                    },
                    children: [
                      // Paso 0 — Bienvenida imponente
                      _BienvenidaImponente(onNombreChange: (v) => _nombre = v),

                      // Paso 1 — Sexo
                      _Paso(
                        emoji: '👤',
                        titulo: '¿Cuál es tu sexo?',
                        subtitulo: 'Para calcular tu metabolismo exacto',
                        body: _OpcionesBody(
                          opciones: const [
                            _Opcion('Masculino', '👨'),
                            _Opcion('Femenino', '👩'),
                          ],
                          seleccionada: _sexo,
                          onSelect: (v) => setState(() => _sexo = v),
                        ),
                        colorFondo: AppColors.fondoAzul,
                      ),

                      // Paso 2 — Objetivo
                      _Paso(
                        emoji: '🎯',
                        titulo: '¿Cuál es tu objetivo?',
                        subtitulo: 'Adaptamos el plan a tu meta',
                        body: _OpcionesBody(
                          opciones: const [
                            _Opcion('Perder peso',       '⚖️'),
                            _Opcion('Más energía',        '⚡'),
                            _Opcion('Control glucémico', '🩸'),
                            _Opcion('Claridad mental',   '🧠'),
                          ],
                          seleccionada: _objetivo,
                          onSelect: (v) => setState(() => _objetivo = v),
                        ),
                        colorFondo: AppColors.fondoOro,
                      ),

                      // Paso 3 — Edad
                      _Paso(
                        emoji: '🎂',
                        titulo: '¿Cuántos años tienes?',
                        subtitulo: 'Parte del cálculo de tu metabolismo basal',
                        body: _NumeroBody(
                          hint: 'Tu edad',
                          sufijo: 'años',
                          onValor: (v) => _edad = v.round(),
                          min: 18, max: 80, inicial: 30,
                        ),
                        colorFondo: AppColors.fondoGris,
                      ),

                      // Paso 4 — Peso
                      _Paso(
                        emoji: '⚖️',
                        titulo: 'Tu peso actual',
                        subtitulo: 'Sin juzgar — solo para personalizar tu plan',
                        body: _NumeroBody(
                          hint: 'Tu peso',
                          sufijo: 'kg',
                          onValor: (v) => _pesoKg = v,
                          min: 40, max: 200, inicial: 80, decimales: true,
                        ),
                        colorFondo: AppColors.fondoNaranja,
                      ),

                      // Paso 5 — Estatura
                      _Paso(
                        emoji: '📏',
                        titulo: 'Tu estatura',
                        subtitulo: 'En centímetros',
                        body: _NumeroBody(
                          hint: 'Tu estatura',
                          sufijo: 'cm',
                          onValor: (v) => _alturaCm = v,
                          min: 140, max: 220, inicial: 170,
                        ),
                        colorFondo: AppColors.fondoVerde,
                      ),

                      // Paso 6 — Actividad
                      _Paso(
                        emoji: '🏃',
                        titulo: 'Nivel de actividad',
                        subtitulo: '¿Qué tan activo eres en tu día a día?',
                        body: _OpcionesBody(
                          opciones: const [
                            _Opcion('Sedentario',   '🪑', 'Trabajo de oficina, poco movimiento'),
                            _Opcion('Ligero',        '🚶', 'Caminas 1-3 días/semana'),
                            _Opcion('Moderado',      '🏋️', 'Ejercicio 3-5 días/semana'),
                            _Opcion('Activo',        '🏊', 'Ejercicio intenso 6-7 días'),
                          ],
                          seleccionada: _actividad,
                          onSelect: (v) => setState(() => _actividad = v),
                          modoDescripcion: true,
                        ),
                        colorFondo: AppColors.fondoAzul,
                      ),

                      // Paso 7 — Experiencia keto
                      _Paso(
                        emoji: '🍳',
                        titulo: '¿Has probado keto antes?',
                        subtitulo: 'Adaptamos las explicaciones a tu nivel',
                        body: _OpcionesBody(
                          opciones: const [
                            _Opcion('Primera vez',    '🌱', 'Nunca he hecho keto'),
                            _Opcion('Lo intenté',     '🔄', 'Lo probé pero lo dejé'),
                            _Opcion('Tengo experiencia', '✅', 'Conozco bien cómo funciona'),
                          ],
                          seleccionada: _experiencia,
                          onSelect: (v) => setState(() => _experiencia = v),
                          modoDescripcion: true,
                        ),
                        colorFondo: AppColors.fondoVerde,
                      ),

                      // Paso 8 — Ayuno
                      _Paso(
                        emoji: '⏰',
                        titulo: '¿Qué tipo de ayuno quieres hacer?',
                        subtitulo: 'Empieza suave — siempre puedes avanzar después',
                        body: _AyunoBody(
                          seleccionado: _tipoAyuno,
                          onSelect: (v) => setState(() => _tipoAyuno = v),
                        ),
                        colorFondo: AppColors.fondoOro,
                      ),

                      // Paso 9 — Plan listo
                      _Paso(
                        emoji: '✨',
                        titulo: '¡Tu plan personalizado está listo!',
                        subtitulo: _nombre.isNotEmpty ? '¡Hola, $_nombre! Preparado especialmente para ti' : 'Preparado especialmente para ti',
                        body: _PlanBody(
                          kcal: _kcal > 0 ? _kcal : 2100,
                          grasasG: _grasasG > 0 ? _grasasG : 163,
                          proteinaG: _proteinaG > 0 ? _proteinaG : 131,
                          carbosG: _carbosG > 0 ? _carbosG : 26,
                          tipoAyuno: _tipoAyuno,
                          objetivo: _objetivo.isNotEmpty ? _objetivo : 'Perder peso',
                        ),
                        colorFondo: AppColors.fondoVerde,
                      ),
                    ],
                  ),
                ),

                // Botón siguiente
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _paso == 9 ? AppColors.oro : AppColors.verde,
                        foregroundColor: AppColors.blanco,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      onPressed: _siguiente,
                      child: Text(
                        _paso == 9 ? '🚀 ¡Comenzar mi KETORA!' : 'Continuar →',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Paso 0 — Bienvenida imponente
// ─────────────────────────────────────────────────────────────────────────────
class _BienvenidaImponente extends StatelessWidget {
  final ValueChanged<String> onNombreChange;
  const _BienvenidaImponente({required this.onNombreChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        children: [
          // Logo horizontal grande
          Image.asset('assets/images/logo_horizontal.png',
            width: double.infinity, height: 160, fit: BoxFit.contain),
          const SizedBox(height: 4),

          // Tagline
          const Text('Tu guía keto en español',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF8FAF8F), fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),

          // Card de bienvenida oscura
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF182318),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2A3D2A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('¿Cómo te llamas?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Personalizamos KETORA para ti',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8FAF8F))),
                const SizedBox(height: 16),
                TextField(
                  onChanged: onNombreChange,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tu nombre',
                    hintStyle: const TextStyle(color: Color(0xFF4A6B4A)),
                    filled: true,
                    fillColor: const Color(0xFF0D1510),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Features — grilla 2x2
          Row(children: [
            Expanded(child: _FeatureCard(Icons.eco_rounded, '🥑', 'Guía Keto', 'En español\npaso a paso', const Color(0xFF7CB518), const Color(0xFF0F2B18))),
            const SizedBox(width: 10),
            Expanded(child: _FeatureCard(Icons.auto_awesome_rounded, '✨', 'Coach IA', 'GEM responde\ncualquier duda', const Color(0xFF3B82F6), const Color(0xFF0F1B2B))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _FeatureCard(Icons.local_fire_department_rounded, '🔥', 'Ayuno 16:8', 'Quema grasa\nmientras ayunas', const Color(0xFFC9A227), const Color(0xFF1E1A0A))),
            const SizedBox(width: 10),
            Expanded(child: _FeatureCard(Icons.monitor_heart_rounded, '💪', 'Macros', 'Calorías y\nnutrientes al día', const Color(0xFFA855F7), const Color(0xFF1A0F2B))),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wrapper de cada paso
// ─────────────────────────────────────────────────────────────────────────────
class _Paso extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Widget body;
  final Color colorFondo;

  const _Paso({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.body,
    required this.colorFondo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          Image.asset('assets/images/logo_horizontal.png',
            width: double.infinity, height: 130, fit: BoxFit.contain),
          const SizedBox(height: 10),
          Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF8FAF8F))),
          const SizedBox(height: 16),
          body,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de contenido por paso
// ─────────────────────────────────────────────────────────────────────────────

class _BienvenidaBody extends StatelessWidget {
  final ValueChanged<String> onNombreChange;
  const _BienvenidaBody({required this.onNombreChange});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF182318),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(children: [
          const Text('¿Cómo te llamas?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          TextField(
            onChanged: onNombreChange,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tu nombre',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true,
              fillColor: const Color(0xFF0D1510),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          const Text('En KETORA te acompañamos en cada paso de tu camino keto. Sin tecnicismos, en tu idioma.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: const Color(0xFF8FAF8F), height: 1.5)),
        ]),
      ),
    ]);
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icono;
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color fondo;
  const _FeatureCard(this.icono, this.emoji, this.titulo, this.subtitulo, this.color, this.fondo);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(titulo,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(subtitulo,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8FAF8F), height: 1.3)),
        ],
      ),
    );
  }
}

class _Opcion {
  final String valor;
  final String emoji;
  final String? descripcion;
  const _Opcion(this.valor, this.emoji, [this.descripcion]);
}

class _OpcionesBody extends StatelessWidget {
  final List<_Opcion> opciones;
  final String seleccionada;
  final ValueChanged<String> onSelect;
  final bool modoDescripcion;

  const _OpcionesBody({
    required this.opciones,
    required this.seleccionada,
    required this.onSelect,
    this.modoDescripcion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: opciones.map((op) {
        final sel = seleccionada == op.valor;
        return GestureDetector(
          onTap: () => onSelect(op.valor),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: modoDescripcion ? 14 : 16),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF0F3020) : const Color(0xFF182318),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sel ? AppColors.verdeMedio : const Color(0xFF2A3D2A),
                width: sel ? 2 : 1.5,
              ),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: sel ? AppColors.verdeMedio.withOpacity(0.2) : const Color(0xFF0D1510),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(op.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(op.valor,
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: sel ? AppColors.verdeMedio : Colors.white,
                    )),
                  if (op.descripcion != null && modoDescripcion)
                    Text(op.descripcion!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
                ],
              )),
              if (sel)
                const Icon(Icons.check_circle_rounded, color: AppColors.verdeMedio, size: 24),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _NumeroBody extends StatefulWidget {
  final String hint;
  final String sufijo;
  final ValueChanged<double> onValor;
  final double min;
  final double max;
  final double inicial;
  final bool decimales;

  const _NumeroBody({
    required this.hint,
    required this.sufijo,
    required this.onValor,
    required this.min,
    required this.max,
    required this.inicial,
    this.decimales = false,
  });

  @override
  State<_NumeroBody> createState() => _NumeroBodyState();
}

class _NumeroBodyState extends State<_NumeroBody> {
  late double _valor;

  @override
  void initState() {
    super.initState();
    _valor = widget.inicial;
    widget.onValor(_valor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF182318),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A3D2A)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            widget.decimales ? _valor.toStringAsFixed(1) : _valor.round().toString(),
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(widget.sufijo,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF8FAF8F))),
          ),
        ]),
        const SizedBox(height: 20),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.verdeMedio,
            inactiveTrackColor: const Color(0xFF2A3D2A),
            thumbColor: AppColors.verdeMedio,
            overlayColor: AppColors.verdeMedio.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: _valor,
            min: widget.min,
            max: widget.max,
            divisions: ((widget.max - widget.min) / (widget.decimales ? 0.5 : 1)).round(),
            onChanged: (v) {
              setState(() => _valor = v);
              widget.onValor(v);
            },
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${widget.min.round()} ${widget.sufijo}', style: const TextStyle(fontSize: 12, color: Color(0xFF4A6B4A))),
          Text('${widget.max.round()} ${widget.sufijo}', style: const TextStyle(fontSize: 12, color: Color(0xFF4A6B4A))),
        ]),
      ]),
    );
  }
}

class _AyunoBody extends StatelessWidget {
  final String seleccionado;
  final ValueChanged<String> onSelect;
  const _AyunoBody({required this.seleccionado, required this.onSelect});

  static const _opciones = [
    (
      id: 'sin_ayuno',
      emoji: '🍽️',
      titulo: 'Sin ayuno',
      desc: 'Como en mi horario habitual, sin ventana definida',
      nivel: '',
    ),
    (
      id: '12:12',
      emoji: '🌙',
      titulo: 'Ayuno 12:12',
      desc: 'Ideal para empezar. Ej: come de 8am a 8pm',
      nivel: 'Principiante',
    ),
    (
      id: '14:10',
      emoji: '⏳',
      titulo: 'Ayuno 14:10',
      desc: 'Un paso más. Come en 10 horas. Ej: 9am a 7pm',
      nivel: 'Fácil',
    ),
    (
      id: '16:8',
      emoji: '⏰',
      titulo: 'Ayuno 16:8',
      desc: 'El más popular. Come en 8 horas. Ej: 12pm a 8pm',
      nivel: 'Intermedio',
    ),
    (
      id: '18:6',
      emoji: '🔥',
      titulo: 'Ayuno 18:6',
      desc: 'Ventana de 6 horas. Ej: 1pm a 7pm',
      nivel: 'Avanzado',
    ),
    (
      id: '20:4',
      emoji: '💪',
      titulo: 'Ayuno 20:4',
      desc: 'Solo 4 horas para comer al día',
      nivel: 'Muy avanzado',
    ),
    (
      id: 'OMAD',
      emoji: '🏆',
      titulo: 'OMAD',
      desc: 'Una sola comida al día. Solo para experimentados',
      nivel: 'Experto',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A0A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC9A227).withOpacity(0.3)),
        ),
        child: const Row(children: [
          Text('💡', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Empieza por donde te sientas cómodo. Puedes cambiarlo después desde tu perfil.',
            style: TextStyle(fontSize: 13, color: Color(0xFFC9A227), height: 1.4),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      ..._opciones.map((op) {
        final sel = seleccionado == op.id;
        return GestureDetector(
          onTap: () => onSelect(op.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF0F3020) : const Color(0xFF182318),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? AppColors.verdeMedio : const Color(0xFF2A3D2A),
                width: sel ? 2 : 1.5,
              ),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: sel ? AppColors.verdeMedio.withOpacity(0.2) : const Color(0xFF0D1510),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(op.emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(op.titulo,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: sel ? AppColors.verdeMedio : Colors.white,
                    )),
                  if (op.nivel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.verdeMedio.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(op.nivel,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.verdeMedio)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(op.desc,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8FAF8F))),
              ])),
              if (sel)
                const Icon(Icons.check_circle_rounded, color: AppColors.verdeMedio, size: 22),
            ]),
          ),
        );
      }),
    ]);
  }
}

class _PlanBody extends StatelessWidget {
  final int kcal;
  final int grasasG;
  final int proteinaG;
  final int carbosG;
  final String tipoAyuno;
  final String objetivo;

  const _PlanBody({
    required this.kcal,
    required this.grasasG,
    required this.proteinaG,
    required this.carbosG,
    required this.tipoAyuno,
    required this.objetivo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Macros card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.verdeOs, AppColors.verde],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          const Text('Tu plan keto personalizado',
            style: TextStyle(color: AppColors.blanco, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _MacroBadge('$kcal', 'kcal/día', AppColors.oro)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MacroBadge('${grasasG}g', 'Grasas 70%', AppColors.macroGrasas)),
            const SizedBox(width: 10),
            Expanded(child: _MacroBadge('${proteinaG}g', 'Proteína 25%', AppColors.macroProtein)),
            const SizedBox(width: 10),
            Expanded(child: _MacroBadge('${carbosG}g', 'Carbos 5%', AppColors.macroCarbos)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),

      // Features que tendrá
      ...<({String e, String t})>[
        if (tipoAyuno != 'sin_ayuno') (e: '⏰', t: 'Timer de ayuno $tipoAyuno con notificaciones'),
        (e: '📊', t: 'Seguimiento diario de macros y calorías'),
        (e: '🤖', t: 'GEM listo para responder tus dudas keto'),
        (e: '💧', t: 'Recordatorios de hidratación'),
        (e: '📈', t: 'Gráfica de peso y medidas'),
        (e: '🏆', t: 'Logros y rachas motivacionales'),
      ].map((f) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF182318),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3D2A)),
        ),
        child: Row(children: [
          Text(f.e, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(f.t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          const Icon(Icons.check_circle_rounded, color: AppColors.verdeMedio, size: 20),
        ]),
      )),
    ]);
  }
}

class _MacroBadge extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;
  const _MacroBadge(this.valor, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border(bottom: BorderSide(color: color, width: 3)),
      ),
      child: Column(children: [
        Text(valor,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
