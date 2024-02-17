import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelprowess/Homepages/Accountpage.dart';
import 'package:pixelprowess/main.dart';
import 'package:video_player/video_player.dart';

class Upload_Page extends StatefulWidget {
  const Upload_Page({Key? key}) : super(key: key);

  @override
  State<Upload_Page> createState() => _Upload_PageState();
}

class _Upload_PageState extends State<Upload_Page> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = '';
  Future<void> fetchusername() async {
    final user = _auth.currentUser;
    final docsnap =
    await _firestore.collection('User Details').doc(user!.uid).get();
    if (docsnap.exists) {
      setState(() {
        username = docsnap.data()?['Username'];
      });
    }
  }

  String profilepicurl = '';
  Future<void> fetchprofilepic() async {
    final user = _auth.currentUser;
    final docsnap = await _firestore
        .collection('User Profile Pictures')
        .doc(user!.uid)
        .get();
    if (docsnap.exists) {
      setState(() {
        profilepicurl = docsnap.data()?['Profile Pic'];
      });
    }
  }

  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  bool _upload = true;
  bool _uploading = true;
  File? _mediaFile;
  bool isImage = false;
  VideoPlayerController? _videoController;

  Future<void> _pickMedia() async {
    final user = _auth.currentUser;
    if (user!.emailVerified) {
      final pickedFile = await (isImage
          ? _imagePicker.pickImage(source: ImageSource.gallery)
          : _imagePicker.pickVideo(source: ImageSource.gallery));
      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
          _uploading = false;
        });
        if (!isImage) {
          _initializeVideoController();
        }
      }
    } else {
      final pickedFile = await (isImage
          ? _imagePicker.pickImage(source: ImageSource.gallery)
          : _imagePicker.pickVideo(source: ImageSource.gallery));
      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile.path);
          _uploading = false;
        });
        if (!isImage) {
          _initializeVideoController();
        }
      }
    }
  }

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

  FirebaseStorage _storage = FirebaseStorage.instance;
  double _uploadProgress = 0.0;
  Future<String> _uploadMediaFile() async {
    final user = _auth.currentUser;

    // Define the path for the new media file in Firebase Storage
    String mediaPath =
        'Videos/${user!.uid}/reels_${DateTime.now().millisecondsSinceEpoch}';

    // Upload the media file to Firebase Storage
    UploadTask uploadTask = _storage
        .ref('$mediaPath.${isImage ? 'jpg' : 'mp4'}')
        .putFile(
      _mediaFile!,
      // Add metadata to specify content type (optional)
      SettableMetadata(
        contentType: isImage ? 'image/jpeg' : 'video/mp4',
      ),
    );

    // Listen for state changes, errors, and completion of the upload task
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      // Calculate upload progress
      double percentage =
          (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      // Update UI with upload progress
      setState(() {
        // Update progress variable to display in UI
        _uploadProgress = percentage;
      });
    });

    // Await upload completion and get the download URL
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }
  Future<String> _uploadImage() async {
    // Define the path for the new image in Firebase Storage
    final user = _auth.currentUser;
    String imagePath =
        'Thumbnail/${user!.uid}/post_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Upload the image to Firebase Storage
    UploadTask uploadTask = _storage.ref(imagePath).putFile(
      _image!,
      // Add metadata to specify content type (optional)
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Listen for state changes, errors, and completion of the upload task
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      // Calculate upload progress
      double percentage =
          (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      // Update UI with upload progress
      setState(() {
        // Update progress variable to display in UI
        _uploadProgress = percentage;
      });
    });

    // Await upload completion and get the download URL
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }
  void _initializeVideoController() {
    _videoController = VideoPlayerController.file(_mediaFile!)
      ..initialize().then((_) {
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.play();
        _videoController!.setVolume(0.0);
      });
  }

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
    await _firestore.collection('Global VIDs').get();
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
    await _firestore.collection('Global Post').doc(combination).set({
      'Uploaded At': DateTime.now(),
      'Video Link': await _uploadMediaFile(),
      'Thumbnail Link': await _uploadImage(),
      'Caption': _title.text,
      'Uploaded UID': user!.uid,
      'Views':0
    });
    await _firestore.collection('Global VIDs').doc('VIDs').set({
      'VID': FieldValue.arrayUnion([combination]),
    }, SetOptions(merge: true));
    await _firestore.collection('User Uploaded Videos ID').doc(user.uid).set({
      'VID': FieldValue.arrayUnion([combination]),
    }, SetOptions(merge: true));
  }

  @override
  void initState() {
    super.initState();
    fetchusername();
    fetchprofilepic();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  TextEditingController _title = TextEditingController();
  bool _startedposting=false;
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final Upload_Page _generator = Upload_Page();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        actions: [
          _startedposting?Container():TextButton(
              onPressed: () async {
              if(_mediaFile!=null &&_image!=null &&_title.text!=null){
                setState(() {
                  _startedposting=true;
                });
                await generateUniqueRandomNumber();
                Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 5,
                  ),
                );
                Navigator.push(context, MaterialPageRoute(builder: (context) => Accountpage(),));
              }
              },
              child: Text(
                'Post',
                style: TextStyle(color: Colors.white),
              ))
        ],
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(CupertinoIcons.back, color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Video to be uploaded',
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
            Divider(
              color: CupertinoColors.white,
              thickness: 0.2,
              indent: 50,
              endIndent: 50,
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              height: 300,
              width: 200,
              color: Colors.black,
              child: _uploading
                  ? IconButton(
                onPressed: () {
                  _pickMedia();
                },
                icon:
                Icon(Icons.upload, color: CupertinoColors.white),
              )
                  : _mediaFile != null
                  ? _videoController != null
                  ? AspectRatio(
                aspectRatio:
                _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
                  : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  image: isImage
                      ? DecorationImage(
                    image: FileImage(_mediaFile!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
              )
                  : Container(),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Thumbnail Selected',
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
            Divider(
              color: CupertinoColors.white,
              thickness: 0.2,
              indent: 50,
              endIndent: 50,
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              height: 300,
              width: 900,
              color: Colors.black,
              child: _upload
                  ? IconButton(
                onPressed: _pickImage,
                icon: Icon(Icons.upload, color: CupertinoColors.white),
              )
                  : _image != null
                  ? Container(
                width: 900,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  image: DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
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
                      color: Colors.white),
                ),
              )
                  : Container(),
            ),
            SizedBox(
              height: 20,
            ),
            Divider(
              color: CupertinoColors.white,
              thickness: 0.2,
              indent: 50,
              endIndent: 50,
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                ),
                CircleAvatar(
                  backgroundImage: NetworkImage(profilepicurl),
                ),
                SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      user != null && user.email != null
                          ? '@${user.email!}'
                          : 'No Email',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          fontSize: 13),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                  ],
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Divider(
              color: CupertinoColors.white,
              thickness: 0.2,
              indent: 50,
              endIndent: 50,
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
                style: TextStyle(color: Colors.white),
                controller: _title,
                maxLength: 15,
                decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle:
                    TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w400),
                    hintText: '   Create a title $username',
                    hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300))),
            SizedBox(
              height: 20,
            ),
            _uploading?Container()
            :Text(
              'Upload Progress: ${_uploadProgress.toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 15),
            ),
            SizedBox(
              height: 80,
            ),
          ],
        ),
      ),
    );
  }
}
