import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/skeleton_widgets.dart';

class StatistiquesCommercantScreen extends StatefulWidget {
  const StatistiquesCommercantScreen({super.key});

  @override
  State<StatistiquesCommercantScreen> createState() => _StatistiquesCommercantScreenState();
}

class _StatistiquesCommercantScreenState extends State<StatistiquesCommercantScreen> {
  List<dynamic> _commandes = [];
  List<dynamic> _produits = [];
  bool _loading = true;
  bool _erreur = false;

  // Stats calculées
  int _totalCommandes = 0;
  int _commandesLivrees = 0;
  int _commandesAnnulees = 0;
  double _revenuTotal = 0;
  double _revenuMois = 0;
  int _nouveauxClientsMois = 0;
  Map<String, int> _topProduits = {};
  Map<String, double> _revenusParJour = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erreur = false; });
    try {
      final results = await Future.wait([
        ApiService.get('/commandes-recues'),
        ApiService.get('/produits'),
      ]);
      if (!mounted) return;

      if (results[0].statusCode == 200) {
        final List cmdData = jsonDecode(results[0].body);
        _calculerStats(cmdData);
        setState(() => _commandes = cmdData);
      }
      if (results[1].statusCode == 200) {
        setState(() => _produits = jsonDecode(results[1].body));
      }
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _erreur = true; });
    }
  }

  void _calculerStats(List data) {
    final now = DateTime.now();
    double total = 0;
    double mois = 0;
    int livrees = 0;
    int annulees = 0;
    Set<int> clientsMois = {};
    Map<String, int> produits = {};
    Map<String, double> parJour = {};

    for (final c in data) {
      _totalCommandes = data.length;
      final montant = double.tryParse(c['total'].toString()) ?? 0;

      if (c['statut'] == 'livree') {
        livrees++;
        total += montant;
        try {
          final date = DateTime.parse(c['created_at']);
          if (date.month == now.month && date.year == now.year) {
            mois += montant;
            if (c['client_id'] != null) clientsMois.add(c['client_id']);
            final key = '${date.day}/${date.month}';
            parJour[key] = (parJour[key] ?? 0) + montant;
          }
        } catch (_) {}
      }
      if (c['statut'] == 'annulee') annulees++;

      // Top produits
      if (c['produits'] != null) {
        for (final p in (c['produits'] as List)) {
          final nom = p['nom'] ?? 'Inconnu';
          final qte = (p['pivot']?['quantite'] as num?)?.toInt() ?? 1;
          produits[nom] = (produits[nom] ?? 0) + qte;
        }
      }
    }

    _commandesLivrees = livrees;
    _commandesAnnulees = annulees;
    _revenuTotal = total;
    _revenuMois = mois;
    _nouveauxClientsMois = clientsMois.length;
    _revenusParJour = parJour;

    // Trier top produits
    final sorted = produits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topProduits = Map.fromEntries(sorted.take(5));
  }

  double get _tauxLivraison => _totalCommandes == 0
      ? 0
      : (_commandesLivrees / _totalCommandes) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      appBar: AppBar(
        backgroundColor: AppColors.noirCarbone,
        title: const Text('Statistiques', style: TextStyle(color: AppColors.blancPur)),
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
          Row(children: [
            Expanded(child: Container(height: 90, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 90, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Container(height: 90, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 90, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
          ]),
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
        // KPIs
        Row(children: [
          _buildKpi('💰', 'Revenus totaux', '${_revenuTotal.toStringAsFixed(0)} F',
              sub: 'Ce mois : ${_revenuMois.toStringAsFixed(0)} F', color: AppColors.success),
          const SizedBox(width: 12),
          _buildKpi('🛒', 'Commandes', '$_totalCommandes',
              sub: '$_commandesLivrees livrées', color: AppColors.primary),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _buildKpi('✅', 'Taux livraison', '${_tauxLivraison.toStringAsFixed(0)}%',
              sub: '$_commandesAnnulees annulée(s)', color: AppColors.warning),
          const SizedBox(width: 12),
          _buildKpi('👥', 'Clients/mois', '$_nouveauxClientsMois',
              sub: 'Ce mois', color: AppColors.primaryLight),
        ]),
        const SizedBox(height: 24),

        // Produits disponibles vs indisponibles
        if (_produits.isNotEmpty) ...[
          _sectionTitle('Catalogue'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.noirCarbone, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                  '${_produits.where((p) => p['disponible'] == true || p['disponible'] == 1).length}',
                  'Disponibles',
                  AppColors.success,
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildMiniStat(
                  '${_produits.where((p) => p['disponible'] != true && p['disponible'] != 1).length}',
                  'Indisponibles',
                  AppColors.error,
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildMiniStat('${_produits.length}', 'Total', AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Top produits vendus
        if (_topProduits.isNotEmpty) ...[
          _sectionTitle('Produits les plus vendus'),
          const SizedBox(height: 12),
          ..._topProduits.entries.toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final nom = entry.value.key;
            final ventes = entry.value.value;
            return _buildTopProduit(rank, nom, ventes);
          }),
          const SizedBox(height: 24),
        ],

        // Revenus par jour ce mois
        if (_revenusParJour.isNotEmpty) ...[
          _sectionTitle('Activité ce mois'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.noirCarbone, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: _revenusParJour.entries.take(7).map((e) {
                final maxVal = _revenusParJour.values.reduce((a, b) => a > b ? a : b);
                final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 50, child: Text(e.key,
                          style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio.toDouble(),
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text('${e.value.toStringAsFixed(0)} F',
                            style: const TextStyle(color: AppColors.blancPur, fontSize: 11),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (_totalCommandes == 0)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucune donnée disponible pour le moment',
                  style: TextStyle(color: AppColors.grisMetallique)),
            ),
          ),
      ],
    );
  }

  Widget _buildKpi(String emoji, String label, String value, {String? sub, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.noirCarbone, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
            if (sub != null) Text(sub, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.grisMetallique, fontSize: 11)),
      ],
    );
  }

  Widget _buildTopProduit(int rank, String nom, int ventes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.noirCarbone, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.warning.withValues(alpha: 0.15)
                  : rank == 2 ? AppColors.grisMetallique.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$rank', style: TextStyle(
                color: rank == 1 ? AppColors.warning : rank == 2 ? AppColors.grisMetallique : AppColors.primary,
                fontWeight: FontWeight.bold, fontSize: 13,
              )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(nom, style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold))),
          Text('$ventes vente(s)', style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}