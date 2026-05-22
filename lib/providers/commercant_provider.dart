import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../services/api_service.dart';

class CommercantProvider extends ChangeNotifier {
  Map<String, dynamic>? _profil;
  bool _loading = false;
  bool _erreur = false;

  Map<String, dynamic>? get profil => _profil;
  bool get loading => _loading;
  bool get erreur => _erreur;

  // Getters pratiques
  String get nomBoutique => _profil?['nom_boutique'] ?? '';
  String get statut => _profil?['statut'] ?? 'en_attente';
  bool get estActif => statut == 'actif';
  bool get estEnAttente => statut == 'en_attente';
  bool get estOuvert => _profil?['ouvert'] == true || _profil?['ouvert'] == 1;
  bool get aUnProfil => _profil != null;
  int? get commercantId => _profil?['id'];
  String? get categorie => _profil?['categorie'];
  String? get adresse => _profil?['adresse'];
  String? get description => _profil?['description'];
  String? get horaires => _profil?['horaires'];
  String? get telephoneBoutique => _profil?['telephone_boutique'];

  /// Charger le profil depuis GET /commercant/profil
  Future<void> chargerProfil() async {
    _loading = true;
    _erreur = false;
    notifyListeners();

    try {
      final res = await ApiService.get('/commercant/profil');
      if (res.statusCode == 200) {
        _profil = jsonDecode(res.body);
        _erreur = false;
      } else if (res.statusCode == 404) {
        // Pas encore de profil boutique créé
        _profil = null;
      } else {
        _erreur = true;
      }
    } catch (_) {
      _erreur = true;
    }

    _loading = false;
    notifyListeners();
  }

  /// Mettre à jour le profil via POST /commercant/profil
  Future<bool> mettreAJourProfil(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.post('/commercant/profil', data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body);
        _profil = body['commercant'] ?? body;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Toggle ouvert/fermé
  Future<bool> toggleOuverture() async {
    final nouvelEtat = !estOuvert;
    try {
      final res = await ApiService.post('/commercant/profil', {'ouvert': nouvelEtat});
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (_profil != null) {
          _profil!['ouvert'] = nouvelEtat;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Réinitialiser (déconnexion)
  void reset() {
    _profil = null;
    _loading = false;
    _erreur = false;
    notifyListeners();
  }
}