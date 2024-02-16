import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RandomNumberGeneratorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Random Number Generator'),
      ),
      body: Center(
        child: RandomNumberGeneratorButton(),
      ),
    );
  }
}

class RandomNumberGeneratorButton extends StatelessWidget {
  final RandomNumberGenerator _generator = RandomNumberGenerator();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        String randomCombination = await _generator.generateUniqueRandomNumber();
        print('Generated unique random combination: $randomCombination');
      },
      child: Text('Generate Random Number'),
    );
  }
}

class RandomNumberGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth=FirebaseAuth.instance;
  Future<String> generateUniqueRandomNumber() async {
    String randomCombination = ''; // Initialize with an empty string
    bool unique = false;

    // Keep generating until a unique combination is found
    while (!unique) {
      randomCombination = _generateRandomCombination();
      unique = await _checkUniqueCombination(randomCombination);
    }

    // Store the random combination as a document name in Firestore
    await _storeRandomCombination(randomCombination);

    return randomCombination;
  }

  String _generateRandomCombination() {
    // Generate a random combination of numbers (e.g., 6 digits)
    Random random = Random();
    String combination = '';
    for (int i = 0; i < 10; i++) { //earlier i=6
      combination += random.nextInt(10).toString();
    }
    return combination;
  }

  Future<bool> _checkUniqueCombination(String combination) async {
    // Check if the combination already exists in Firestore array
    QuerySnapshot querySnapshot = await _firestore.collection('random_numbers_list').get();
    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      List<dynamic> numbers = document['numbers'];
      if (numbers.contains(combination)) {
        return false; // Combination already exists, not unique
      }
    }
    return true; // Combination is unique
  }

  Future<void> _storeRandomCombination(String combination) async {
    // Store the combination in Firestore
    await _firestore.collection('random_numbers').doc(combination).set({
      'created_at': DateTime.now(),
    });
    final user=_auth.currentUser;
    await _firestore.collection('random_numbers_list').doc(user!.uid).set({
      'numbers': FieldValue.arrayUnion([combination]),
    }, SetOptions(merge: true));
  }
}

void main() {
  runApp(MaterialApp(
    home: RandomNumberGeneratorScreen(),
  ));
}
