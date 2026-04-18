import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/agneau_model.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController zipController = TextEditingController();
  final FocusNode zipFocusNode = FocusNode();
  final TextEditingController commentaireMereController =
    TextEditingController();

  String boucleMere = '';
  String nombreAgneau = '1';

  int? brebisId;
  final int currentYear = DateTime.now().year;

  List<AgneauModel> agneaux = [];

  @override
  void initState() {
    super.initState();
    _generateEmptyAgneaux(1);
  }

  @override
  void dispose() {
    zipController.dispose();
    zipFocusNode.dispose();
    commentaireMereController.dispose();
    for (var a in agneaux) {
      a.dispose();
    }
    super.dispose();
  }

  void _generateEmptyAgneaux(int count) {
    agneaux = List.generate(count, (_) => AgneauModel());
  }

  String calculBoucle(String zip) {
    String transformed = zip
        .replaceAll('à', '0')
        .replaceAll('&', '1')
        .replaceAll('é', '2')
        .replaceAll('"', '3')
        .replaceAll("'", '4')
        .replaceAll('(', '5')
        .replaceAll('-', '6')
        .replaceAll('è', '7')
        .replaceAll('_', '8')
        .replaceAll('ç', '9');

    if (transformed.length <= 5) return '';
    return transformed.substring(5);
  }

  Future<void> _loadBrebis(String zip) async {
    final db = DatabaseHelper.instance;

    final brebis = await db.getBrebisByZip(zip);

    if (brebis == null) {
      setState(() {
        brebisId = null;
        boucleMere = calculBoucle(zip);
        nombreAgneau = '1';
        _generateEmptyAgneaux(1);
      });
      return;
    }

    setState(() {
      brebisId = brebis['id'];
      boucleMere = brebis['boucle'];
    });

    commentaireMereController.text =
        brebis['commentaire'] ?? '';

    final data =
        await db.getAgneauxByBrebisAndYear(brebisId!, currentYear);

    setState(() {
      nombreAgneau = data.length.toString();

      agneaux = data
          .map((a) => AgneauModel(
                id: a['id'],
                zip: a['zip'] ?? '',
                commentaire: a['commentaire'] ?? '',
                boucle: a['boucle'] ?? '',
                male: a['sexe'] == 'M',
                femelle: a['sexe'] == 'F',
                vivant: a['vivant'] == 1,
              ))
          .toList();

      if (agneaux.isEmpty) {
        _generateEmptyAgneaux(1);
      }
    });
  }

  void _handleNombreChange(String newValue) {
    final newCount = int.parse(newValue);
    final currentCount = agneaux.length;

    if (newCount < currentCount && brebisId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Impossible de réduire. Décochez 'vivant' pour un agneau en moins."),
        ),
      );
      return;
    }

    setState(() {
      if (newCount > currentCount) {
        // ➕ Ajout
        for (int i = 0; i < newCount - currentCount; i++) {
          agneaux.add(AgneauModel());
        }
      } else if (newCount < currentCount) {
        for (int i = newCount; i < currentCount; i++) {
          agneaux[i].dispose();
        }
        agneaux = agneaux.sublist(0, newCount);
      }
        nombreAgneau = newValue;
      });
  }

  Future<void> _save() async {
    final db = DatabaseHelper.instance;

    brebisId ??=
      await db.getOrCreateBrebis(
      zipController.text,
      boucleMere,
      commentaireMereController.text,
    );

    if (brebisId != null) {
      await db.updateBrebisCommentaire(
        brebisId!,
        commentaireMereController.text,
      );
    }

    for (var a in agneaux) {
      final data = {
        'brebis_id': brebisId,
        'annee': currentYear,
        'zip': a.zipController.text,
        'boucle': a.boucle,
        'sexe': a.sexe,
        'vivant': a.vivant ? 1 : 0,
        'commentaire': a.commentController.text,
      };

      if (a.id == null) {
        a.id = await db.insertAgneau(data);
      } else {
        await db.updateAgneau(a.id!, data);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enregistré")),
    );

    setState(() {
      zipController.clear();
      commentaireMereController.clear();
      boucleMere = '';
      brebisId = null;
      nombreAgneau = '1';

      for (var a in agneaux) {
        a.dispose();
      }

      _generateEmptyAgneaux(1);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      zipFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("ZIP mère",
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: zipController,
            focusNode: zipFocusNode,
            onChanged: (v) {
              if (v.length > 5) {
                _loadBrebis(v);
              }
            },
          ),
          const SizedBox(height: 8),
          Text("Boucle mère : $boucleMere",
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 8),
          const Text("Commentaire brebis"),
          TextField(
            controller: commentaireMereController,
            maxLines: 2,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),

          const Divider(),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nombre d’agneaux",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: nombreAgneau,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: ['1', '2', '3', '4', '5']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => _handleNombreChange(v!),
              ),
            ],
          ),

          const Divider(),

          ...agneaux.asMap().entries.map((entry) {
            final index = entry.key;
            final a = entry.value;

            return Card(
              elevation: 2,
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Agneau ${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: a.sexeNonRenseigne
                              ? Colors.orange
                              : Colors.black,
                        ),
                      ),
                    ),
                    if (a.sexeNonRenseigne)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                  ],
                ),
                childrenPadding:
                    const EdgeInsets.all(8),
                children: [
                  if (a.sexeNonRenseigne)
                    const Padding(
                      padding:
                          EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange,
                              size: 18),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Sexe non renseigné",
                              style: TextStyle(
                                  color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text("ZIP agneau"),
                  TextField(
                    controller: a.zipController,
                    onChanged: (v) {
                      setState(() {
                        a.boucle =
                            calculBoucle(v);
                      });
                    },
                  ),
                  Text("Boucle : ${a.boucle}"),

                  CheckboxListTile(
                    title: const Text("Mâle"),
                    value: a.male,
                    onChanged: (v) {
                      setState(() {
                        a.male = v!;
                        if (v) a.femelle = false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Femelle"),
                    value: a.femelle,
                    onChanged: (v) {
                      setState(() {
                        a.femelle = v!;
                        if (v) a.male = false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Vivant"),
                    value: a.vivant,
                    onChanged: (v) =>
                        setState(() => a.vivant = v!),
                  ),
                  const Text("Commentaire"),
                  TextField(
                    controller: a.commentController,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }
}