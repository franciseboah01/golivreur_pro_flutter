import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/skeleton_widgets.dart';

class CommandesCommercantScreen extends StatefulWidget {
  const CommandesCommercantScreen({super.key});

  @override
  State<CommandesCommercantScreen> createState() => _CommandesCommercantScreenState();
}

class _CommandesCommercantScreenState extends State<CommandesCommercantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _commandes = [];
  bool _loading = true;
  bool _erreur = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load(silencieux: true));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silencieux = false}) async {
    if (!silencieux) setState(() { _loading = true; _erreur = false; });
    try {
      final res = await ApiService.get('/commandes-recues');
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() { _commandes = jsonDecode(res.body); _loading = false; });
      } else {
        if (!silencieux) setState(() { _loading = false; _erreur = true; });
      }
    } catch (_) {
      if (!mounted) return;
      if (!silencieux) setState(() { _loading = false; _erreur = true; });
    }
  }

  Future<void> _changerStatut(int id, String statut) async {
    try {
      final res = await ApiService.put('/commandes/$id/statut', {'statut': statut});
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Commande ${_statutLabel(statut).toLowerCase()}'),
          backgroundColor: AppColors.success,
        ));
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau'), backgroundColor: AppColors.error),
      );
    }
  }

  void _confirmerAction(int id, String statut, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer', style: TextStyle(color: AppColors.white)),
        content: Text(message, style: const TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _changerStatut(id, statut); },
            style: ElevatedButton.styleFrom(
              backgroundColor: statut == 'annulee' ? AppColors.error : AppColors.primary,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'en_attente': return AppColors.jauneNeon;
      case 'acceptee': case 'en_livraison': return AppColors.primary;
      case 'livree': return AppColors.success;
      case 'annulee': return AppColors.error;
      default: return AppColors.grey;
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'en_attente': return 'NOUVELLE';
      case 'acceptee': return 'ACCEPTÉE';
      case 'en_livraison': return 'EN ROUTE';
      case 'livree': return 'LIVRÉE';
      case 'annulee': return 'ANNULÉE';
      default: return s.toUpperCase();
    }
  }

  List<dynamic> _filtrer(String filtre) {
    if (filtre == 'acceptee') {
      return _commandes.where((c) => c['statut'] == 'acceptee' || c['statut'] == 'en_livraison').toList();
    }
    return _commandes.where((c) => c['statut'] == filtre).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      appBar: AppBar(
        backgroundColor: AppColors.noirCarbone,
        title: const Text('Commandes', style: TextStyle(color: AppColors.blancPur)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grisMetallique,
          tabs: [
            Tab(text: _loading ? 'Nouvelles' : 'Nouvelles (${_filtrer("en_attente").length})'),
            Tab(text: _loading ? 'En cours' : 'En cours (${_filtrer("acceptee").length})'),
            Tab(text: _loading ? 'Livrées' : 'Livrées (${_filtrer("livree").length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _loading
            ? ListView(padding: const EdgeInsets.all(12),
                children: List.generate(4, (_) => const SkeletonCommandeCard()))
            : _erreur
                ? _buildErreur()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListe('en_attente'),
                      _buildListe('acceptee'),
                      _buildListe('livree'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErreur() {
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

  Widget _buildListe(String filtre) {
    final liste = _filtrer(filtre);
    if (liste.isEmpty) {
      return Center(
        child: Text(
          filtre == 'en_attente' ? 'Aucune nouvelle commande'
              : filtre == 'acceptee' ? 'Aucune commande en cours'
              : 'Aucune commande livrée',
          style: const TextStyle(color: AppColors.grisMetallique, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: liste.length,
      itemBuilder: (_, i) {
        final c = liste[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.noirCarbone,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statutColor(c['statut']).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Commande #${c['id']}',
                    style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statutColor(c['statut']).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statutLabel(c['statut']),
                      style: TextStyle(color: _statutColor(c['statut']), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 10),
              if (c['client'] != null)
                Row(children: [
                  const Icon(Icons.person, color: AppColors.grisMetallique, size: 14),
                  const SizedBox(width: 4),
                  Text('${c['client']['prenom'] ?? ''} ${c['client']['nom'] ?? ''}'.trim(),
                      style: const TextStyle(color: AppColors.grisMetallique)),
                ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on, color: AppColors.grisMetallique, size: 14),
                const SizedBox(width: 4),
                Expanded(child: Text(c['adresse_livraison'] ?? '',
                    style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12))),
              ]),
              const SizedBox(height: 8),
              if (c['produits'] != null && (c['produits'] as List).isNotEmpty) ...[
                const Divider(color: AppColors.border, height: 16),
                ...(c['produits'] as List).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(children: [
                    const Icon(Icons.circle, color: AppColors.grisMetallique, size: 6),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p['nom'] ?? '',
                        style: const TextStyle(color: AppColors.blancPur, fontSize: 13))),
                    Text('x${p['pivot']?['quantite'] ?? 1}',
                        style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
                  ]),
                )),
                const SizedBox(height: 8),
              ],
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total', style: TextStyle(color: AppColors.grisMetallique)),
                Text('${c['total']} FCFA',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
              ]),
              if (c['statut'] == 'en_attente') ...[
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: ElevatedButton(
                    onPressed: () => _confirmerAction(c['id'], 'acceptee', 'Accepter la commande #${c['id']} ?'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('✅ Accepter', style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton(
                    onPressed: () => _confirmerAction(c['id'], 'annulee', 'Refuser la commande #${c['id']} ?'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('❌ Refuser'),
                  )),
                ]),
              ],
              if (c['statut'] == 'acceptee') ...[
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => _confirmerAction(c['id'], 'en_livraison', 'Marquer comme prête pour livraison ?'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('🚀 Prête pour livraison', style: TextStyle(fontWeight: FontWeight.bold)),
                )),
              ],
            ],
          ),
        );
      },
    );
  }
}