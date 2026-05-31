import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/perfil_service.dart';
import '../../../../features/gem/data/services/gemini_service.dart';

/// Pantalla de Login / Registro — KETORA Premium
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _mostrarEmail = false;
  bool _esRegistro = false;
  bool _cargando = false;
  bool _verPass = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (_mostrarEmail) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      await _authConEmail();
    } else {
      // Google Sign-In — por ahora va directo al onboarding (sin SDK nativo configurado)
      setState(() => _cargando = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _cargando = false);
      context.go(AppRoutes.onboarding);
    }
  }

  Future<void> _authConEmail() async {
    setState(() { _cargando = true; _errorMsg = null; });
    try {
      UserCredential cred;
      if (_esRegistro) {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
        // Actualizar displayName si se registra con nombre
        if (_nameCtrl.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_nameCtrl.text.trim());
        }
      } else {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      }

      if (!mounted) return;

      // Verificar si ya completó el onboarding
      final uid = cred.user!.uid;
      final perfilExiste = await sl<PerfilService>().onboardingCompletado(uid);

      if (perfilExiste) {
        // Cargar perfil y sincronizar GEM
        final perfil = await sl<PerfilService>().cargarPerfil(uid);
        if (perfil != null) {
          sl<GeminiService>().actualizarPerfil(
            nombre:    perfil.nombre,
            objetivo:  perfil.objetivo,
            kcal:      perfil.kcal,
            grasasG:   perfil.grasasG,
            proteinaG: perfil.proteinaG,
            carbosG:   perfil.carbosG,
          );
        }
        if (mounted) context.go(AppRoutes.hoy);
      } else {
        if (mounted) context.go(AppRoutes.onboarding);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMsg = _traducirError(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMsg = 'Error inesperado. Intenta de nuevo.';
      });
    }
  }

  String _traducirError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No encontramos una cuenta con ese email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        // Firebase SDK v4+ unifica user-not-found y wrong-password
        return 'Email o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Este email ya tiene una cuenta. Intenta iniciar sesión.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      case 'operation-not-allowed':
      case 'unknown':
        return 'Inicio de sesión no disponible. Contacta soporte.';
      default:
        return 'Error al iniciar sesión. Intenta de nuevo.';
    }
  }

  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo negro total (como el logo)
          Positioned.fill(
            child: Container(color: Colors.black),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(color: Colors.black),
          ),

          // Círculos decorativos
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 80, right: 40,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo real KETORA
                    Image.asset(
                      'assets/images/logo_horizontal.png',
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    const Text('Tu guía keto inteligente',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      )),

                    const SizedBox(height: 48),

                    // Card de login
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.blanco,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mostrarEmail
                              ? (_esRegistro ? 'Crear cuenta' : 'Iniciar sesión')
                              : 'Comenzar',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _mostrarEmail
                              ? (_esRegistro ? 'Crea tu cuenta gratis' : 'Bienvenido de vuelta')
                              : 'Elige cómo quieres ingresar',
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),

                          if (!_mostrarEmail) ...[
                            // Botón Google
                            _SocialBtn(
                              label: 'Continuar con Google',
                              icon: _GoogleIcon(),
                              onTap: _continuar,
                            ),
                            const SizedBox(height: 12),

                            // Separador
                            Row(children: [
                              const Expanded(child: Divider()),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('o', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                              ),
                              const Expanded(child: Divider()),
                            ]),
                            const SizedBox(height: 12),

                            // Botón email
                            _SocialBtn(
                              label: 'Continuar con email',
                              icon: const Icon(Icons.email_outlined, color: AppColors.verde, size: 22),
                              onTap: () => setState(() => _mostrarEmail = true),
                              outlined: true,
                            ),
                          ] else ...[
                            // Formulario email/password
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (_esRegistro) ...[
                                    _Campo(
                                      ctrl: _nameCtrl,
                                      label: 'Tu nombre',
                                      icon: Icons.person_outline_rounded,
                                      validator: (v) => (v?.isEmpty ?? true) ? 'Escribe tu nombre' : null,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  _Campo(
                                    ctrl: _emailCtrl,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboard: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v?.isEmpty ?? true) return 'Escribe tu email';
                                      if (!v!.contains('@')) return 'Email inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _Campo(
                                    ctrl: _passCtrl,
                                    label: 'Contraseña',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: !_verPass,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _verPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: AppColors.textHint, size: 20,
                                      ),
                                      onPressed: () => setState(() => _verPass = !_verPass),
                                    ),
                                    validator: (v) {
                                      if (v?.isEmpty ?? true) return 'Escribe tu contraseña';
                                      if (v!.length < 6) return 'Mínimo 6 caracteres';
                                      return null;
                                    },
                                  ),
                                  if (!_esRegistro) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        child: const Text('¿Olvidaste tu contraseña?',
                                          style: TextStyle(fontSize: 12, color: AppColors.verde)),
                                      ),
                                    ),
                                  ] else
                                    const SizedBox(height: 14),
                                ],
                              ),
                            ),

                            // Error message
                            if (_errorMsg != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(_errorMsg!,
                                    style: const TextStyle(fontSize: 13, color: AppColors.error))),
                                ]),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Botón principal
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.verde,
                                  foregroundColor: AppColors.blanco,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                onPressed: _cargando ? null : _continuar,
                                child: _cargando
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      _esRegistro ? 'Crear mi cuenta' : 'Entrar',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Toggle registro/login
                            GestureDetector(
                              onTap: () => setState(() => _esRegistro = !_esRegistro),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _esRegistro ? '¿Ya tienes cuenta? ' : '¿No tienes cuenta? ',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    _esRegistro ? 'Iniciar sesión' : 'Crear cuenta gratis',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.verde),
                                  ),
                                ],
                              ),
                            ),

                            // Volver
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() { _mostrarEmail = false; _esRegistro = false; }),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.textHint),
                                  SizedBox(width: 4),
                                  Text('Otras opciones', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Al continuar aceptas nuestros Términos de Servicio\ny Política de Privacidad',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _SocialBtn extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final bool outlined;

  const _SocialBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : AppColors.fondoGris,
          borderRadius: BorderRadius.circular(16),
          border: outlined ? Border.all(color: AppColors.verde, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: outlined ? AppColors.verde : AppColors.textPrimary,
              )),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _Campo({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.fondoGris,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.verde, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text('G',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
          )),
      ),
    );
  }
}
