import 'package:flutter/material.dart';

class AgneauModel {
  int? id;
  final TextEditingController zipController;
  final TextEditingController commentController;

  String boucle;
  bool male;
  bool femelle;
  bool vivant;

  AgneauModel({
    this.id,
    String zip = '',
    String commentaire = '',
    this.boucle = '',
    this.male = false,
    this.femelle = false,
    this.vivant = true,
  })  : zipController = TextEditingController(text: zip),
        commentController = TextEditingController(text: commentaire);

  bool get sexeNonRenseigne => !male && !femelle;

  String? get sexe {
    if (male) return 'M';
    if (femelle) return 'F';
    return null;
  }

  void dispose() {
    zipController.dispose();
    commentController.dispose();
  }
}