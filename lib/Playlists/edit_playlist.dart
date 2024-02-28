import 'dart:io';
import 'dart:math';
import 'package:circular_progress_stack/circular_progress_stack.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class Playlist_creation extends StatefulWidget {
  const Playlist_creation({Key? key}) : super(key: key);

  @override
  State<Playlist_creation> createState() => _Playlist_creationState();
}

class _Playlist_creationState extends State<Playlist_creation> {
  Color _iconColor = Colors.white; // Default color
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  bool _uploading = false;
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  bool islatest=true;
  bool iscommunity=false;
  bool isabout=false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _imageUrl;
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

  Future<bool> _checkUniqueCombination(String combination) async {
    // Check if the combination already exists in Firestore array
    QuerySnapshot querySnapshot =
    await _firestore.collection('Global Playlists').get();
    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      List<dynamic> numbers = document['VID'];
      if (numbers.contains(combination)) {
        return false; // Combination already exists, not unique
      }
    }
    return true; // Combination is unique
  }

  String _generateRandomCombination() {
    // Generate a random combination of numbers (e.g., 6 digits)
    Random random = Random();
    String combination = '';
    for (int i = 0; i < 10; i++) {
      //earlier i=6
      combination += random.nextInt(10).toString();
    }
    return combination;
  }
  Future<void> _storeRandomCombination(String combination) async {
    // Store the combination in Firestore
    final user = _auth.currentUser;
    setState(() {
      _uploading = true;
    });
    final ref = _storage.ref().child('Playlist Images/${user!.uid}/$combination');
    await ref.putFile(_image!);
    final imageUrl = await ref.getDownloadURL();

    await user.updateProfile(photoURL: imageUrl);
    await _firestore.collection(user!.uid).doc(combination).set({
      'Created At': DateTime.now(),
      'Playlist Name': _playlistController.text,
      'Uploaded UID': user!.uid,
      'Image URL': imageUrl // Fix this line
    });
    await _firestore.collection('Global Playlists').doc(user.uid).set({
      'VID': FieldValue.arrayUnion([combination]),
    }, SetOptions(merge: true));
    await _firestore.collection('User Uploaded Playlist ID').doc(user.uid).set({
      'VID': FieldValue.arrayUnion([combination]),
    }, SetOptions(merge: true));
    setState(() {
      _uploading = false;
      _imageUrl = imageUrl;
    });
  }

  bool _upload=true;
  Future<void> _pickImage() async {
    final user = _auth.currentUser;
    if (user!.emailVerified) {
      final pickedFile =
      await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _upload = false;
        });
      }
    } else {
      final pickedFile =
      await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _upload = false;
        });
      }
    }
  }
  TextEditingController _playlistController=TextEditingController();
  bool _uploaded=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        actions: [
          ElevatedButton(onPressed: ()async{
            final user=_auth.currentUser;
            await generateUniqueRandomNumber();
            Navigator.pop(context);
            _playlistController.clear();
          },
            child: Text('Create',style: TextStyle(color: Colors.black),),
            style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.green)),
          )
        ],
        backgroundColor: Colors.black,
        leading: IconButton(onPressed: (){}, icon: Icon(CupertinoIcons.back,color: Colors.white,)),
        title: Text('Create Playlist',style: GoogleFonts.abyssinicaSil(color: Colors.white,fontWeight: FontWeight.bold),),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                ),
                if(!_upload)
                  Text(
                    'Thumbnail Selected',
                    style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                SizedBox(
                  height: 20,
                ),
                if(_upload)
                  Text(
                    'Select Thumbnail',
                    style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            DottedBorder(
                borderType: BorderType.RRect,
                radius: Radius.circular(8),
                color: Colors.white,
                dashPattern: [10,4],
                strokeCap: StrokeCap.round,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  color:Colors.grey.withOpacity(0.3),
                  child: _upload
                      ? IconButton(
                    onPressed: _pickImage,
                    icon: Icon(Icons.upload, color: CupertinoColors.white),
                  )
                      : _image != null
                      ? Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      image: DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _upload = true;
                          _image = null;
                        });
                      },
                      icon: Icon(CupertinoIcons.clear,
                          color: Colors.black),
                    ),
                  )
                      : Container(),
                )
            ),
            SizedBox(
              height: 50,
            ),
            Text(
              'Playlist Name',
              style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _playlistController,
                decoration: InputDecoration(
                    hintText: 'Playlist Name',
                    fillColor: Colors.grey,
                    filled: true
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Color _calculateIconColor(Color backgroundColor) {
    // Use a simple heuristic to determine whether to use light or dark icon color
    // You can adjust this threshold based on your specific use case
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }
}
