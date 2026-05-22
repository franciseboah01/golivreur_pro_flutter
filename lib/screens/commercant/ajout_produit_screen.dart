import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class AjoutProduitScreen extends StatefulWidget {
  final Map<String, dynamic>? produit; // null = ajout, non-null = modification
  const AjoutProduitScreen({super.key, this.produit});

  @override
  State<AjoutProduitScreen> createState() => _AjoutProduitScreenState();
}

class _AjoutProduitScreenState extends State<AjoutProduitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  bool _disponible = true;
  bool _loading = false;

  bool get _estModification => widget.produit != null;

  @override
  void initState() {
    super.initState();
    if (_estModification) {
      _nomCtrl.text = widget.produit!['nom'] ?? '';
      _prixCtrl.text = widget.produit!['prix']?.toString() ?? '';
      _descCtrl.text = widget.produit!['description'] ?? '';
      _catCtrl.text = widget.produit!['categorie'] ?? '';
      _disponible = widget.produit!['disponible'] == true || widget.produit!['disponible'] == 1;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prixCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  String? _validateNom(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le nom est requis';
    if (v.trim().length < 2) return 'Minimum 2 caractères';
    return null;
  }

  String? _validatePrix(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le prix est requis';
    final parsed = double.tryParse(v.trim());
    if (parsed == null) return 'Prix invalide';
    if (parsed <= 0) return 'Le prix doit être supérieur à 0';
    return null;
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final body = {
        'nom': _nomCtrl.text.trim(),
        'prix': double.parse(_prixCtrl.text.trim()),
        'description': _descCtrl.text.trim(),
        'categorie': _catCtrl.text.trim(),
        'disponible': _disponible,
      };

      final res = _estModification
          ? await ApiService.put('/produits/${widget.produit!['id']}', body)
          : await ApiService.post('/produits', body);

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_estModification ? 'Produit modifié !' : 'Produit ajouté !'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context, true); // true = refresh parent
      } else {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? 'Erreur lors de la sauvegarde'),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      appBar: AppBar(
        backgroundColor: AppColors.noirCarbone,
        title: Text(
          _estModification ? 'Modifier le produit' : 'Nouveau produit',
          style: const TextStyle(color: AppColors.blancPur),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone photo
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.noirCarbone,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo, color: AppColors.primary, size: 40),
                      SizedBox(height: 8),
                      Text('Ajouter une photo', style: TextStyle(color: AppColors.grisMetallique)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _sectionTitle('Informations produit'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nomCtrl,
                textCapitalization: TextCapitalization.sentences,
                validator: _validateNom,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _prixCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validatePrix,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Prix (FCFA) *',
                  prefixIcon: Icon(Icons.monetization_on),
                  hintText: 'Ex: 1500',
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _catCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Catégorie (optionnel)',
                  prefixIcon: Icon(Icons.category),
                  hintText: 'Ex: Boissons, Plats, ...',
                ),
              ),
              const SizedBox(height: 16),

              // Toggle disponible
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.noirCarbone,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  title: const Text('Produit disponible', style: TextStyle(color: AppColors.blancPur)),
                  subtitle: Text(
                    _disponible ? 'Visible par les clients' : 'Masqué aux clients',
                    style: TextStyle(color: _disponible ? AppColors.success : AppColors.error, fontSize: 12),
                  ),
                  value: _disponible,
                  onChanged: (v) => setState(() => _disponible = v),
                  activeColor: AppColors.success,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _sauvegarder,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: AppColors.blancPur, strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(
                    _loading
                        ? 'Sauvegarde...'
                        : _estModification ? 'Enregistrer les modifications' : 'Publier le produit',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}