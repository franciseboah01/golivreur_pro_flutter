import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/commercant_provider.dart';
import '../../utils/app_colors.dart';
import 'setup_documents_screen.dart';

class SetupBoutiqueScreen extends StatefulWidget {
  const SetupBoutiqueScreen({super.key});

  @override
  State<SetupBoutiqueScreen> createState() => _SetupBoutiqueScreenState();
}

class _SetupBoutiqueScreenState extends State<SetupBoutiqueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _horairesCtrl = TextEditingController();
  String? _categorie;
  bool _loading = false;

  final List<String> _categories = [
    'Alimentation', 'Pharmacie', 'Mode', 'Électronique',
    'Beauté', 'Boulangerie', 'Restaurant', 'Épicerie', 'Autre',
  ];

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _adresseCtrl.dispose();
    _telCtrl.dispose();
    _horairesCtrl.dispose();
    super.dispose();
  }

  String? _validateRequired(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label est requis';
    if (v.trim().length < 2) return 'Minimum 2 caractères';
    return null;
  }

  Future<void> _continuer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une catégorie'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _loading = true);
    final provider = context.read<CommercantProvider>();
    final ok = await provider.mettreAJourProfil({
      'nom_boutique': _nomCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'adresse': _adresseCtrl.text.trim(),
      'telephone_boutique': _telCtrl.text.trim(),
      'horaires': _horairesCtrl.text.trim(),
      'categorie': _categorie,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupDocumentsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      body: SafeArea(
        child: Column(
          children: [
            // Header progression
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Configurez votre boutique',
                          style: TextStyle(color: AppColors.blancPur, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Ces informations seront visibles par vos clients',
                          style: TextStyle(color: AppColors.grisMetallique, fontSize: 13)),
                      const SizedBox(height: 24),

                      _sectionTitle('Informations principales'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nomCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => _validateRequired(v, 'Le nom de la boutique'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la boutique *',
                          prefixIcon: Icon(Icons.store),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (optionnel)',
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Décrivez votre boutique...',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Catégorie
                      DropdownButtonFormField<String>(
                        value: _categorie,
                        dropdownColor: AppColors.noirCarbone,
                        style: const TextStyle(color: AppColors.blancPur),
                        decoration: const InputDecoration(
                          labelText: 'Catégorie *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(color: AppColors.blancPur)),
                        )).toList(),
                        onChanged: (v) => setState(() => _categorie = v),
                        validator: (v) => v == null ? 'Choisissez une catégorie' : null,
                      ),
                      const SizedBox(height: 24),

                      _sectionTitle('Localisation & Contact'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adresseCtrl,
                        validator: (v) => _validateRequired(v, 'L\'adresse'),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Adresse *',
                          prefixIcon: Icon(Icons.location_on),
                          hintText: 'Ex: Cocody, Abidjan',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone boutique (optionnel)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _horairesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Horaires (optionnel)',
                          prefixIcon: Icon(Icons.schedule),
                          hintText: 'Ex: Lun-Sam 8h-20h',
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _continuer,
                          icon: _loading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(color: AppColors.blancPur, strokeWidth: 2))
                              : const Icon(Icons.arrow_forward),
                          label: Text(_loading ? 'Sauvegarde...' : 'Continuer',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              const Text('Étape 2 sur 3', style: TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
              const Spacer(),
              Text('Configuration boutique', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 2 / 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppColors.blancPur, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}