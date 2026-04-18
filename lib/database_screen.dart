import 'package:flutter/material.dart';
import 'db/database_helper.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<Map<String, dynamic>> brebis = [];
  List<Map<String, dynamic>> agneaux = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;

    final b = await db.getAllBrebis();
    final a = await db.getAllAgneaux();

    setState(() {
      brebis = b;
      agneaux = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Base de données"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🐑 Brebis mères",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...brebis.map((b) => Card(
                  child: ListTile(
                    title: Text("ZIP: ${b['zip']}"),
                    subtitle:
                        Text("Boucle: ${b['boucle']}"),
                    trailing: Text("ID: ${b['id']}"),
                  ),
                )),

            const SizedBox(height: 24),

            const Text(
              "🐑 Agneaux",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...agneaux.map((a) => Card(
                  child: ListTile(
                    title: Text(
                        "Année ${a['annee']} - Brebis ${a['brebis_id']}"),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text("ZIP: ${a['zip']}"),
                        Text("Boucle: ${a['boucle']}"),
                        Text("Sexe: ${a['sexe'] ?? '-'}"),
                        Text("Vivant: ${a['vivant'] == 1 ? 'Oui' : 'Non'}"),
                        Text("Commentaire: ${a['commentaire'] ?? ''}"),
                      ],
                    ),
                    trailing: Text("ID: ${a['id']}"),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}