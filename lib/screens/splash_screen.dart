import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/commercant_provider.dart';
import '../utils/app_colors.dart';
import 'commercant/setup_boutique_screen.dart';
import 'commercant/attente_validation_screen.dart';

class SplashScreen extends StatefulWidget {
  final String redirectRole;
  final String redirectRoute;
  const SplashScreen({super.key, required this.redirectRole, required this.redirectRoute});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _checkAndNavigate();
    });
  }

  Future<void> _checkAndNavigate() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final commercantProvider = Provider.of<CommercantProvider>(context, listen: false);

    await auth.tryAutoLogin();
    if (!mounted) return;

    if (!auth.isAuth) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (auth.role != widget.redirectRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ce compte n\'est pas un compte ${widget.redirectRole}')),
      );
      await auth.deconnecter();
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Charger le profil boutique
    await commercantProvider.chargerProfil();
    if (!mounted) return;

    if (!commercantProvider.aUnProfil) {
      // Pas encore de profil → configurer la boutique
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupBoutiqueScreen()),
      );
      return;
    }

    if (commercantProvider.estEnAttente) {
      // Profil créé mais en attente de validation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttenteValidationScreen()),
      );
      return;
    }

    // Compte actif → dashboard
    Navigator.pushReplacementNamed(context, widget.redirectRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.noirCarbone,
                          border: Border.all(color: AppColors.primary, width: 3),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 40)],
                        ),
                        child: const Icon(Icons.store, size: 60, color: AppColors.primary),
                      ),
                      const SizedBox(height: 32),
                      Text('GOLIVREUR PRO',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blancPur,
                            letterSpacing: 4,
                            shadows: [Shadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20)],
                          )),
                      const SizedBox(height: 12),
                      Text('Gérez votre boutique',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppColors.grisMetallique,
                            letterSpacing: 2,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 40, right: 40,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _controller.value,
                  backgroundColor: AppColors.grisAnthracite,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}