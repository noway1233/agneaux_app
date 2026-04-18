import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final int currentYear = DateTime.now().year;

  int nbBrebis = 0;
  int nbMale = 0;
  int nbFemelle = 0;
  int nbSimple = 0;
  int nbDouble = 0;
  int nbTriplePlus = 0;
  int nbMort = 0;
  int nbVivant = 0;
  double tauxProlificite = 0;
  double tauxMortalite = 0;
  int totalAgneau = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = DatabaseHelper.instance;

    final brebis =
        await db.countBrebisAyantMisBas(currentYear);
    final male =
        await db.countAgneauxBySexe(currentYear, 'M');
    final femelle =
        await db.countAgneauxBySexe(currentYear, 'F');
    final vivant =
        await db.countAgneauxVivant(currentYear);
    final mort =
        await db.countAgneauxMort(currentYear);
    final total =
        await db.countTotalAgneaux(currentYear);
    final portees =
        await db.countTypePortee(currentYear);

    setState(() {
      nbBrebis = brebis;
      nbMale = male;
      nbFemelle = femelle;
      nbVivant = vivant;
      nbMort = mort;
      totalAgneau = total;
      nbSimple = portees['simple']!;
      nbDouble = portees['double']!;
      nbTriplePlus = portees['triplePlus']!;
      tauxProlificite = nbBrebis > 0 ? totalAgneau / nbBrebis : 0;
      tauxMortalite = totalAgneau > 0 ? nbMort / totalAgneau : 0;
    });
  }

  Widget statTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  String formatPercent(double value) {
    return "${(value * 100).toStringAsFixed(1)} %";
  }
  String formatDouble(double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Statistiques $currentYear",
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          statTile("Nb brebis ayant mis bas", nbBrebis.toString()),
          statTile("Nb agneau mâle", nbMale.toString()),
          statTile("Nb agneau femelle", nbFemelle.toString()),

          const Divider(),

          statTile("Nb portée simple", nbSimple.toString()),
          statTile("Nb portée double", nbDouble.toString()),
          statTile("Nb portée triple ou +", nbTriplePlus.toString()),

          const Divider(),

          statTile("Nb agneau vivant", nbVivant.toString()),
          statTile("Nb agneau mort", nbMort.toString()),

          const Divider(),

          statTile("Taux de prolificité", formatDouble(tauxProlificite)),
          statTile("Taux de mortalité", formatPercent(tauxMortalite)),

          const Divider(),

          statTile("Total agneau", totalAgneau.toString()),
        ],
      ),
    );
  }
}