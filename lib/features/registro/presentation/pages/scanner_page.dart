import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../hoy/domain/entities/alimento_registrado_entity.dart';

/// Pantalla de escaneo de código de barras para registrar alimentos.
/// Llama Open Food Facts (sin key) para obtener datos nutricionales.
class ScannerPage extends StatefulWidget {
  /// Comida a la que se agrega el alimento (Desayuno, Almuerzo, Cena, Snacks).
  final String tipoComida;

  const ScannerPage({super.key, this.tipoComida = 'General'});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _buscando = false;
  bool _pausado = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onBarcode(BarcodeCapture capture) async {
    if (_buscando || _pausado) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() { _buscando = true; _error = null; _pausado = true; });
    await _ctrl.stop();

    try {
      final producto = await _buscarProducto(code);
      if (!mounted) return;

      if (producto != null) {
        _mostrarConfirmacion(producto);
      } else {
        setState(() {
          _error = 'Producto no encontrado en la base de datos.\nIntenta buscar manualmente.';
          _buscando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de conexión. Verifica tu internet.';
        _buscando = false;
      });
    }
  }

  Future<_ProductoScaneado?> _buscarProducto(String barcode) async {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    // Open Food Facts API — gratuita, sin autenticación
    final url = 'https://world.openfoodfacts.net/api/v2/product/$barcode?fields=product_name,nutriments,serving_size,brands';

    final resp = await dio.get(url);
    if (resp.statusCode != 200) return null;

    final data = resp.data is String ? json.decode(resp.data) : resp.data;
    if (data['status'] != 1) return null;

    final product = data['product'] as Map<String, dynamic>;
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    // Nutrients per 100g
    final kcalPer100 = (nutriments['energy-kcal_100g'] as num?)?.toDouble()
        ?? (nutriments['energy-kcal'] as num?)?.toDouble()
        ?? 0;
    final grasasPer100 = (nutriments['fat_100g'] as num?)?.toDouble() ?? 0;
    final proteinaPer100 = (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0;
    final carbosPer100 = (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0;

    return _ProductoScaneado(
      nombre: product['product_name'] as String? ?? 'Producto $barcode',
      marca: product['brands'] as String? ?? '',
      barcode: barcode,
      kcalPer100g: kcalPer100,
      grasasPer100g: grasasPer100,
      proteinaPer100g: proteinaPer100,
      carbosPer100g: carbosPer100,
    );
  }

  void _mostrarConfirmacion(_ProductoScaneado producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmacionSheet(
        producto: producto,
        tipoComida: widget.tipoComida,
        onAgregar: (alimento) {
          context.pop(alimento); // Devolver el alimento al caller
        },
        onReintentar: () {
          Navigator.pop(context);
          setState(() { _buscando = false; _pausado = false; _error = null; });
          _ctrl.start();
        },
      ),
    );
  }

  void _reintentarScan() {
    setState(() { _buscando = false; _pausado = false; _error = null; });
    _ctrl.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Cámara ───────────────────────────────────────────
          MobileScanner(
            controller: _ctrl,
            onDetect: _onBarcode,
          ),

          // ── Overlay ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _ctrl.toggleTorch(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Marco de escaneo
                Container(
                  width: 260, height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.verde, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Esquinas decorativas
                      Positioned(top: 0, left: 0, child: _Corner(color: AppColors.verde)),
                      Positioned(top: 0, right: 0, child: _Corner(color: AppColors.verde, flipH: true)),
                      Positioned(bottom: 0, left: 0, child: _Corner(color: AppColors.verde, flipV: true)),
                      Positioned(bottom: 0, right: 0, child: _Corner(color: AppColors.verde, flipH: true, flipV: true)),
                      if (_buscando)
                        const Center(child: CircularProgressIndicator(color: AppColors.verde)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Mensaje
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _error ?? (_buscando
                        ? 'Buscando producto...'
                        : 'Apunta al código de barras del producto'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _error != null ? Colors.red[300] : Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verde,
                      foregroundColor: AppColors.blanco,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: const Size(0, 0),
                    ),
                    onPressed: _reintentarScan,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Escanear de nuevo', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],

                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Compatible con códigos EAN-13, UPC-A',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
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

class _ProductoScaneado {
  final String nombre;
  final String marca;
  final String barcode;
  final double kcalPer100g;
  final double grasasPer100g;
  final double proteinaPer100g;
  final double carbosPer100g;

  const _ProductoScaneado({
    required this.nombre,
    required this.marca,
    required this.barcode,
    required this.kcalPer100g,
    required this.grasasPer100g,
    required this.proteinaPer100g,
    required this.carbosPer100g,
  });

  /// Calcula macros para una cantidad específica en gramos
  double kcalPara(double gramos) => (kcalPer100g * gramos) / 100;
  double grasasPara(double gramos) => (grasasPer100g * gramos) / 100;
  double proteinaPara(double gramos) => (proteinaPer100g * gramos) / 100;
  double carbosPara(double gramos) => (carbosPer100g * gramos) / 100;
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmacionSheet extends StatefulWidget {
  final _ProductoScaneado producto;
  final String tipoComida;
  final ValueChanged<AlimentoRegistradoEntity> onAgregar;
  final VoidCallback onReintentar;

  const _ConfirmacionSheet({
    required this.producto,
    required this.tipoComida,
    required this.onAgregar,
    required this.onReintentar,
  });

  @override
  State<_ConfirmacionSheet> createState() => _ConfirmacionSheetState();
}

class _ConfirmacionSheetState extends State<_ConfirmacionSheet> {
  double _gramos = 100;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          // Producto info
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.fondoVerde,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('🏷️', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nombre,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              if (p.marca.isNotEmpty)
                Text(p.marca, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 20),

          // Cantidad
          Text('Cantidad: ${_gramos.round()} g',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.verde,
              thumbColor: AppColors.verde,
              overlayColor: AppColors.verde.withValues(alpha: 0.15),
              trackHeight: 6,
            ),
            child: Slider(
              value: _gramos, min: 10, max: 500,
              divisions: 49,
              onChanged: (v) => setState(() => _gramos = v),
            ),
          ),

          // Macros calculados
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fondoVerde,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MacroPill('${p.kcalPara(_gramos).round()}', 'kcal', AppColors.oro),
                _MacroPill('${p.grasasPara(_gramos).toStringAsFixed(1)}g', 'Grasa', AppColors.macroGrasas),
                _MacroPill('${p.proteinaPara(_gramos).toStringAsFixed(1)}g', 'Prot.', AppColors.macroProtein),
                _MacroPill('${p.carbosPara(_gramos).toStringAsFixed(1)}g', 'Carb.', AppColors.macroCarbos),
              ],
            ),
          ),

          // Keto check
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: p.carbosPer100g <= 5
                  ? AppColors.fondoVerde
                  : p.carbosPer100g <= 15
                      ? AppColors.fondoOro
                      : AppColors.fondoRojo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Text(
                p.carbosPer100g <= 5 ? '✅' : p.carbosPer100g <= 15 ? '⚠️' : '🚫',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Text(
                p.carbosPer100g <= 5
                    ? 'Apto para keto — bajo en carbos'
                    : p.carbosPer100g <= 15
                        ? 'Moderado en carbos — consume con cuidado'
                        : 'Alto en carbos — no recomendado en keto',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.carbosPer100g <= 5
                      ? AppColors.verdeOs
                      : p.carbosPer100g <= 15
                          ? const Color(0xFF92400E)
                          : AppColors.error,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // Botones
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(0, 0),
                ),
                onPressed: widget.onReintentar,
                child: const Text('Escanear otro', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verde,
                  foregroundColor: AppColors.blanco,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(0, 0),
                ),
                onPressed: () {
                  final alimento = AlimentoRegistradoEntity(
                    id: '${p.barcode}_${DateTime.now().millisecondsSinceEpoch}',
                    nombre: p.nombre,
                    cantidadG: _gramos,
                    unidad: 'g',
                    calorias: p.kcalPara(_gramos),
                    grasasG: p.grasasPara(_gramos),
                    proteinaG: p.proteinaPara(_gramos),
                    carbosNetosG: p.carbosPara(_gramos),
                    comida: widget.tipoComida.toLowerCase(),
                    horaRegistro: DateTime.now(),
                    fuenteRegistro: 'codigo_barras',
                  );
                  widget.onAgregar(alimento);
                },
                child: const Text('Agregar al registro', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
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
    return Column(children: [
      Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  final bool flipH;
  final bool flipV;
  const _Corner({required this.color, this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
      child: CustomPaint(
        size: const Size(24, 24),
        painter: _CornerPainter(color: color),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
