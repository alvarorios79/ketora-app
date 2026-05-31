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
          color: AppColors.blanco,
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
    final uid = FirebaseAuth.instance.currentUser!.uid;
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
      backgroundColor: AppColors.surface,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.verde))
          : CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.verdeOs,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.blanco),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.verdeOs, AppColors.verde],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
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
                            onTap: () {},
                          ),
                          _ActionRow(
                            icon: Icons.privacy_tip_rounded,
                            label: 'Privacidad y datos',
                            onTap: () {},
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
              Expanded(child: _MacroPill('${perfil.proteinaG}g', 'Proteína', AppColors.macroProtein)),
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
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
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
        color: AppColors.blanco,
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
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
        Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
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
  late int _kcal;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.perfil.nombre);
    _pesoKg = widget.perfil.pesoKg;
    _kcal   = widget.perfil.kcal;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final updated = widget.perfil.copyWith(
      nombre: _nombreCtrl.text.trim().isNotEmpty ? _nombreCtrl.text.trim() : widget.perfil.nombre,
      pesoKg: _pesoKg,
      kcal:   _kcal,
      // Recalcular macros proporcionales
      grasasG:   (_kcal * 0.70 / 9).round(),
      proteinaG: (_kcal * 0.25 / 4).round(),
      carbosG:   (_kcal * 0.05 / 4).round(),
    );
    try {
      await sl<PerfilService>().guardarPerfil(updated);
    } catch (_) {}
    if (mounted) {
      widget.onGuardado(updated);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text('Editar perfil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 20),

          // Nombre
          TextField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_rounded, color: AppColors.verde),
            ),
          ),
          const SizedBox(height: 16),

          // Peso
          Text('Peso: ${_pesoKg.toStringAsFixed(1)} kg',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.verde,
              thumbColor: AppColors.verde,
              overlayColor: AppColors.verde.withValues(alpha: 0.15),
              trackHeight: 5,
            ),
            child: Slider(
              value: _pesoKg, min: 40, max: 200,
              divisions: 320,
              onChanged: (v) => setState(() => _pesoKg = v),
            ),
          ),

          // Calorías
          Text('Calorías objetivo: $_kcal kcal/día',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.oro,
              thumbColor: AppColors.oro,
              overlayColor: AppColors.oro.withValues(alpha: 0.15),
              trackHeight: 5,
            ),
            child: Slider(
              value: _kcal.toDouble(), min: 1200, max: 3500,
              divisions: 230,
              onChanged: (v) => setState(() => _kcal = v.round()),
            ),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.blanco, strokeWidth: 2))
                  : const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}
