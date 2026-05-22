import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/notifications');
      if (res.statusCode == 200) {
        setState(() {
          _notifs = jsonDecode(res.body);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _marquerLue(int id) async {
    await ApiService.put('/notifications/$id/lire', {});
    _load();
  }

  Future<void> _toutMarquerLu() async {
    await ApiService.put('/notifications/tout-lire', {});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: _toutMarquerLu,
            child: const Text('Tout lire', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifs.isEmpty
              ? const Center(child: Text('Aucune notification'))
              : ListView.builder(
                  itemCount: _notifs.length,
                  itemBuilder: (_, i) {
                    final n = _notifs[i];
                    return ListTile(
                      leading: Icon(
                        n['type'] == 'commande' ? Icons.receipt : n['type'] == 'livraison' ? Icons.local_shipping : Icons.info,
                        color: n['lu'] == 1 || n['lu'] == true ? Colors.grey : Colors.orange,
                      ),
                      title: Text(n['titre'], style: TextStyle(fontWeight: n['lu'] == 1 ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(n['message']),
                      onTap: () => _marquerLue(n['id']),
                    );
                  },
                ),
    );
  }
}