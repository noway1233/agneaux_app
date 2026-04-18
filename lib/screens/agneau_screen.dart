import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class AgneauScreen extends StatefulWidget {
  const AgneauScreen({super.key});

  @override
  State<AgneauScreen> createState() => _AgneauScreenState();
}

class _AgneauScreenState extends State<AgneauScreen> {

  final TextEditingController zipController = TextEditingController();
  final TextEditingController poidsController = TextEditingController();

  String boucleAgneau = '';
  String boucleMere = '';
  String acheteur = "ND";

  Map<String, dynamic>? agneau;
  List<Map<String, dynamic>> fratrie = [];

  Future<void> rechercher(String zip) async {

    if (zip.length < 6) return;

    final db = DatabaseHelper.instance;

    final result = await db.getAgneauByZip(zip);

    if (result == null) {
      setState(() {
        agneau = null;
        boucleAgneau = '';
        boucleMere = '';
        fratrie = [];
      });
      return;
    }

    final brebis = await db.getBrebisById(result['brebis_id']);
    final autres = await db.getAgneauxByBrebis(result['brebis_id']);

    setState(() {

      agneau = result;

      boucleAgneau = result['boucle'] ?? '';

      boucleMere = brebis?['boucle'] ?? '';

      fratrie = autres.where((a) => a['id'] != result['id']).toList();

      if (result['poids_vente'] != null) {
        poidsController.text = result['poids_vente'].toString();
      } else {
        poidsController.clear();
      }

      acheteur = result['acheteur'] ?? "ND";

    });

  }

  Future<void> enregistrer() async {

    if (agneau == null) return;

    final texte = poidsController.text.replaceAll(",", ".").trim();
    final poids = double.tryParse(texte);

    if (poids == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Poids invalide")),
      );
      return;
    }

    final db = DatabaseHelper.instance;

    await db.updateAgneau(
      agneau!['id'],
      {
        "poids_vente": poids,
        "acheteur": acheteur,
        "date_vente": DateTime.now().toIso8601String()
      },
    );

    await rechercher(zipController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vente enregistrée")),
    );
  }

  Widget buildFratrie() {

    return ExpansionTile(

      initiallyExpanded: true,

      title: const Text(
        "Famille",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),

      children: [

        ListTile(
          title: Text("Boucle mère : $boucleMere"),
        ),

        const Divider(),

        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Agneaux de la même mère",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        ...fratrie.map((a) {

          bool vivant = a['vivant'] == 1;
          bool vendu = a['date_vente'] != null;

          return ListTile(

            title: Text("Boucle ${a['boucle']}"),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                Icon(
                  vivant ? Icons.favorite : Icons.close,
                  color: vivant ? Colors.green : Colors.red,
                ),

                const SizedBox(width: 8),

                Icon(
                  vendu ? Icons.sell : Icons.remove,
                  color: vendu ? Colors.blue : Colors.grey,
                ),

              ],
            ),

          );

        }).toList()

      ],

    );

  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(
            "ZIP agneau",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          TextField(
            controller: zipController,
            keyboardType: TextInputType.number,

            onChanged: (v) {
              rechercher(v);
            },

          ),

          const SizedBox(height: 20),

          if (boucleAgneau.isNotEmpty)
            Text(
              "Boucle agneau : $boucleAgneau",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

          const SizedBox(height: 20),

          if (agneau != null) buildFratrie(),

          const SizedBox(height: 30),

          if (agneau != null) ...[

            const Text(
              "Poids de vente",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: poidsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Acheteur",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            DropdownButtonFormField<String>(
              value: acheteur,
              items: ["Marché", "Javy", "Particulier", "ND"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  acheteur = v!;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: enregistrer,
                child: const Text("Enregistrer"),
              ),
            ),

          ]

        ],

      ),

    );

  }
}