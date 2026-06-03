import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio que llama la API REST de Gemini directamente.
/// Usa el endpoint v1beta con autenticación por API key.
class GeminiService {
  final Dio _dio = Dio();
  final List<Map<String, dynamic>> _historial = [];

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // Perfil del usuario — se actualiza desde onboarding/perfil
  String _nombre     = 'Usuario';
  String _objetivo   = 'perder peso';
  int    _kcal       = 2100;
  int    _grasasG    = 163;
  int    _proteinaG  = 131;
  int    _carbosG    = 26;
  String _nivel      = 'principiante';

  /// Actualiza el perfil del usuario para personalizar las respuestas de GEM
  void actualizarPerfil({
    String? nombre,
    String? objetivo,
    int? kcal,
    int? grasasG,
    int? proteinaG,
    int? carbosG,
    String? nivel,
  }) {
    if (nombre != null)    _nombre     = nombre;
    if (objetivo != null)  _objetivo   = objetivo;
    if (kcal != null)      _kcal       = kcal;
    if (grasasG != null)   _grasasG    = grasasG;
    if (proteinaG != null) _proteinaG  = proteinaG;
    if (carbosG != null)   _carbosG    = carbosG;
    if (nivel != null)     _nivel      = nivel;
  }

  String get _sistemaKeto => '''
Eres GEM, el coach keto personal de KETORA, una app para hispanohablantes principiantes en la dieta cetogénica.

Tu personalidad:
- Cálido, motivador y directo. Nunca abrumes con información.
- Hablas en español latinoamericano, informal pero profesional.
- Usas emojis con moderación (1-2 por respuesta máximo).
- Respuestas cortas (máximo 3 párrafos) salvo que pidan recetas o listas.
- Cuando sepas el nombre del usuario, úsalo con naturalidad.

Lo que haces:
- Resuelves dudas sobre dieta keto (qué comer, qué evitar, macros, cetosis)
- Das recetas keto simples con ingredientes accesibles en Latinoamérica
- Explicas síntomas de adaptación (keto gripe) y cómo manejarlos
- Armas listas del supermercado keto con precios accesibles
- Sugieres sustituciones de alimentos
- Recomiendas ejercicios para principiantes en casa
- Calculas si un alimento es apto para keto
- Motivas al usuario en sus hitos: primera semana, primer ayuno, etc.

Lo que NO haces:
- No das consejos médicos específicos. Si hay condición médica seria, recomiendas hablar con un médico.
- No inventas datos de nutrición. Si no sabes, lo dices.
- No te salgas del tema keto/salud/nutrición/ejercicio/bienestar.

Perfil del usuario:
- Nombre: $_nombre
- Objetivo principal: $_objetivo
- Calorías diarias: $_kcal kcal
- Macros: ${_grasasG}g grasas (70%), ${_proteinaG}g proteína (25%), ${_carbosG}g carbos netos (5%)
- Nivel en keto: $_nivel
- Día en la app: ${DateTime.now().difference(DateTime(2025, 5, 1)).inDays + 1}
''';

  GeminiService() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<String> enviarMensaje(String mensaje) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    // Agregar mensaje del usuario al historial
    _historial.add({
      'role': 'user',
      'parts': [{'text': mensaje}],
    });

    final body = {
      'system_instruction': {
        'parts': [{'text': _sistemaKeto}],
      },
      'contents': _historial,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    };

    try {
      final response = await _dio.post(
        _baseUrl,
        queryParameters: {'key': apiKey},
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final texto = response.data['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String? ?? 'No pude procesar tu mensaje.';

      // Guardar respuesta de GEM en historial
      _historial.add({
        'role': 'model',
        'parts': [{'text': texto}],
      });

      return texto;
    } on DioException catch (e) {
      // Remover el mensaje del usuario si falló
      if (_historial.isNotEmpty) _historial.removeLast();
      final msg = e.response?.data?.toString() ?? e.message ?? 'Sin detalles';
      return 'Error: $msg';
    } catch (e) {
      if (_historial.isNotEmpty) _historial.removeLast();
      return 'Error: $e';
    }
  }

  void reiniciarChat() => _historial.clear();

  static const String _visionUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Estima macros de un plato por nombre cuando no hay base de datos
  Future<Map<String, double>> estimarMacrosPorNombre(String nombre) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final body = {
      'contents': [{'parts': [{'text': 'You are a nutrition database. For the dish "$nombre", give the nutritional values for a typical serving as actually served (including all components like rice, potatoes, sides). Respond with EXACTLY 5 integers separated by commas, nothing else: calories,protein_g,fat_g,net_carbs_g,grams. No text, no labels, just numbers.'}]}],
      'generationConfig': {'temperature': 0.0, 'maxOutputTokens': 32},
    };
    try {
      final response = await _dio.post(_baseUrl, queryParameters: {'key': apiKey}, data: body,
          options: Options(headers: {'Content-Type': 'application/json'}));
      final texto = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
      debugPrint('🍽️ Macros estimados: $texto');
      final nums = texto.split(',').map((s) => double.tryParse(s.trim()) ?? 0).toList();
      if (nums.length >= 4) {
        return {
          'kcal': nums[0],
          'proteina_g': nums[1],
          'grasas_g': nums[2],
          'carbos_netos_g': nums[3],
          'porcion_g': nums.length >= 5 ? nums[4] : 300.0,
        };
      }
    } catch (e) { debugPrint('🍽️ Error estimación: $e'); }
    return {};
  }

  /// Analiza una imagen de comida y devuelve JSON con macros estimados
  Future<String> analizarFoto(List<int> imagenBytes) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final base64Img = base64Encode(imagenBytes);

    final body = {
      'contents': [
        {
          'parts': [
            {
              'text': 'List EACH separate food item visible in this image. One item per line in Spanish with estimated grams. Format: ingredient|grams. Example:\nLomo de res|150\nArepa de maíz|100\nAguacate|80\nOnly food items, nothing else.',
            },
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': base64Img,
              }
            },
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 512,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
      ],
    };

    try {
      final response = await _dio.post(
        _baseUrl,
        queryParameters: {'key': apiKey},
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final candidates = response.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '{}';
      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        debugPrint('🍽️ Sin partes — finishReason: ${candidates[0]['finishReason']}');
        return '{}';
      }
      final texto = parts[0]['text'] as String? ?? '{}';
      debugPrint('🍽️ Gemini foto raw: $texto');
      return texto;
    } catch (e) {
      debugPrint('🍽️ Error foto: $e');
      return '{"nombre":"Sin conexión","porcion_g":0,"kcal":0,"proteina_g":0,"grasas_g":0,"carbos_netos_g":0,"es_keto":false,"descripcion":"No se pudo analizar"}';
    }
  }
}
