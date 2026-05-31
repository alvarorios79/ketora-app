import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../features/gem/data/services/gemini_service.dart';
import '../../../../features/hoy/domain/entities/alimento_registrado_entity.dart';

class FotoIAPage extends StatefulWidget {
  final void Function(AlimentoRegistradoEntity) onAgregar;
  const FotoIAPage({super.key, required this.onAgregar});

  @override
  State<FotoIAPage> createState() => _FotoIAPageState();
}

class _FotoIAPageState extends State<FotoIAPage> {
  File? _foto;
  bool _analizando = false;
  Map<String, dynamic>? _resultado;
  String? _error;
  final _picker = ImagePicker();
  final _gemini = GetIt.instance<GeminiService>();

  Future<void> _tomarFoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (picked == null) return;
    setState(() {
      _foto = File(picked.path);
      _resultado = null;
      _error = null;
    });
    await _analizar();
  }

  Future<void> _analizar() async {
    if (_foto == null) return;
    setState(() { _analizando = true; _error = null; });
    try {
      final bytes = await _foto!.readAsBytes();
      final respuesta = await _gemini.analizarFoto(bytes);
      // Extraer JSON limpio
      final jsonStr = _extraerJson(respuesta);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      setState(() { _resultado = data; _analizando = false; });
    } catch (e) {
      setState(() { _analizando = false; _error = 'No pude analizar la imagen. Intenta con otra foto.'; });
    }
  }

  String _extraerJson(String texto) {
    final start = texto.indexOf('{');
    final end = texto.lastIndexOf('}');
    if (start != -1 && end != -1) return texto.substring(start, end + 1);
    return '{}';
  }

  double _num(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

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
            decoration: BoxDecoration(color: const Color(0xFF2A3D2A), borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                const Text('📷 Foto con IA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8FAF8F)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                children: [
                  // Área de foto
                  if (_foto == null) ...[
                    const Text(
                      'GEM analiza tu plato y calcula\nlos macros automáticamente 🤖',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFF8FAF8F), height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _BotonFoto(
                            icono: Icons.camera_alt_rounded,
                            etiqueta: 'Cámara',
                            onTap: () => _tomarFoto(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BotonFoto(
                            icono: Icons.photo_library_rounded,
                            etiqueta: 'Galería',
                            onTap: () => _tomarFoto(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Foto tomada
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_foto!, height: 220, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setState(() { _foto = null; _resultado = null; }),
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.verdeMedio),
                      label: const Text('Cambiar foto', style: TextStyle(color: AppColors.verdeMedio)),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Estado análisis
                  if (_analizando)
                    Column(
                      children: [
                        const CircularProgressIndicator(color: AppColors.verdeMedio),
                        const SizedBox(height: 12),
                        const Text('GEM está analizando tu plato...',
                          style: TextStyle(fontSize: 15, color: Color(0xFF8FAF8F))),
                      ],
                    ),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B0F0F),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_error!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 15)),
                    ),

                  // Resultado
                  if (_resultado != null && !_analizando) ...[
                    _TarjetaResultado(
                      data: _resultado!,
                      onAgregar: () {
                        final d = _resultado!;
                        final entidad = AlimentoRegistradoEntity(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          nombre: d['nombre']?.toString() ?? 'Alimento',
                          cantidadG: _num(d['porcion_g']),
                          unidad: 'g',
                          calorias: _num(d['kcal']),
                          grasasG: _num(d['grasas_g']),
                          proteinaG: _num(d['proteina_g']),
                          carbosNetosG: _num(d['carbos_netos_g']),
                          comida: _comidaActual(),
                          horaRegistro: DateTime.now(),
                          fuenteRegistro: 'foto_ia',
                        );
                        Navigator.pop(context);
                        widget.onAgregar(entidad);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('✓ ${d['nombre']} agregado al registro'),
                          backgroundColor: AppColors.verde,
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonFoto extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  const _BotonFoto({required this.icono, required this.etiqueta, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF182318),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.verde.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icono, color: AppColors.verdeMedio, size: 40),
          const SizedBox(height: 10),
          Text(etiqueta, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _TarjetaResultado extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAgregar;
  const _TarjetaResultado({required this.data, required this.onAgregar});

  double _num(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

  @override
  Widget build(BuildContext context) {
    final esKeto = data['es_keto'] == true;
    final carbos = _num(data['carbos_netos_g']);
    final color = carbos <= 5 ? AppColors.verdeMedio
        : carbos <= 15 ? const Color(0xFFC9A227)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF182318),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data['nombre']?.toString() ?? 'Alimento',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (esKeto ? AppColors.verdeMedio : const Color(0xFFEF4444)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  esKeto ? '✅ KETO' : '🔴 NO KETO',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: esKeto ? AppColors.verdeMedio : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          if (data['descripcion'] != null) ...[
            const SizedBox(height: 6),
            Text(data['descripcion'].toString(),
              style: const TextStyle(fontSize: 14, color: Color(0xFF8FAF8F))),
          ],
          const SizedBox(height: 16),

          // Macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroItem('🔥', '${_num(data['kcal']).round()}', 'kcal', const Color(0xFF8FAF8F)),
              _MacroItem('🥩', '${_num(data['proteina_g']).toStringAsFixed(1)}g', 'Prot.', const Color(0xFF3B82F6)),
              _MacroItem('🫒', '${_num(data['grasas_g']).toStringAsFixed(1)}g', 'Grasas', const Color(0xFFC9A227)),
              _MacroItem('🍞', '${carbos.toStringAsFixed(1)}g', 'Carbos', color),
            ],
          ),
          const SizedBox(height: 6),
          Text('Porción estimada: ${_num(data['porcion_g']).round()}g',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A6B4A))),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAgregar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verde,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('+ Agregar al registro',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String emoji, valor, label;
  final Color color;
  const _MacroItem(this.emoji, this.valor, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
    ],
  );
}
