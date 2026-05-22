import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/commercant_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_transitions.dart';
import 'boutique_screen.dart';

class ParametresCommercantScreen extends StatefulWidget {
  const ParametresCommercantScreen({super.key});

  @override
  State<ParametresCommercantScreen> createState() => _ParametresCommercantScreenState();
}

class _ParametresCommercantScreenState extends State<ParametresCommercantScreen> {
  // Toggles notifications (état local — à connecter à l'API si disponible)
  bool _notifCommandes = true;
  bool _notifPaiements = true;
  bool _notifAvis = false;
  bool _notifRupture = true;
  bool _notifNewsletter = false;

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
              context.read<CommercantProvider>().reset();
              await context.read<AuthService>().deconnecter();
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

  void _comingSoon(String titre) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$titre — Bientôt disponible'),
      backgroundColor: AppColors.noirCarbone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      appBar: AppBar(
        backgroundColor: AppColors.noirCarbone,
        title: const Text('Paramètres', style: TextStyle(color: AppColors.blancPur)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ma boutique
          _sectionTitle('Ma boutique'),
          _menuItem(Icons.store, 'Informations de la boutique', () {
            Navigator.push(context, AppTransitions.slideRight(const BoutiqueScreen()))
                .then((_) => context.read<CommercantProvider>().chargerProfil());
          }),
          _menuItem(Icons.photo, 'Photos (logo et couverture)', () => _comingSoon('Photos')),
          _menuItem(Icons.schedule, 'Horaires d\'ouverture', () => _comingSoon('Horaires')),
          _menuItem(Icons.location_on, 'Zone de livraison', () => _comingSoon('Zone de livraison')),
          _menuItem(Icons.local_shipping, 'Frais de livraison', () => _comingSoon('Frais de livraison')),
          const SizedBox(height: 16),

          // Mon compte
          _sectionTitle('Mon compte'),
          _menuItem(Icons.person, 'Informations personnelles', () => _comingSoon('Informations personnelles')),
          _menuItem(Icons.lock, 'Sécurité et mot de passe', () => _comingSoon('Sécurité')),
          _menuItem(Icons.phone, 'Numéro de téléphone', () => _comingSoon('Téléphone')),
          const SizedBox(height: 16),

          // Paiements
          _sectionTitle('Paiements'),
          _menuItem(Icons.payment, 'Moyens de retrait', () => _comingSoon('Moyens de retrait')),
          _menuItem(Icons.receipt_long, 'Historique des factures', () => _comingSoon('Factures')),
          const SizedBox(height: 16),

          // Notifications
          _sectionTitle('Notifications'),
          _toggle('Nouvelles commandes', _notifCommandes,
              (v) => setState(() => _notifCommandes = v)),
          _toggle('Paiements reçus', _notifPaiements,
              (v) => setState(() => _notifPaiements = v)),
          _toggle('Nouveaux avis', _notifAvis,
              (v) => setState(() => _notifAvis = v)),
          _toggle('Rupture de stock', _notifRupture,
              (v) => setState(() => _notifRupture = v)),
          _toggle('Newsletter', _notifNewsletter,
              (v) => setState(() => _notifNewsletter = v)),
          const SizedBox(height: 16),

          // Support
          _sectionTitle('Support'),
          _menuItem(Icons.help, 'Centre d\'aide', () => _comingSoon('Centre d\'aide')),
          _menuItem(Icons.chat, 'Contacter le support', () => _comingSoon('Support')),
          _menuItem(Icons.description, 'Conditions commerçants', () => _comingSoon('CGU')),
          _menuItem(Icons.privacy_tip, 'Politique de confidentialité', () => _comingSoon('Confidentialité')),
          const SizedBox(height: 24),

          // Déconnexion
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _confirmerDeconnexion,
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Se déconnecter',
                  style: TextStyle(color: AppColors.error, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 3, height: 16,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      color: AppColors.noirCarbone,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(color: AppColors.blancPur)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.grisMetallique, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Card(
      color: AppColors.noirCarbone,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: AppColors.blancPur)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}