import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/perfil_service.dart';
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
  List<Map<String, dynamic>> _ingredientes = [];
  String? _error;
  final _picker = ImagePicker();
  final _gemini = GetIt.instance<GeminiService>();
  final _dio = Dio();

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
    setState(() { _analizando = true; _error = null; _ingredientes = []; _resultado = null; });
    try {
      // Paso 1: Gemini lista cada ingrediente con gramos
      final bytes = await _foto!.readAsBytes();
      final respuesta = (await _gemini.analizarFoto(bytes)).trim();
      debugPrint('🍽️ Gemini foto raw: $respuesta');

      // Parsear líneas: "Ingrediente|gramos"
      final lineas = respuesta.split('\n').where((l) => l.contains('|')).toList();
      if (lineas.isEmpty) throw Exception('Sin ingredientes');

      final lista = <Map<String, dynamic>>[];
      for (final linea in lineas) {
        final partes = linea.split('|');
        final nombre = partes[0].trim();
        final gramos = double.tryParse(partes.length > 1 ? partes[1].trim() : '100') ?? 100;

        // Buscar macros por ingrediente
        Map<String, dynamic>? macros = _buscarEnBDLocal(nombre);
        macros ??= await _buscarMacros(nombre);

        if (macros != null) {
          // Ajustar por gramos reales vs porción de referencia
          final factor = gramos / (_num(macros['porcion_g'] ?? 100));
          lista.add({
            'nombre': nombre,
            'gramos': gramos,
            'kcal': _num(macros['kcal']) * factor,
            'proteina_g': _num(macros['proteina_g']) * factor,
            'grasas_g': _num(macros['grasas_g']) * factor,
            'carbos_netos_g': _num(macros['carbos_netos_g']) * factor,
            'es_keto': macros['es_keto'],
            'en_bd': true,
          });
        } else {
          lista.add({
            'nombre': nombre,
            'gramos': gramos,
            'kcal': 0.0,
            'proteina_g': 0.0,
            'grasas_g': 0.0,
            'carbos_netos_g': 0.0,
            'es_keto': null, // desconocido
            'en_bd': false,
          });
        }
      }

      if (lista.isEmpty) throw Exception('Sin datos');
      setState(() { _ingredientes = lista; _analizando = false; });
    } catch (e) {
      setState(() { _analizando = false; _error = 'No pude analizar la imagen. Intenta con otra foto.'; });
    }
  }

  // ── Base de datos comidas colombianas/latinoamericanas ────────────────────
  // Fuente: ICBF TCAC + USDA FoodData + comiai.co verificado 2026
  static const Map<String, Map<String, double>> _bdColombia = {
    // ── Sopas y caldos ────────────────────────────────────────────
    'sancocho':              {'kcal': 550, 'proteina_g': 32, 'grasas_g': 22, 'carbos_netos_g': 45, 'porcion_g': 500},
    'sancocho de gallina':   {'kcal': 550, 'proteina_g': 32, 'grasas_g': 22, 'carbos_netos_g': 45, 'porcion_g': 500},
    'sancocho trifasico':    {'kcal': 620, 'proteina_g': 38, 'grasas_g': 24, 'carbos_netos_g': 48, 'porcion_g': 550},
    'sancocho de res':       {'kcal': 580, 'proteina_g': 35, 'grasas_g': 23, 'carbos_netos_g': 46, 'porcion_g': 520},
    'sancocho de pollo':     {'kcal': 500, 'proteina_g': 30, 'grasas_g': 18, 'carbos_netos_g': 42, 'porcion_g': 480},
    'ajiaco':                {'kcal': 450, 'proteina_g': 30, 'grasas_g': 18, 'carbos_netos_g': 40, 'porcion_g': 450},
    'ajiaco bogotano':       {'kcal': 450, 'proteina_g': 30, 'grasas_g': 18, 'carbos_netos_g': 40, 'porcion_g': 450},
    'mondongo':              {'kcal': 420, 'proteina_g': 25, 'grasas_g': 18, 'carbos_netos_g': 38, 'porcion_g': 450},
    'mondongo colombiano':   {'kcal': 420, 'proteina_g': 25, 'grasas_g': 18, 'carbos_netos_g': 38, 'porcion_g': 450},
    'caldo de costilla':     {'kcal': 380, 'proteina_g': 28, 'grasas_g': 16, 'carbos_netos_g': 30, 'porcion_g': 450},
    'sopa de lentejas':      {'kcal': 380, 'proteina_g': 18, 'grasas_g': 12, 'carbos_netos_g': 48, 'porcion_g': 350},
    'cazuela de frijoles':   {'kcal': 380, 'proteina_g': 18, 'grasas_g': 12, 'carbos_netos_g': 48, 'porcion_g': 350},
    'sopa de verduras':      {'kcal': 200, 'proteina_g': 8, 'grasas_g': 4, 'carbos_netos_g': 32, 'porcion_g': 400},
    'changua':               {'kcal': 280, 'proteina_g': 12, 'grasas_g': 16, 'carbos_netos_g': 18, 'porcion_g': 350},
    'mute santandereano':    {'kcal': 420, 'proteina_g': 22, 'grasas_g': 16, 'carbos_netos_g': 42, 'porcion_g': 450},
    'cocido boyacense':      {'kcal': 480, 'proteina_g': 25, 'grasas_g': 18, 'carbos_netos_g': 50, 'porcion_g': 500},
    // ── Platos fuertes ─────────────────────────────────────────────
    'bandeja paisa':         {'kcal': 1730, 'proteina_g': 68, 'grasas_g': 100, 'carbos_netos_g': 120, 'porcion_g': 900},
    'lechona':               {'kcal': 600, 'proteina_g': 35, 'grasas_g': 40, 'carbos_netos_g': 25, 'porcion_g': 250},
    'lechona tolimense':     {'kcal': 600, 'proteina_g': 35, 'grasas_g': 40, 'carbos_netos_g': 25, 'porcion_g': 250},
    'tamal colombiano':      {'kcal': 450, 'proteina_g': 18, 'grasas_g': 22, 'carbos_netos_g': 45, 'porcion_g': 250},
    'tamales':               {'kcal': 450, 'proteina_g': 18, 'grasas_g': 22, 'carbos_netos_g': 45, 'porcion_g': 250},
    'arroz con pollo':       {'kcal': 350, 'proteina_g': 20, 'grasas_g': 10, 'carbos_netos_g': 42, 'porcion_g': 250},
    'arroz con pollo colombiano': {'kcal': 350, 'proteina_g': 20, 'grasas_g': 10, 'carbos_netos_g': 42, 'porcion_g': 250},
    'arroz atollado':        {'kcal': 450, 'proteina_g': 22, 'grasas_g': 16, 'carbos_netos_g': 50, 'porcion_g': 300},
    'chuleta valluna':       {'kcal': 480, 'proteina_g': 35, 'grasas_g': 28, 'carbos_netos_g': 20, 'porcion_g': 200},
    'mojarra frita':         {'kcal': 380, 'proteina_g': 40, 'grasas_g': 18, 'carbos_netos_g': 12, 'porcion_g': 250},
    'sudado de pollo':       {'kcal': 350, 'proteina_g': 28, 'grasas_g': 12, 'carbos_netos_g': 30, 'porcion_g': 300},
    'sudado de carne':       {'kcal': 380, 'proteina_g': 32, 'grasas_g': 14, 'carbos_netos_g': 28, 'porcion_g': 350},
    'sudado de carne colombiano': {'kcal': 380, 'proteina_g': 32, 'grasas_g': 14, 'carbos_netos_g': 28, 'porcion_g': 350},
    'sudado de res':         {'kcal': 380, 'proteina_g': 32, 'grasas_g': 14, 'carbos_netos_g': 28, 'porcion_g': 350},
    'sudado':                {'kcal': 360, 'proteina_g': 30, 'grasas_g': 13, 'carbos_netos_g': 28, 'porcion_g': 330},
    'cazuela de mariscos':   {'kcal': 380, 'proteina_g': 30, 'grasas_g': 18, 'carbos_netos_g': 20, 'porcion_g': 350},
    'arroz con mariscos':    {'kcal': 400, 'proteina_g': 25, 'grasas_g': 12, 'carbos_netos_g': 45, 'porcion_g': 300},
    'ceviche colombiano':    {'kcal': 180, 'proteina_g': 18, 'grasas_g': 4, 'carbos_netos_g': 15, 'porcion_g': 200},
    'fritanga colombiana':   {'kcal': 850, 'proteina_g': 45, 'grasas_g': 55, 'carbos_netos_g': 40, 'porcion_g': 400},
    'perro caliente colombiano': {'kcal': 550, 'proteina_g': 18, 'grasas_g': 32, 'carbos_netos_g': 45, 'porcion_g': 200},
    // ── Carnes (keto friendly) ─────────────────────────────────────
    'pollo asado':           {'kcal': 330, 'proteina_g': 60, 'grasas_g': 9, 'carbos_netos_g': 0, 'porcion_g': 200},
    'pollo guisado':         {'kcal': 360, 'proteina_g': 48, 'grasas_g': 16, 'carbos_netos_g': 8, 'porcion_g': 250},
    'pollo guisado con arroz':      {'kcal': 620, 'proteina_g': 48, 'grasas_g': 16, 'carbos_netos_g': 70, 'porcion_g': 450},
    'pollo guisado con patatas':     {'kcal': 520, 'proteina_g': 50, 'grasas_g': 16, 'carbos_netos_g': 38, 'porcion_g': 400},
    'pollo guisado con arroz y papas': {'kcal': 680, 'proteina_g': 52, 'grasas_g': 17, 'carbos_netos_g': 80, 'porcion_g': 500},
    'pollo guisado con patatas y arroz': {'kcal': 680, 'proteina_g': 52, 'grasas_g': 17, 'carbos_netos_g': 80, 'porcion_g': 500},
    'pollo con arroz':       {'kcal': 580, 'proteina_g': 46, 'grasas_g': 14, 'carbos_netos_g': 65, 'porcion_g': 420},
    'carne asada':           {'kcal': 440, 'proteina_g': 56, 'grasas_g': 24, 'carbos_netos_g': 0, 'porcion_g': 250},
    'carne molida':          {'kcal': 380, 'proteina_g': 42, 'grasas_g': 22, 'carbos_netos_g': 4, 'porcion_g': 250},
    'chicharron':            {'kcal': 500, 'proteina_g': 30, 'grasas_g': 42, 'carbos_netos_g': 0, 'porcion_g': 100},
    'chicharron colombiano': {'kcal': 500, 'proteina_g': 30, 'grasas_g': 42, 'carbos_netos_g': 0, 'porcion_g': 100},
    'chorizo colombiano':    {'kcal': 250, 'proteina_g': 14, 'grasas_g': 20, 'carbos_netos_g': 2, 'porcion_g': 80},
    'chorizos':              {'kcal': 250, 'proteina_g': 14, 'grasas_g': 20, 'carbos_netos_g': 2, 'porcion_g': 80},
    'morcilla':              {'kcal': 320, 'proteina_g': 15, 'grasas_g': 26, 'carbos_netos_g': 7, 'porcion_g': 150},
    'salmón':                {'kcal': 410, 'proteina_g': 40, 'grasas_g': 26, 'carbos_netos_g': 0, 'porcion_g': 200},
    'atún':                  {'kcal': 264, 'proteina_g': 58, 'grasas_g': 2, 'carbos_netos_g': 0, 'porcion_g': 200},
    // ── Acompañantes ───────────────────────────────────────────────
    'arroz blanco':          {'kcal': 200, 'proteina_g': 4, 'grasas_g': 0.5, 'carbos_netos_g': 44, 'porcion_g': 150},
    'frijoles':              {'kcal': 280, 'proteina_g': 16, 'grasas_g': 5, 'carbos_netos_g': 44, 'porcion_g': 250},
    'arepa de maiz':         {'kcal': 180, 'proteina_g': 4, 'grasas_g': 5, 'carbos_netos_g': 30, 'porcion_g': 100},
    'bistec con arepa':      {'kcal': 520, 'proteina_g': 48, 'grasas_g': 22, 'carbos_netos_g': 30, 'porcion_g': 280},
    'lomo con arepa':        {'kcal': 540, 'proteina_g': 50, 'grasas_g': 24, 'carbos_netos_g': 30, 'porcion_g': 290},
    'carne con arepa':       {'kcal': 510, 'proteina_g': 46, 'grasas_g': 22, 'carbos_netos_g': 30, 'porcion_g': 280},
    'bistec':                {'kcal': 330, 'proteina_g': 48, 'grasas_g': 16, 'carbos_netos_g': 0, 'porcion_g': 200},
    'lomo de res':           {'kcal': 310, 'proteina_g': 46, 'grasas_g': 14, 'carbos_netos_g': 0, 'porcion_g': 200},
    'arepa':                 {'kcal': 180, 'proteina_g': 4, 'grasas_g': 5, 'carbos_netos_g': 30, 'porcion_g': 100},
    'arepa de choclo':       {'kcal': 220, 'proteina_g': 5, 'grasas_g': 7, 'carbos_netos_g': 35, 'porcion_g': 120},
    'arepa de huevo':        {'kcal': 350, 'proteina_g': 12, 'grasas_g': 20, 'carbos_netos_g': 30, 'porcion_g': 150},
    'arepa con queso':       {'kcal': 260, 'proteina_g': 9, 'grasas_g': 10, 'carbos_netos_g': 30, 'porcion_g': 120},
    'papa':                  {'kcal': 115, 'proteina_g': 3, 'grasas_g': 0, 'carbos_netos_g': 26, 'porcion_g': 150},
    'papa criolla':          {'kcal': 100, 'proteina_g': 2.5, 'grasas_g': 0.2, 'carbos_netos_g': 23, 'porcion_g': 150},
    'yuca':                  {'kcal': 200, 'proteina_g': 2, 'grasas_g': 0.5, 'carbos_netos_g': 48, 'porcion_g': 150},
    'yuca cocida':           {'kcal': 200, 'proteina_g': 2, 'grasas_g': 0.5, 'carbos_netos_g': 48, 'porcion_g': 150},
    'mazorca':               {'kcal': 177, 'proteina_g': 6, 'grasas_g': 2, 'carbos_netos_g': 38, 'porcion_g': 200},
    'patacones':             {'kcal': 300, 'proteina_g': 2, 'grasas_g': 15, 'carbos_netos_g': 40, 'porcion_g': 150},
    'platano maduro frito':  {'kcal': 250, 'proteina_g': 1, 'grasas_g': 10, 'carbos_netos_g': 40, 'porcion_g': 150},
    'arroz con coco':        {'kcal': 320, 'proteina_g': 5, 'grasas_g': 14, 'carbos_netos_g': 42, 'porcion_g': 200},
    // ── Snacks y antojitos ─────────────────────────────────────────
    'empanada':              {'kcal': 280, 'proteina_g': 8, 'grasas_g': 16, 'carbos_netos_g': 25, 'porcion_g': 120},
    'empanada colombiana':   {'kcal': 280, 'proteina_g': 8, 'grasas_g': 16, 'carbos_netos_g': 25, 'porcion_g': 120},
    'bunuelo':               {'kcal': 120, 'proteina_g': 3, 'grasas_g': 6, 'carbos_netos_g': 12, 'porcion_g': 60},
    'almojabana':            {'kcal': 180, 'proteina_g': 5, 'grasas_g': 8, 'carbos_netos_g': 22, 'porcion_g': 80},
    'pan de bono':           {'kcal': 150, 'proteina_g': 4, 'grasas_g': 6, 'carbos_netos_g': 18, 'porcion_g': 60},
    'pandebono':             {'kcal': 160, 'proteina_g': 5, 'grasas_g': 6, 'carbos_netos_g': 20, 'porcion_g': 65},
    'marranitas':            {'kcal': 350, 'proteina_g': 10, 'grasas_g': 18, 'carbos_netos_g': 35, 'porcion_g': 150},
    'carimanola':            {'kcal': 320, 'proteina_g': 12, 'grasas_g': 16, 'carbos_netos_g': 30, 'porcion_g': 150},
    // ── Keto friendly ──────────────────────────────────────────────
    'aguacate':              {'kcal': 240, 'proteina_g': 3, 'grasas_g': 22, 'carbos_netos_g': 4, 'porcion_g': 150},
    // Ensaladas — varían mucho según ingredientes
    'lechuga':               {'kcal': 15, 'proteina_g': 1.5, 'grasas_g': 0.2, 'carbos_netos_g': 2, 'porcion_g': 100},
    'ensalada':              {'kcal': 60, 'proteina_g': 2, 'grasas_g': 2, 'carbos_netos_g': 8, 'porcion_g': 150},
    'ensalada simple':       {'kcal': 40, 'proteina_g': 2, 'grasas_g': 1, 'carbos_netos_g': 6, 'porcion_g': 150},
    'ensalada mixta':        {'kcal': 120, 'proteina_g': 4, 'grasas_g': 7, 'carbos_netos_g': 10, 'porcion_g': 200},
    'ensalada cesar':        {'kcal': 280, 'proteina_g': 8, 'grasas_g': 22, 'carbos_netos_g': 12, 'porcion_g': 250},
    'ensalada completa':     {'kcal': 200, 'proteina_g': 6, 'grasas_g': 12, 'carbos_netos_g': 14, 'porcion_g': 250},
    'ensalada con queso':    {'kcal': 220, 'proteina_g': 8, 'grasas_g': 14, 'carbos_netos_g': 10, 'porcion_g': 200},
    'espinaca':              {'kcal': 25, 'proteina_g': 3, 'grasas_g': 0.4, 'carbos_netos_g': 2, 'porcion_g': 100},
    'zanahoria':             {'kcal': 40, 'proteina_g': 1, 'grasas_g': 0.2, 'carbos_netos_g': 8, 'porcion_g': 100},
    'pepino':                {'kcal': 15, 'proteina_g': 0.6, 'grasas_g': 0.1, 'carbos_netos_g': 3, 'porcion_g': 100},
    'tomate':                {'kcal': 20, 'proteina_g': 1, 'grasas_g': 0.2, 'carbos_netos_g': 4, 'porcion_g': 100},
    'huevos revueltos':      {'kcal': 300, 'proteina_g': 22, 'grasas_g': 22, 'carbos_netos_g': 2, 'porcion_g': 200},
    'huevos fritos':         {'kcal': 196, 'proteina_g': 13, 'grasas_g': 15, 'carbos_netos_g': 1, 'porcion_g': 100},
    // ── Bebidas permitidas en keto ─────────────────────────────────
    'cafe':                  {'kcal': 5, 'proteina_g': 0.3, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 240},
    'café':                  {'kcal': 5, 'proteina_g': 0.3, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 240},
    'cafe negro':            {'kcal': 5, 'proteina_g': 0.3, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 240},
    'café negro':            {'kcal': 5, 'proteina_g': 0.3, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 240},
    'cafe con leche':        {'kcal': 60, 'proteina_g': 3, 'grasas_g': 3, 'carbos_netos_g': 5, 'porcion_g': 240},
    'café con leche':        {'kcal': 60, 'proteina_g': 3, 'grasas_g': 3, 'carbos_netos_g': 5, 'porcion_g': 240},
    'cafe con crema':        {'kcal': 100, 'proteina_g': 1, 'grasas_g': 10, 'carbos_netos_g': 1, 'porcion_g': 240},
    'te':                    {'kcal': 2, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 240},
    'té':                    {'kcal': 2, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 240},
    'te verde':              {'kcal': 2, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 240},
    'agua':                  {'kcal': 0, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 500},
    'agua con limon':        {'kcal': 10, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 2, 'porcion_g': 500},
    'agua mineral':          {'kcal': 0, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 0, 'porcion_g': 500},
    'leche entera':          {'kcal': 150, 'proteina_g': 8, 'grasas_g': 8, 'carbos_netos_g': 11, 'porcion_g': 240},
    'leche deslactosada':    {'kcal': 145, 'proteina_g': 8, 'grasas_g': 8, 'carbos_netos_g': 11, 'porcion_g': 240},
    'leche de almendras':    {'kcal': 40, 'proteina_g': 1, 'grasas_g': 3, 'carbos_netos_g': 2, 'porcion_g': 240},
    'leche de coco':         {'kcal': 120, 'proteina_g': 1, 'grasas_g': 12, 'carbos_netos_g': 2, 'porcion_g': 240},
    'proteina en polvo':     {'kcal': 120, 'proteina_g': 25, 'grasas_g': 2, 'carbos_netos_g': 3, 'porcion_g': 35},
    'shake proteina':        {'kcal': 180, 'proteina_g': 25, 'grasas_g': 5, 'carbos_netos_g': 5, 'porcion_g': 300},
    'electrolitos':          {'kcal': 10, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 2, 'porcion_g': 500},
    // ── Bebidas NO keto ─────────────────────────────────────────────
    'chocolate caliente':    {'kcal': 180, 'proteina_g': 5, 'grasas_g': 5, 'carbos_netos_g': 28, 'porcion_g': 250},
    'agua de panela':        {'kcal': 80, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 20, 'porcion_g': 250},
    'jugo de mora':          {'kcal': 120, 'proteina_g': 1, 'grasas_g': 0.5, 'carbos_netos_g': 28, 'porcion_g': 250},
    'jugo de naranja':       {'kcal': 110, 'proteina_g': 2, 'grasas_g': 0.5, 'carbos_netos_g': 26, 'porcion_g': 250},
    'gaseosa':               {'kcal': 140, 'proteina_g': 0, 'grasas_g': 0, 'carbos_netos_g': 35, 'porcion_g': 350},
    // ── Nueces y semillas (keto) ───────────────────────────────────
    'mani':                  {'kcal': 280, 'proteina_g': 13, 'grasas_g': 24, 'carbos_netos_g': 5, 'porcion_g': 50},
    'mani natural':          {'kcal': 280, 'proteina_g': 13, 'grasas_g': 24, 'carbos_netos_g': 5, 'porcion_g': 50},
    'mani tostado':          {'kcal': 295, 'proteina_g': 13, 'grasas_g': 25, 'carbos_netos_g': 6, 'porcion_g': 50},
    'nuez':                  {'kcal': 327, 'proteina_g': 7, 'grasas_g': 33, 'carbos_netos_g': 2, 'porcion_g': 50},
    'nuez del brasil':       {'kcal': 330, 'proteina_g': 7, 'grasas_g': 34, 'carbos_netos_g': 2, 'porcion_g': 50},
    'nuez de brasil':        {'kcal': 330, 'proteina_g': 7, 'grasas_g': 34, 'carbos_netos_g': 2, 'porcion_g': 50},
    'almendra':              {'kcal': 290, 'proteina_g': 11, 'grasas_g': 25, 'carbos_netos_g': 4, 'porcion_g': 50},
    'almendras':             {'kcal': 290, 'proteina_g': 11, 'grasas_g': 25, 'carbos_netos_g': 4, 'porcion_g': 50},
    'macadamia':             {'kcal': 370, 'proteina_g': 4, 'grasas_g': 39, 'carbos_netos_g': 2, 'porcion_g': 50},
    'pistacho':              {'kcal': 280, 'proteina_g': 10, 'grasas_g': 23, 'carbos_netos_g': 6, 'porcion_g': 50},
    'semillas de chia':      {'kcal': 245, 'proteina_g': 17, 'grasas_g': 31, 'carbos_netos_g': 2, 'porcion_g': 30},
    'chia':                  {'kcal': 245, 'proteina_g': 17, 'grasas_g': 31, 'carbos_netos_g': 2, 'porcion_g': 30},
    'linaza':                {'kcal': 225, 'proteina_g': 8, 'grasas_g': 18, 'carbos_netos_g': 1, 'porcion_g': 30},
    'ajonjoli':              {'kcal': 280, 'proteina_g': 9, 'grasas_g': 24, 'carbos_netos_g': 4, 'porcion_g': 30},
    'mantequilla de mani':   {'kcal': 190, 'proteina_g': 8, 'grasas_g': 16, 'carbos_netos_g': 4, 'porcion_g': 32},
    // ── Coco ────────────────────────────────────────────────────────
    'coco natural':          {'kcal': 190, 'proteina_g': 2, 'grasas_g': 18, 'carbos_netos_g': 4, 'porcion_g': 80},
    'coco':                  {'kcal': 190, 'proteina_g': 2, 'grasas_g': 18, 'carbos_netos_g': 4, 'porcion_g': 80},
    'coco rallado':          {'kcal': 285, 'proteina_g': 3, 'grasas_g': 28, 'carbos_netos_g': 5, 'porcion_g': 60},
    'agua de coco':          {'kcal': 45, 'proteina_g': 0.5, 'grasas_g': 0.5, 'carbos_netos_g': 9, 'porcion_g': 240},
    'aceite de coco':        {'kcal': 360, 'proteina_g': 0, 'grasas_g': 40, 'carbos_netos_g': 0, 'porcion_g': 40},
    // ── Grasas keto ─────────────────────────────────────────────────
    'aceite de oliva':       {'kcal': 360, 'proteina_g': 0, 'grasas_g': 40, 'carbos_netos_g': 0, 'porcion_g': 40},
    'mantequilla ghee':      {'kcal': 360, 'proteina_g': 0, 'grasas_g': 40, 'carbos_netos_g': 0, 'porcion_g': 40},
    // ── Internacional ──────────────────────────────────────────────
    'pasta':                 {'kcal': 440, 'proteina_g': 16, 'grasas_g': 4, 'carbos_netos_g': 86, 'porcion_g': 300},
    'pizza':                 {'kcal': 530, 'proteina_g': 22, 'grasas_g': 20, 'carbos_netos_g': 66, 'porcion_g': 250},
    'hamburguesa':           {'kcal': 560, 'proteina_g': 30, 'grasas_g': 28, 'carbos_netos_g': 46, 'porcion_g': 250},
    'perro caliente':        {'kcal': 550, 'proteina_g': 18, 'grasas_g': 32, 'carbos_netos_g': 45, 'porcion_g': 200},
  };

  Map<String, dynamic>? _buscarEnBDLocal(String nombre) {
    final n = nombre.toLowerCase().trim();
    // Búsqueda exacta
    if (_bdColombia.containsKey(n)) {
      final d = _bdColombia[n]!;
      final carbos = d['carbos_netos_g']!;
      final porcion = d['porcion_g'] ?? 300.0;
      final carbos100g = carbos / (porcion / 100);
      return {'nombre': nombre, 'porcion_g': porcion, 'kcal': d['kcal'], 'proteina_g': d['proteina_g'], 'grasas_g': d['grasas_g'], 'carbos_netos_g': carbos, 'es_keto': carbos100g < 5};
    }
    // Búsqueda parcial
    for (final key in _bdColombia.keys) {
      if (n.contains(key) || key.contains(n)) {
        final d = _bdColombia[key]!;
        final carbos = d['carbos_netos_g']!;
        final porcion = d['porcion_g'] ?? 300.0;
      final carbos100g = carbos / (porcion / 100);
      return {'nombre': nombre, 'porcion_g': porcion, 'kcal': d['kcal'], 'proteina_g': d['proteina_g'], 'grasas_g': d['grasas_g'], 'carbos_netos_g': carbos, 'es_keto': carbos100g < 5};
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _buscarMacros(String nombre) async {
    try {
      final resp = await _dio.get(
        'https://world.openfoodfacts.org/cgi/search.pl',
        queryParameters: {
          'search_terms': nombre,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': 5,
          'fields': 'product_name,nutriments',
          'lc': 'es',
        },
        options: Options(sendTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)),
      );
      final products = (resp.data['products'] as List? ?? []);
      for (final p in products) {
        final n = p['nutriments'] ?? {};
        final kcal = _num(n['energy-kcal_100g']);
        if (kcal > 0) {
          final carbos = _num(n['carbohydrates_100g']);
          return {
            'nombre': nombre,
            'porcion_g': 300.0,
            'kcal': kcal,
            'proteina_g': _num(n['proteins_100g']),
            'grasas_g': _num(n['fat_100g']),
            'carbos_netos_g': carbos,
            'es_keto': carbos < 20,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _parsearRespuesta(String texto) {
    debugPrint('🍽️ Gemini respuesta: $texto');
    try {
      final result = <String, dynamic>{};
      for (final linea in texto.split('\n')) {
        final l = linea.trim();
        if (l.startsWith('1.NAME:') || l.startsWith('1. NAME:')) {
          result['nombre'] = l.split(':').sublist(1).join(':').trim();
        } else if (l.startsWith('2.GRAMS:') || l.startsWith('2. GRAMS:')) {
          result['porcion_g'] = double.tryParse(l.split(':').last.trim()) ?? 300;
        } else if (l.startsWith('3.KCAL:') || l.startsWith('3. KCAL:')) {
          result['kcal'] = double.tryParse(l.split(':').last.trim()) ?? 0;
        } else if (l.startsWith('4.PROT:') || l.startsWith('4. PROT:')) {
          result['proteina_g'] = double.tryParse(l.split(':').last.trim()) ?? 0;
        } else if (l.startsWith('5.FAT:') || l.startsWith('5. FAT:')) {
          result['grasas_g'] = double.tryParse(l.split(':').last.trim()) ?? 0;
        } else if (l.startsWith('6.CARB:') || l.startsWith('6. CARB:')) {
          result['carbos_netos_g'] = double.tryParse(l.split(':').last.trim()) ?? 0;
        } else if (l.startsWith('7.KETO:') || l.startsWith('7. KETO:')) {
          result['es_keto'] = l.split(':').last.trim().toLowerCase() == 'true';
        }
      }
      return result;
    } catch (e) {
      debugPrint('🍽️ Parse error: $e');
      return {};
    }
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
                        color: const Color(0xFF1E1A0A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC9A227).withOpacity(0.4)),
                      ),
                      child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFC9A227), fontSize: 15, height: 1.5)),
                    ),

                  // Lista de ingredientes por separado
                  if (_ingredientes.isNotEmpty && !_analizando) ...[
                    _ListaIngredientes(
                      ingredientes: _ingredientes,
                      perfil: sl<PerfilService>().perfilActual,
                      onAgregar: (ingrediente) {
                        final comida = ingrediente['comida']?.toString() ?? _comidaActual();
                        final entidad = AlimentoRegistradoEntity(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          nombre: ingrediente['nombre']?.toString() ?? 'Alimento',
                          cantidadG: _num(ingrediente['gramos']),
                          unidad: 'g',
                          calorias: _num(ingrediente['kcal']),
                          grasasG: _num(ingrediente['grasas_g']),
                          proteinaG: _num(ingrediente['proteina_g']),
                          carbosNetosG: _num(ingrediente['carbos_netos_g']),
                          comida: comida,
                          horaRegistro: DateTime.now(),
                          fuenteRegistro: 'foto_ia',
                        );
                        widget.onAgregar(entidad);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('✓ ${ingrediente['nombre']} agregado al $comida'),
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

// Sustituciones keto para alimentos no keto
const Map<String, String> _sustituciones = {
  'arepa': 'Cambia por aguacate o queso blanco',
  'arroz': 'Cambia por coliflor salteada o ensalada',
  'papa': 'Cambia por brócoli o espárragos',
  'yuca': 'Cambia por pepino o apio',
  'mazorca': 'Cambia por espinaca salteada',
  'pan': 'Cambia por lechuga como wrap',
  'platano': 'Cambia por aguacate',
  'patacon': 'Cambia por chicharrón o queso',
  'frijoles': 'Reduce la porción o cambia por aguacate',
  'pasta': 'Cambia por zucchini en espiral',
};

String? _sugerenciaKeto(String nombre) {
  final n = nombre.toLowerCase();
  for (final key in _sustituciones.keys) {
    if (n.contains(key)) return _sustituciones[key];
  }
  return null;
}

class _ListaIngredientes extends StatelessWidget {
  final List<Map<String, dynamic>> ingredientes;
  final void Function(Map<String, dynamic>) onAgregar;
  final dynamic perfil;
  const _ListaIngredientes({required this.ingredientes, required this.onAgregar, this.perfil});

  double _num(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

  void _seleccionarComida(BuildContext context, Map<String, dynamic> ing, void Function(Map<String, dynamic>) onAgregar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF182318),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agregar "${ing['nombre']}" a...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 16),
            ...['🌅 Desayuno', '☀️ Almuerzo', '🌙 Cena', '⚡ Snack'].map((comida) {
              final key = comida.split(' ')[1].toLowerCase();
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  final ingConComida = Map<String, dynamic>.from(ing);
                  ingConComida['comida'] = key;
                  onAgregar(ingConComida);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1510),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A3D2A)),
                  ),
                  child: Text(comida, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalKcal = ingredientes.fold(0.0, (s, i) => s + _num(i['kcal']));
    final totalCarbos = ingredientes.fold(0.0, (s, i) => s + _num(i['carbos_netos_g']));
    final carbosMeta = perfil?.carbosG?.toDouble() ?? 26.0;
    final kcalMeta = perfil?.kcal?.toDouble() ?? 1889.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resumen total
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF182318),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A3D2A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [
                const Text('Total plato', style: TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
                Text('${totalKcal.round()} kcal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFC9A227))),
              ]),
              Column(children: [
                const Text('Tu meta', style: TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
                Text('${kcalMeta.round()} kcal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF8FAF8F))),
              ]),
              Column(children: [
                const Text('Carbos totales', style: TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
                Text('${totalCarbos.round()}g / ${carbosMeta.round()}g',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                    color: totalCarbos > carbosMeta ? const Color(0xFFEF4444) : const Color(0xFF7CB518))),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Cada ingrediente
        ...ingredientes.map((ing) {
          final esKeto = ing['es_keto'];
          final enBd = ing['en_bd'] == true;
          final sugerencia = esKeto == false ? _sugerenciaKeto(ing['nombre'].toString()) : null;
          final color = esKeto == true ? const Color(0xFF7CB518)
              : esKeto == false ? const Color(0xFFEF4444)
              : const Color(0xFF8FAF8F);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF182318),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ing['nombre'].toString(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('${_num(ing['gramos']).round()}g · ${_num(ing['kcal']).round()} kcal · ${_num(ing['carbos_netos_g']).toStringAsFixed(1)}g carbos',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8FAF8F))),
                    ],
                  )),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      esKeto == true ? '✅ KETO' : esKeto == false ? '❌ NO KETO' : '❓',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (enBd)
                    GestureDetector(
                      onTap: () => _seleccionarComida(context, ing, onAgregar),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.verde, borderRadius: BorderRadius.circular(10)),
                        child: const Text('+ Agregar', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ]),
                if (sugerencia != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1A0A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Text('💡 ', style: TextStyle(fontSize: 13)),
                      Expanded(child: Text(sugerencia,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFC9A227)))),
                    ]),
                  ),
                ],
                if (!enBd)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('No en BD — usa búsqueda manual para datos exactos',
                      style: TextStyle(fontSize: 11, color: Color(0xFF4A6B4A))),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TarjetaResultado extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAgregar;
  final dynamic perfil;
  const _TarjetaResultado({required this.data, required this.onAgregar, this.perfil});

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
          if (data['estimado'] == true)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('⚠️ Valores aproximados — no disponible en BD verificada',
                style: TextStyle(fontSize: 11, color: Color(0xFFC9A227))),
            ),

          // Comparativa simplificada con metas del usuario
          if (perfil != null) ...[
            const SizedBox(height: 12),
            _ComparativaMeta(
              kcalPlato: _num(data['kcal']),
              carbosPlato: carbos,
              kcalMeta: perfil.kcal.toDouble(),
              carbosMeta: perfil.carbosG.toDouble(),
            ),
          ],
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

class _ComparativaMeta extends StatelessWidget {
  final double kcalPlato, carbosPlato, kcalMeta, carbosMeta;
  const _ComparativaMeta({
    required this.kcalPlato, required this.carbosPlato,
    required this.kcalMeta, required this.carbosMeta,
  });

  @override
  Widget build(BuildContext context) {
    final carbosExcede = carbosPlato > carbosMeta;
    final kcalRestantes = kcalMeta - kcalPlato;
    final carbosRestantes = carbosMeta - carbosPlato;

    return Column(
      children: [
        // ── Calorías ──────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF182318),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A3D2A)),
          ),
          child: Column(
            children: [
              const Text('🔥 Calorías', style: TextStyle(fontSize: 13, color: Color(0xFF8FAF8F), fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NumeroMeta('Este plato', '${kcalPlato.round()} kcal', const Color(0xFFC9A227)),
                  Container(width: 1, height: 40, color: const Color(0xFF2A3D2A)),
                  _NumeroMeta('Tu meta diaria', '${kcalMeta.round()} kcal', const Color(0xFF8FAF8F)),
                  Container(width: 1, height: 40, color: const Color(0xFF2A3D2A)),
                  _NumeroMeta('Te quedan', '${kcalRestantes.round()} kcal',
                    kcalRestantes < 0 ? const Color(0xFFEF4444) : const Color(0xFF7CB518)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // ── Carbos (crítico para keto) ────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: carbosExcede ? const Color(0xFF2B0F0F) : const Color(0xFF182318),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: carbosExcede ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFF2A3D2A),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🍞 Carbos', style: TextStyle(fontSize: 13, color: Color(0xFF8FAF8F), fontWeight: FontWeight.w600)),
                  if (carbosExcede) ...[
                    const SizedBox(width: 6),
                    const Text('⚠️ EXCEDE LÍMITE KETO', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NumeroMeta('Este plato', '${carbosPlato.round()}g',
                    carbosExcede ? const Color(0xFFEF4444) : const Color(0xFFC9A227)),
                  Container(width: 1, height: 40, color: const Color(0xFF2A3D2A)),
                  _NumeroMeta('Límite keto', '${carbosMeta.round()}g', const Color(0xFF8FAF8F)),
                  Container(width: 1, height: 40, color: const Color(0xFF2A3D2A)),
                  _NumeroMeta(carbosExcede ? 'Te pasaste' : 'Te quedan',
                    '${carbosRestantes.abs().round()}g',
                    carbosExcede ? const Color(0xFFEF4444) : const Color(0xFF7CB518)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumeroMeta extends StatelessWidget {
  final String label, valor;
  final Color color;
  const _NumeroMeta(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8FAF8F))),
      const SizedBox(height: 4),
      Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
    ],
  );
}

class _BarraMeta extends StatelessWidget {
  final String label;
  final double valor, meta;
  final Color color;
  const _BarraMeta(this.label, this.valor, this.meta, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = meta > 0 ? (valor / meta).clamp(0.0, 1.5) : 0.0;
    final pctStr = '${(pct * 100).round()}%';
    final excede = pct > 1.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8FAF8F)))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF2A3D2A),
              valueColor: AlwaysStoppedAnimation(excede ? const Color(0xFFEF4444) : color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(pctStr,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: excede ? const Color(0xFFEF4444) : const Color(0xFF8FAF8F))),
      ]),
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
