import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../db/database_helper.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController controller = TextEditingController();
  final AudioPlayer player = AudioPlayer();

  String message = "";

  Future<void> jouerAlerte() async {
    await player.play(AssetSource('beep.mp3'));
  }

  Future<void> verifier(String zip) async {
    final db = DatabaseHelper.instance;

    final brebis = await db.getBrebisByZip(zip);

    if (brebis == null) {
      setState(() => message = "Brebis inconnue");
      return;
    }

    final ok = await db.tousAgneauxSortis(brebis['id']);

    if (ok) {
      await jouerAlerte();

      setState(() {
        message = "✔ Tous les agneaux sont sortis";
      });
    } else {
      setState(() {
        message = "⛔ Il reste des agneaux";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Scan ZIP brebis"),
          TextField(
            controller: controller,
            onChanged: (v) {
              if (v.length > 5) {
                verifier(v);
              }
            },
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}