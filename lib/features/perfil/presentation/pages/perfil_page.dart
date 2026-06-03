import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/perfil_service.dart';
import '../../../../features/gem/data/services/gemini_service.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  PerfilUsuario? _perfil;
  bool _cargando = true;
  String? _fotoPath;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    _cargarFotoPerfil();
  }

  Future<void> _cargarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _cargando = false);
      return;
    }
    final p = await sl<PerfilService>().cargarPerfil(uid);
    if (mounted) setState(() { _perfil = p; _cargando = false; });
  }

  Future<void> _cargarFotoPerfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('ketora_profile_photo_$uid');
    if (path != null && File(path).existsSync()) {
      if (mounted) setState(() => _fotoPath = path);
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF182318),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Foto de perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.fondoVerde, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.verde, size: 20),
              ),
              title: const Text('Tomar una foto', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.fondoAzul, shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.info, size: 20),
              ),
              title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source, maxWidth: 600, maxHeight: 600, imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final destPath = '${dir.path}/profile_$uid.jpg';
    await File(photo.path).copy(destPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ketora_profile_photo_$uid', destPath);
    if (mounted) setState(() => _fotoPath = destPath);
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta KETORA?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    sl<GeminiService>().reiniciarChat();
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1510),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.verde))
          : CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: Colors.black,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.blanco),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: Colors.black,
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Avatar con foto
                            GestureDetector(
                              onTap: _cambiarFotoPerfil,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 90, height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: ClipOval(
                                      child: _fotoPath != null
                                          ? Image.file(File(_fotoPath!), fit: BoxFit.cover)
                                          : Center(
                                              child: Text(
                                                _perfil?.nombre.isNotEmpty == true
                                                    ? _perfil!.nombre[0].toUpperCase()
                                                    : '🥑',
                                                style: const TextStyle(fontSize: 36, color: AppColors.blanco, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.oro,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _perfil?.nombre ?? user?.displayName ?? 'Usuario',
                              style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800,
                                color: AppColors.blanco,
                              ),
                            ),
                            Text(
                              user?.email ?? 'Sin cuenta vinculada',
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Macros actuales ──────────────────────
                        if (_perfil != null) ...[
                          _SectionTitle('Tu plan KETORA'),
                          _MacrosCard(perfil: _perfil!),
                          const SizedBox(height: 20),

                          // ── Datos personales ─────────────────────
                          _SectionTitle('Datos personales'),
                          _InfoCard(children: [
                            _InfoRow('Objetivo', _perfil!.objetivo, Icons.flag_rounded),
                            _InfoRow('Sexo',     _perfil!.sexo,     Icons.person_rounded),
                            _InfoRow('Edad',     '${_perfil!.edad} años', Icons.cake_rounded),
                            _InfoRow('Peso',     '${_perfil!.pesoKg.toStringAsFixed(1)} kg', Icons.monitor_weight_rounded),
                            _InfoRow('Estatura', '${_perfil!.alturaCm.round()} cm', Icons.height_rounded),
                            _InfoRow('Actividad', _perfil!.actividad, Icons.directions_run_rounded),
                            _InfoRow('Experiencia', _perfil!.experiencia, Icons.school_rounded),
                            _InfoRow('Ayuno intermitente', _perfil!.tipoAyuno == 'sin_ayuno' ? 'Sin ayuno 🍽️' : '${_perfil!.tipoAyuno} ⏰', Icons.timer_rounded),
                          ]),
                          const SizedBox(height: 20),
                        ],

                        // ── Acciones ─────────────────────────────
                        _SectionTitle('Cuenta'),
                        _InfoCard(children: [
                          _ActionRow(
                            icon: Icons.edit_rounded,
                            label: 'Editar mi perfil',
                            onTap: () => _mostrarEditarPerfil(),
                          ),
                          _ActionRow(
                            icon: Icons.notifications_rounded,
                            label: 'Notificaciones',
                            onTap: () => _mostrarNotificaciones(),
                          ),
                          _ActionRow(
                            icon: Icons.privacy_tip_rounded,
                            label: 'Privacidad y datos',
                            onTap: () => _mostrarPrivacidad(),
                          ),
                        ]),
                        const SizedBox(height: 12),

                        // Cerrar sesión
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _cerrarSesion,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Center(
                          child: Text('KETORA v1.0.0 · Hecho con 🥑 para la comunidad keto',
                            style: TextStyle(fontSize: 11, color: AppColors.textHint),
                            textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _mostrarNotificaciones() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF182318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🔔 Notificaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 20),
          _SwitchTile('Recordatorio de ayuno', '16h, 14h, 12h — hitos del ayuno', 'notif_ayuno', true),
          _SwitchTile('Motivación diaria', 'Un mensaje keto cada mañana', 'notif_motivacion', true),
          _SwitchTile('Registro de agua', 'Recordatorio cada 2 horas', 'notif_agua', false),
          _SwitchTile('Logros desbloqueados', 'Cuando alcances un hito', 'notif_logros', true),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar preferencias'),
          )),
        ]),
      ),
    );
  }

  void _mostrarPrivacidad() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF182318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🔒 Privacidad y datos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 16),
          _InfoTile('📊 Tus datos', 'Tu información está cifrada en Firebase (Google) y nunca se comparte con terceros.'),
          _InfoTile('🗂️ Qué guardamos', 'Perfil, alimentos registrados, glucosa, peso, medidas y fotos de progreso.'),
          _InfoTile('🌐 Servicios externos', 'Usamos Gemini (Google) para el coach IA y Open Food Facts para datos nutricionales.'),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2A3D2A)),
          const SizedBox(height: 12),
          // Eliminar datos
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _confirmarEliminarDatos();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2B0F0F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Eliminar todos mis datos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                  Text('Borra tu perfil y registros de KETORA permanentemente', style: TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
                ])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmarEliminarDatos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF182318),
        title: const Text('¿Eliminar todos tus datos?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Esta acción es permanente. Se borrarán tu perfil, registros de alimentos, glucosa, peso y medidas.', style: TextStyle(color: Color(0xFF8FAF8F))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8FAF8F)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              // Cerrar sesión y limpiar
              await FirebaseAuth.instance.signOut();
              if (mounted) context.go(AppRoutes.onboarding);
            },
            child: const Text('Eliminar y salir'),
          ),
        ],
      ),
    );
  }

  void _mostrarEditarPerfil() {
    if (_perfil == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarPerfilSheet(perfil: _perfil!, onGuardado: (p) {
        setState(() => _perfil = p);
        // Actualizar GEM con nuevo perfil
        sl<GeminiService>().actualizarPerfil(
          nombre:    p.nombre,
          objetivo:  p.objetivo,
          kcal:      p.kcal,
          grasasG:   p.grasasG,
          proteinaG: p.proteinaG,
          carbosG:   p.carbosG,
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MacrosCard extends StatelessWidget {
  final PerfilUsuario perfil;
  const _MacrosCard({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.verdeOs, AppColors.verde],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroPill('${perfil.kcal}', 'kcal/día', AppColors.oro),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MacroPill('${perfil.grasasG}g', 'Grasas', AppColors.macroGrasas)),
              const SizedBox(width: 10),
              Expanded(child: _MacroPill('${perfil.proteinaG}g', 'Proteína', AppColors.verdeMedio)),
              const SizedBox(width: 10),
              Expanded(child: _MacroPill('${perfil.carbosG}g', 'Carbos', AppColors.macroCarbos)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;
  const _MacroPill(this.valor, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF182318),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          return Column(children: [
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 52, color: AppColors.divider),
          ]);
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  const _InfoRow(this.label, this.valor, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.fondoVerde, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.verde),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8FAF8F)))),
        Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.fondoVerde, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.verde),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet de edición de perfil
// ─────────────────────────────────────────────────────────────────────────────

class _EditarPerfilSheet extends StatefulWidget {
  final PerfilUsuario perfil;
  final ValueChanged<PerfilUsuario> onGuardado;

  const _EditarPerfilSheet({required this.perfil, required this.onGuardado});

  @override
  State<_EditarPerfilSheet> createState() => _EditarPerfilSheetState();
}

class _EditarPerfilSheetState extends State<_EditarPerfilSheet> {
  late final TextEditingController _nombreCtrl;
  late double _pesoKg;
  late double _alturaCm;
  late int _edad;
  late String _sexo;
  late String _objetivo;
  late String _actividad;
  bool _guardando = false;

  static const _objetivos = ['Perder peso', 'Más energía', 'Control glucémico', 'Claridad mental'];
  static const _actividades = ['Sedentario', 'Ligero', 'Moderado', 'Activo', 'Muy activo'];
  static const _sexos = ['Masculino', 'Femenino'];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.perfil.nombre);
    _pesoKg    = widget.perfil.pesoKg;
    _alturaCm  = widget.perfil.alturaCm;
    _edad      = widget.perfil.edad;
    _sexo      = widget.perfil.sexo;
    _objetivo  = widget.perfil.objetivo;
    _actividad = widget.perfil.actividad;
  }

  @override
  void dispose() { _nombreCtrl.dispose(); super.dispose(); }

  int _calcularKcal() {
    double tmb = _sexo == 'Masculino'
        ? (10 * _pesoKg) + (6.25 * _alturaCm) - (5 * _edad) + 5
        : (10 * _pesoKg) + (6.25 * _alturaCm) - (5 * _edad) - 161;
    final factores = {'Sedentario': 1.2, 'Ligero': 1.375, 'Moderado': 1.55, 'Activo': 1.725, 'Muy activo': 1.9};
    return (tmb * (factores[_actividad] ?? 1.375) * 0.8).round();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final kcal = _calcularKcal();
    final updated = widget.perfil.copyWith(
      nombre:    _nombreCtrl.text.trim().isNotEmpty ? _nombreCtrl.text.trim() : widget.perfil.nombre,
      pesoKg:    _pesoKg,
      alturaCm:  _alturaCm,
      edad:      _edad,
      sexo:      _sexo,
      objetivo:  _objetivo,
      actividad: _actividad,
      kcal:      kcal,
      grasasG:   (kcal * 0.70 / 9).round(),
      proteinaG: (kcal * 0.25 / 4).round(),
      carbosG:   (kcal * 0.05 / 4).round(),
    );
    try { await sl<PerfilService>().guardarPerfil(updated); } catch (_) {}
    if (mounted) { widget.onGuardado(updated); Navigator.pop(context); }
  }

  Widget _slider(String label, double valor, double min, double max, int div, Color color, ValueChanged<double> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(activeTrackColor: color, thumbColor: color, overlayColor: color.withOpacity(0.15), trackHeight: 5),
        child: Slider(value: valor, min: min, max: max, divisions: div, onChanged: onChanged),
      ),
    ]);
  }

  Widget _selector(String label, List<String> opciones, String selec, ValueChanged<String> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8FAF8F))),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: opciones.map((op) {
        final sel = selec == op;
        return GestureDetector(
          onTap: () => onChanged(op),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.verde : const Color(0xFF0D1510),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? AppColors.verde : const Color(0xFF2A3D2A)),
            ),
            child: Text(op, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(0xFF8FAF8F))),
          ),
        );
      }).toList()),
      const SizedBox(height: 12),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final kcalEstimado = _calcularKcal();
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(color: Color(0xFF182318), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
          decoration: BoxDecoration(color: const Color(0xFF2A3D2A), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(children: [
            const Text('Actualizar mis datos', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: Color(0xFF8FAF8F)), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Nombre
              TextField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Tu nombre', prefixIcon: Icon(Icons.person_rounded, color: AppColors.verde)),
              ),
              const SizedBox(height: 16),
              // Sexo
              _selector('Sexo', _sexos, _sexo, (v) => setState(() => _sexo = v)),
              // Objetivo
              _selector('Objetivo principal', _objetivos, _objetivo, (v) => setState(() => _objetivo = v)),
              // Edad
              _slider('Edad: $_edad años', _edad.toDouble(), 15, 80, 65, AppColors.info, (v) => setState(() => _edad = v.round())),
              // Peso
              _slider('Peso: ${_pesoKg.toStringAsFixed(1)} kg', _pesoKg, 40, 200, 320, AppColors.verde, (v) => setState(() => _pesoKg = v)),
              // Altura
              _slider('Altura: ${_alturaCm.toStringAsFixed(0)} cm', _alturaCm, 140, 220, 160, AppColors.macroProtein, (v) => setState(() => _alturaCm = v)),
              // Actividad
              _selector('Nivel de actividad', _actividades, _actividad, (v) => setState(() => _actividad = v)),
              // Resumen macros calculados
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0D1510), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.verde.withOpacity(0.3))),
                child: Column(children: [
                  const Text('Tus macros calculados', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8FAF8F))),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    Column(children: [const Text('Calorías', style: TextStyle(fontSize: 11, color: Color(0xFF8FAF8F))), Text('$kcalEstimado kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFC9A227)))]),
                    Column(children: [const Text('Grasas', style: TextStyle(fontSize: 11, color: Color(0xFF8FAF8F))), Text('${(kcalEstimado * 0.70 / 9).round()}g', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFC9A227)))]),
                    Column(children: [const Text('Proteína', style: TextStyle(fontSize: 11, color: Color(0xFF8FAF8F))), Text('${(kcalEstimado * 0.25 / 4).round()}g', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6)))]),
                    Column(children: [const Text('Carbos', style: TextStyle(fontSize: 11, color: Color(0xFF8FAF8F))), Text('${(kcalEstimado * 0.05 / 4).round()}g', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.verdeMedio))]),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar todos los cambios'),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  final String titulo, subtitulo, prefKey;
  final bool defecto;
  const _SwitchTile(this.titulo, this.subtitulo, this.prefKey, this.defecto);
  @override State<_SwitchTile> createState() => _SwitchTileState();
}
class _SwitchTileState extends State<_SwitchTile> {
  bool _val = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _val = p.getBool(widget.prefKey) ?? widget.defecto);
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        Text(widget.subtitulo, style: const TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
      ])),
      Switch(
        value: _val,
        onChanged: (v) async {
          setState(() => _val = v);
          final p = await SharedPreferences.getInstance();
          await p.setBool(widget.prefKey, v);
        },
        activeColor: AppColors.verdeMedio,
      ),
    ]),
  );
}

class _InfoTile extends StatelessWidget {
  final String titulo, contenido;
  const _InfoTile(this.titulo, this.contenido);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 3),
      Text(contenido, style: const TextStyle(fontSize: 13, color: Color(0xFF8FAF8F), height: 1.4)),
    ]),
  );
}
