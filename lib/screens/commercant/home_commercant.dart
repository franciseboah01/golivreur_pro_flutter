import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../providers/commercant_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_transitions.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/offline_banner.dart';
import 'commandes_commercant_screen.dart';
import 'produits_commercant_screen.dart';
import 'boutique_screen.dart';
import 'finances_screen.dart';

class HomeCommercant extends StatefulWidget {
  const HomeCommercant({super.key});

  @override
  State<HomeCommercant> createState() => _HomeCommercantState();
}

class _HomeCommercantState extends State<HomeCommercant> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  int _nouvellesCommandes = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
    // Polling nouvelles commandes toutes les 30s
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollCommandes());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _loading = true);
    await Future.wait([
      _chargerStats(),
      _pollCommandes(),
      context.read<CommercantProvider>().chargerProfil(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _chargerStats() async {
    try {
      // Route correcte : GET /commandes-recues
      final res = await ApiService.get('/commandes-recues');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        double totalRevenus = 0;
        int commandesLivrees = 0;
        for (final c in data) {
          if (c['statut'] == 'livree') {
            commandesLivrees++;
            totalRevenus += double.tryParse(c['total'].toString()) ?? 0;
          }
        }
        setState(() {
          _stats = {
            'total_commandes': data.length,
            'commandes_livrees': commandesLivrees,
            'revenus_total': totalRevenus.toStringAsFixed(0),
          };
        });
      }
    } catch (_) {}
  }

  Future<void> _pollCommandes() async {
    try {
      final res = await ApiService.get('/commandes-recues');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final nouvelles = data.where((c) => c['statut'] == 'en_attente').length;
        if (mounted) setState(() => _nouvellesCommandes = nouvelles);
      }
    } catch (_) {}
  }

  Future<void> _toggleOuverture() async {
    final provider = context.read<CommercantProvider>();
    final ok = await provider.toggleOuverture();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.estOuvert ? '🟢 Boutique ouverte' : '🔴 Boutique fermée'),
        backgroundColor: provider.estOuvert ? AppColors.success : AppColors.error,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: AppColors.error),
      );
    }
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
              context.read<CommercantProvider>().reset();
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
    final auth = Provider.of<AuthService>(context);
    final commercant = context.watch<CommercantProvider>();

    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      appBar: AppBar(
        backgroundColor: AppColors.noirCarbone,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${auth.prenom ?? ''} 👋',
                style: const TextStyle(color: AppColors.blancPur, fontSize: 16, fontWeight: FontWeight.bold)),
            if (commercant.nomBoutique.isNotEmpty)
              Text(commercant.nomBoutique,
                  style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
          ],
        ),
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: _confirmerDeconnexion,
          ),
        ],
      ),
      body: OfflineBanner(
        child: RefreshIndicator(
          onRefresh: _chargerDonnees,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: _loading
              ? _buildSkeleton()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Toggle ouvert/fermé
                    _buildToggleBoutique(commercant),
                    const SizedBox(height: 20),

                    // KPIs dynamiques
                    Row(children: [
                      _buildKpi('Commandes', _stats?['total_commandes']?.toString() ?? '0', Icons.shopping_cart),
                      const SizedBox(width: 12),
                      _buildKpi('Revenus', '${_stats?['revenus_total'] ?? '0'} F', Icons.monetization_on),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _buildKpi('Livrées', _stats?['commandes_livrees']?.toString() ?? '0', Icons.check_circle),
                      const SizedBox(width: 12),
                      _buildKpi('Note', '4.8 ⭐', Icons.star),
                    ]),
                    const SizedBox(height: 24),

                    // Menu
                    _buildMenuItem(
                      Icons.receipt_long,
                      'Commandes',
                      'Traiter et suivre',
                      badge: _nouvellesCommandes,
                      onTap: () => Navigator.push(context,
                          AppTransitions.slideRight(const CommandesCommercantScreen()))
                          .then((_) => _chargerDonnees()),
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      Icons.inventory,
                      'Mon catalogue',
                      'Gérer les produits',
                      onTap: () => Navigator.push(context,
                          AppTransitions.slideRight(const ProduitsCommercantScreen())),
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      Icons.store,
                      'Ma boutique',
                      'Configurer ma boutique',
                      onTap: () => Navigator.push(context,
                          AppTransitions.slideRight(const BoutiqueScreen()))
                          .then((_) => commercant.chargerProfil()),
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      Icons.monetization_on,
                      'Finances',
                      'Revenus et retraits',
                      onTap: () => Navigator.push(context,
                          AppTransitions.slideRight(const FinancesCommercantScreen())),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildToggleBoutique(CommercantProvider commercant) {
    return GestureDetector(
      onTap: _toggleOuverture,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: commercant.estOuvert
              ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
              : null,
          color: commercant.estOuvert ? null : AppColors.noirCarbone,
          borderRadius: BorderRadius.circular(20),
          border: commercant.estOuvert ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commercant.estOuvert ? '🟢 Boutique Ouverte' : '🔴 Boutique Fermée',
                  style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  commercant.estOuvert ? 'Vous recevez des commandes' : 'Vous ne recevez aucune commande',
                  style: TextStyle(
                    color: commercant.estOuvert
                        ? AppColors.blancPur.withValues(alpha: 0.7)
                        : AppColors.grisMetallique,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Switch(
              value: commercant.estOuvert,
              onChanged: (_) => _toggleOuverture(),
              activeColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpi(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.noirCarbone,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {int badge = 0, required VoidCallback onTap}) {
    return Card(
      color: AppColors.noirCarbone,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            if (badge > 0)
              Positioned(
                right: -6, top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Text('$badge', style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        title: Text(title, style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grisMetallique)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(height: 100, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Container(height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Container(height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
        ]),
      ],
    );
  }
}