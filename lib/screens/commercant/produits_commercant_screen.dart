import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../models/produit.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_transitions.dart';
import '../../widgets/skeleton_widgets.dart';
import 'ajout_produit_screen.dart';

class ProduitsCommercantScreen extends StatefulWidget {
  const ProduitsCommercantScreen({super.key});

  @override
  State<ProduitsCommercantScreen> createState() => _ProduitsCommercantScreenState();
}

class _ProduitsCommercantScreenState extends State<ProduitsCommercantScreen> {
  List<Produit> _produits = [];
  bool _loading = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erreur = false; });
    try {
      final res = await ApiService.get('/produits');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _produits = data.map((j) => Produit.fromJson(j)).toList();
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _erreur = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _erreur = true; });
    }
  }

  Future<void> _toggleDisponible(Produit p) async {
    try {
      await ApiService.put('/produits/${p.id}', {'disponible': !p.disponible});
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau'), backgroundColor: AppColors.error),
      );
    }
  }

  void _confirmerSuppression(Produit p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le produit', style: TextStyle(color: AppColors.white)),
        content: Text('Voulez-vous supprimer "${p.nom}" ?', style: const TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.delete('/produits/${p.id}');
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produit supprimé'), backgroundColor: AppColors.success),
              );
              _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
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
        title: Text(
          'Mon catalogue (${_loading ? "…" : _produits.length})',
          style: const TextStyle(color: AppColors.blancPur),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context, AppTransitions.slideUp(const AjoutProduitScreen()),
              ).then((r) { if (r == true) _load(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: const Text('+ Ajouter',
                    style: TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold)),
              ),
            ),
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
        padding: const EdgeInsets.all(12),
        children: List.generate(5, (_) => const SkeletonListTile()),
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

    if (_produits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.grisMetallique, size: 64),
            const SizedBox(height: 16),
            const Text('Aucun produit',
                style: TextStyle(color: AppColors.blancPur, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ajoutez votre premier produit',
                style: TextStyle(color: AppColors.grisMetallique)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context, AppTransitions.slideUp(const AjoutProduitScreen()),
              ).then((r) { if (r == true) _load(); }),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un produit'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _produits.length,
      itemBuilder: (_, i) {
        final p = _produits[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.noirCarbone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: p.disponible ? AppColors.border : AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: p.disponible
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fastfood,
                    color: p.disponible ? AppColors.primary : AppColors.error.withValues(alpha: 0.5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nom, style: TextStyle(
                      color: p.disponible ? AppColors.blancPur : AppColors.grisMetallique,
                      fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 2),
                    Text('${p.prix.toStringAsFixed(0)} FCFA', style: TextStyle(
                      color: p.disponible ? AppColors.primary : AppColors.grisMetallique,
                      fontWeight: FontWeight.bold,
                    )),
                    if (p.categorie != null && p.categorie!.isNotEmpty)
                      Text(p.categorie!,
                          style: const TextStyle(color: AppColors.grisMetallique, fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleDisponible(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.disponible
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.disponible ? 'Dispo' : 'Indispo',
                    style: TextStyle(
                      color: p.disponible ? AppColors.success : AppColors.error,
                      fontSize: 11, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  AppTransitions.slideRight(AjoutProduitScreen(produit: {
                    'id': p.id, 'nom': p.nom, 'prix': p.prix,
                    'description': p.description, 'categorie': p.categorie,
                    'disponible': p.disponible,
                  })),
                ).then((r) { if (r == true) _load(); }),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () => _confirmerSuppression(p),
              ),
            ],
          ),
        );
      },
    );
  }
}