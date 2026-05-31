import 'dart:convert';
import 'package:dio/dio.dart';
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

  /// Analiza una imagen de comida y devuelve JSON con macros estimados
  Future<String> analizarFoto(List<int> imagenBytes) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final base64Img = base64Encode(imagenBytes);

    final body = {
      'system_instruction': {
        'parts': [{'text': _sistemaKeto}],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Img,
              }
            },
            {
              'text': '''Analiza esta foto de comida y responde ÚNICAMENTE con un JSON válido con este formato exacto (sin texto adicional):
{
  "nombre": "nombre del plato o alimento",
  "porcion_g": 300,
  "kcal": 450,
  "proteina_g": 35,
  "grasas_g": 28,
  "carbos_netos_g": 8,
  "es_keto": true,
  "descripcion": "breve descripción de 1 línea"
}
Estima los valores para una porción típica visible en la imagen. Si no puedes identificar la comida, usa nombre "Alimento no identificado" con valores en 0.'''
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 512,
      },
    };

    try {
      final response = await _dio.post(
        _baseUrl,
        queryParameters: {'key': apiKey},
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '{}';
    } catch (e) {
      return '{}';
    }
  }
}
