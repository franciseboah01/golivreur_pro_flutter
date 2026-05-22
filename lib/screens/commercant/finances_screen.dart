import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/skeleton_widgets.dart';

class FinancesCommercantScreen extends StatefulWidget {
  const FinancesCommercantScreen({super.key});

  @override
  State<FinancesCommercantScreen> createState() => _FinancesCommercantScreenState();
}

class _FinancesCommercantScreenState extends State<FinancesCommercantScreen> {
  List<dynamic> _commandes = [];
  bool _loading = true;
  bool _erreur = false;

  // Calculés depuis les commandes
  double _revenuTotal = 0;
  double _revenuMois = 0;
  int _nbLivrees = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erreur = false; });
    try {
      final res = await ApiService.get('/commandes-recues');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _calculerStats(data);
        setState(() { _commandes = data; _loading = false; });
      } else {
        setState(() { _loading = false; _erreur = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _erreur = true; });
    }
  }

  void _calculerStats(List data) {
    double total = 0;
    double mois = 0;
    int livrees = 0;
    final now = DateTime.now();

    for (final c in data) {
      if (c['statut'] == 'livree') {
        final montant = double.tryParse(c['total'].toString()) ?? 0;
        total += montant;
        livrees++;
        try {
          final date = DateTime.parse(c['created_at']);
          if (date.month == now.month && date.year == now.year) {
            mois += montant;
          }
        } catch (_) {}
      }
    }
    _revenuTotal = total;
    _revenuMois = mois;
    _nbLivrees = livrees;
  }

  List<dynamic> get _commandesLivrees =>
      _commandes.where((c) => c['statut'] == 'livree').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      appBar: AppBar(
        backgroundColor: AppColors.noirCarbone,
        title: const Text('Mes finances', style: TextStyle(color: AppColors.blancPur)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.primary),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 180, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12),
          Container(height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 24),
          ...List.generate(4, (_) => const SkeletonListTile()),
        ],
      );
    }

    if (_erreur) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.grisMetallique, size: 60),
            const SizedBox(height: 16),
            const Text('Erreur de connexion',
                style: TextStyle(color: AppColors.blancPur, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Solde total
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('Revenus totaux', style: TextStyle(color: AppColors.blancPur, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '${_revenuTotal.toStringAsFixed(0)} FCFA',
                style: const TextStyle(color: AppColors.blancPur, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Sur $_nbLivrees commande(s) livrée(s)',
                  style: TextStyle(color: AppColors.blancPur.withValues(alpha: 0.7), fontSize: 12)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.blancPur.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Retrait — Bientôt disponible',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Revenus du mois
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.noirCarbone, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ce mois-ci', style: TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
                  Text('${_revenuMois.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Transactions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dernières transactions',
                style: TextStyle(color: AppColors.blancPur, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${_commandesLivrees.length} au total',
                style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),

        if (_commandesLivrees.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucune transaction pour le moment',
                  style: TextStyle(color: AppColors.grisMetallique)),
            ),
          )
        else
          ..._commandesLivrees.take(20).map((c) => _buildTransaction(c)),
      ],
    );
  }

  Widget _buildTransaction(Map<String, dynamic> c) {
    final montant = double.tryParse(c['total'].toString()) ?? 0;
    String dateLabel = '';
    try {
      final dt = DateTime.parse(c['created_at']).toLocal();
      dateLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.noirCarbone, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande #${c['id']}',
                    style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold)),
                Text(dateLabel, style: const TextStyle(color: AppColors.grisMetallique, fontSize: 11)),
              ],
            ),
          ),
          Text('+${montant.toStringAsFixed(0)} FCFA',
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('À propos des finances', style: TextStyle(color: AppColors.white)),
        content: const Text(
          'Les revenus affichés correspondent aux commandes livrées. La fonctionnalité de retrait sera disponible prochainement.',
          style: TextStyle(color: AppColors.grey),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}