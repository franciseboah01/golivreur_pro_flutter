import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'attente_validation_screen.dart';

class SetupDocumentsScreen extends StatefulWidget {
  const SetupDocumentsScreen({super.key});

  @override
  State<SetupDocumentsScreen> createState() => _SetupDocumentsScreenState();
}

class _SetupDocumentsScreenState extends State<SetupDocumentsScreen> {
  bool _photoAdded = false;
  bool _registreAdded = false;
  bool _cniAdded = false;
  bool _loading = false;

  Future<void> _continuer() async {
    if (!_photoAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La photo de la boutique est obligatoire'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AttenteValidationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.noirProfond,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Documents requis',
                        style: TextStyle(color: AppColors.blancPur, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Ces documents permettent de vérifier votre identité',
                        style: TextStyle(color: AppColors.grisMetallique, fontSize: 13)),
                    const SizedBox(height: 24),

                    _buildDocumentCard(
                      icon: Icons.store,
                      title: 'Photo de la boutique',
                      subtitle: 'Photo claire de votre devanture',
                      obligatoire: true,
                      ajoute: _photoAdded,
                      onTap: () => setState(() => _photoAdded = !_photoAdded),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentCard(
                      icon: Icons.business,
                      title: 'Registre de commerce',
                      subtitle: 'Optionnel mais recommandé',
                      obligatoire: false,
                      ajoute: _registreAdded,
                      onTap: () => setState(() => _registreAdded = !_registreAdded),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentCard(
                      icon: Icons.badge,
                      title: 'Pièce d\'identité',
                      subtitle: 'CNI, passeport ou permis',
                      obligatoire: false,
                      ajoute: _cniAdded,
                      onTap: () => setState(() => _cniAdded = !_cniAdded),
                    ),
                    const SizedBox(height: 24),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Vos documents sont confidentiels et ne seront utilisés que pour la vérification de votre compte.',
                              style: TextStyle(color: AppColors.blancPur.withValues(alpha: 0.8), fontSize: 13),
                            ),
                          ),
                        ],
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
                            : const Icon(Icons.send),
                        label: Text(
                          _loading ? 'Envoi...' : 'Soumettre ma demande',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
              const Text('Étape 3 sur 3', style: TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
              const Spacer(),
              Text('Documents', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1.0,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool obligatoire,
    required bool ajoute,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ajoute ? AppColors.primary.withValues(alpha: 0.08) : AppColors.noirCarbone,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ajoute ? AppColors.primary : AppColors.border,
            width: ajoute ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: ajoute ? AppColors.primary.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ajoute ? AppColors.primary : AppColors.grey, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(
                        color: ajoute ? AppColors.blancPur : AppColors.blancPur,
                        fontWeight: FontWeight.bold,
                      )),
                      if (obligatoire) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Obligatoire',
                              style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.grisMetallique, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              ajoute ? Icons.check_circle : Icons.add_circle_outline,
              color: ajoute ? AppColors.success : AppColors.grey,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}