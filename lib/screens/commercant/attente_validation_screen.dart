import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/commercant_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import 'setup_boutique_screen.dart';

class AttenteValidationScreen extends StatefulWidget {
  const AttenteValidationScreen({super.key});

  @override
  State<AttenteValidationScreen> createState() => _AttenteValidationScreenState();
}

class _AttenteValidationScreenState extends State<AttenteValidationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Vérifier le statut toutes les 30s
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) => _verifierStatut());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifierStatut() async {
    final provider = context.read<CommercantProvider>();
    await provider.chargerProfil();
    if (!mounted) return;

    if (provider.estActif) {
      // Compte validé → accès au dashboard
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _modifierInfos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetupBoutiqueScreen()),
    );
  }

  void _confirmerDeconnexion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter', style: TextStyle(color: AppColors.white)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = context.read<AuthService>();
              await auth.deconnecter();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      appBar: AppBar(
        backgroundColor: AppColors.noirCarbone,
        automaticallyImplyLeading: false,
        title: const Text('GoLivreur Pro', style: TextStyle(color: AppColors.blancPur)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: _confirmerDeconnexion,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation horloge
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.warning, width: 2),
                  boxShadow: [BoxShadow(color: AppColors.warning.withValues(alpha: 0.2), blurRadius: 30)],
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 56),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Votre boutique est en cours\nde validation',
              style: TextStyle(color: AppColors.blancPur, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Délai estimé : 24 à 48 heures',
              style: TextStyle(color: AppColors.warning, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notre équipe vérifie vos informations et documents. Vous recevrez une notification dès que votre compte sera activé.',
              style: TextStyle(color: AppColors.grisMetallique, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Étapes de validation
            _buildEtape(Icons.check_circle, 'Compte créé', true),
            _buildEtape(Icons.check_circle, 'Boutique configurée', true),
            _buildEtape(Icons.check_circle, 'Documents soumis', true),
            _buildEtape(Icons.radio_button_unchecked, 'Vérification admin', false),
            _buildEtape(Icons.radio_button_unchecked, 'Compte activé', false),
            const SizedBox(height: 40),

            // Boutons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _modifierInfos,
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                label: const Text('Modifier mes informations',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_outlined, color: AppColors.grey),
                label: const Text('Contacter le support',
                    style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _verifierStatut,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh, color: AppColors.grisMetallique, size: 16),
                  const SizedBox(width: 6),
                  const Text('Vérifier l\'état de ma demande',
                      style: TextStyle(color: AppColors.grisMetallique, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtape(IconData icon, String label, bool fait) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: fait ? AppColors.success : AppColors.border, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            color: fait ? AppColors.blancPur : AppColors.grisMetallique,
            fontWeight: fait ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          )),
        ],
      ),
    );
  }
}