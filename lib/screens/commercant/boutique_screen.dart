import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../providers/commercant_provider.dart';
import '../../utils/app_colors.dart';

class BoutiqueScreen extends StatefulWidget {
  const BoutiqueScreen({super.key});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _horairesCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _adresseCtrl.dispose();
    _telCtrl.dispose();
    _catCtrl.dispose();
    _horairesCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerProfil() async {
    setState(() => _loading = true);
    try {
      final provider = context.read<CommercantProvider>();
      await provider.chargerProfil();
      if (!mounted) return;

      if (provider.aUnProfil) {
        final p = provider.profil!;
        _nomCtrl.text = p['nom_boutique'] ?? '';
        _descCtrl.text = p['description'] ?? '';
        _adresseCtrl.text = p['adresse'] ?? '';
        _telCtrl.text = p['telephone_boutique'] ?? '';
        _catCtrl.text = p['categorie'] ?? '';
        _horairesCtrl.text = p['horaires'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String? _validateRequired(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label est requis';
    if (v.trim().length < 2) return 'Minimum 2 caractères';
    return null;
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<CommercantProvider>();
    final ok = await provider.mettreAJourProfil({
      'nom_boutique': _nomCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'adresse': _adresseCtrl.text.trim(),
      'telephone_boutique': _telCtrl.text.trim(),
      'categorie': _catCtrl.text.trim(),
      'horaires': _horairesCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Boutique mise à jour !' : 'Erreur lors de la sauvegarde'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.noirProfond,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      appBar: AppBar(
        backgroundColor: AppColors.noirCarbone,
        title: const Text('Ma boutique', style: TextStyle(color: AppColors.blancPur)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _catCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category),
                ),
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
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone boutique',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _horairesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Horaires',
                  prefixIcon: Icon(Icons.schedule),
                  hintText: 'Ex: Lun-Sam 8h-20h',
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _sauvegarder,
                  icon: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: AppColors.blancPur, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(
                    _saving ? 'Sauvegarde...' : 'Enregistrer',
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