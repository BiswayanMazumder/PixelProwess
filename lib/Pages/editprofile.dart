import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  String username='';
  String coverpicurl='';
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  TextEditingController _nameController=TextEditingController();
  TextEditingController _bioController=TextEditingController();
  bool _uploading = false;
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _imageUrl;
  Future<void> _pickcoverImage() async {
    final user = _auth.currentUser;
    if (user!.emailVerified) {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        _uploadcoverImage();
      }
    } else {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        _uploadcoverImage();
      }
    }

  }
  Future<void> _uploadcoverImage() async {
    try {
      final user = _auth.currentUser;
      if (user != null && _image != null) {
        setState(() {
          _uploading = true;
        });
        final ref = _storage.ref().child('cover_pictures/${user.uid}');
        await ref.putFile(_image!);
        final imageUrl = await ref.getDownloadURL();

        await user.updateProfile(photoURL: imageUrl);

        // Store the URL in Firestore
        await _firestore.collection('User Cover Pictures').doc(user.uid).set({
          'Cover Pic': imageUrl,
          'time stamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          _uploading = false;
          _imageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text('Cover picture uploaded successfully!'),
        ));
      }
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Error uploading profile picture: $e'),
      ));
    }
  }

  Future<void> _uploadImage() async {
    try {
      final user = _auth.currentUser;
      if (user != null && _image != null) {
        setState(() {
          _uploading = true;
        });
        final ref = _storage.ref().child('profile_pictures/${user.uid}');
        await ref.putFile(_image!);
        final imageUrl = await ref.getDownloadURL();

        await user.updateProfile(photoURL: imageUrl);

        // Store the URL in Firestore
        await _firestore.collection('User Profile Pictures').doc(user.uid).set({
          'Profile Pic': imageUrl,
          'time stamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          _uploading = false;
          _imageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text('Profile picture uploaded successfully!'),
        ));
      }
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Error uploading profile picture: $e'),
      ));
    }
  }
  Future<void> _pickImage() async {
    final user = _auth.currentUser;
    if (user!.emailVerified) {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        _uploadImage();
      }
    } else {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        _uploadImage();
      }
    }

  }
  Future<void>fetchusername()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection('User Details').doc(user!.uid).get();
    if(docsnap.exists){
      setState(() {
        username=docsnap.data()?['Username'];
      });
    }
  }
  String profilepicurl='';
  Future<void> fetchprofilepic()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection('User Profile Pictures').doc(user!.uid).get();
    if(docsnap.exists){
      setState(() {
        profilepicurl=docsnap.data()?['Profile Pic'];
      });
    }
  }
  Future<void> fetchcoverpic()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection('User Cover Pictures').doc(user!.uid).get();
    if(docsnap.exists){
      setState(() {
        coverpicurl=docsnap.data()?['Cover Pic'];
      });
    }
  }
  String userbio='No bio';
  Future<void> fetchbio()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection('User Details').doc(user!.uid).get();
    if(docsnap.exists){
      setState(() {
        userbio=docsnap.data()?['Bio'];
      });
    }
  }
  void fetchUserDataPeriodically() {
    // Fetch data initially
    fetchData();

    // Set up a timer to fetch data every 2 seconds
    Timer.periodic(Duration(seconds: 2), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    await fetchusername();
    await fetchprofilepic();
    await fetchcoverpic();
    await fetchbio();
    await fetchchannelprivate();
  }
  bool _isPrivate = false; // Default value is false, assuming subscribers are not private by default
  Future<void> fetchchannelprivate() async{
    final user=_auth.currentUser;
  final docsnap=await _firestore.collection('User Details').doc(user!.uid).get();
  if(docsnap.exists){
    setState(() {
      _isPrivate=docsnap.data()?['channel private'];
    });
  }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchusername();
    fetchprofilepic();
    fetchcoverpic();
    fetchbio();
    fetchchannelprivate();
    fetchUserDataPeriodically();
  }
  @override
  Widget build(BuildContext context) {
    final user=_auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(CupertinoIcons.chevron_back,color: Colors.white,)),
        backgroundColor: Colors.black,
        title: Text('Channel Settings',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Container(
              height: 150,
              width: 1000,
              color: Colors.grey,
              child: Stack(
                children: [
                  InkWell(
                    onTap: () {
                      print('cover');
                      _pickcoverImage();
                    },
                    child: coverpicurl.isNotEmpty
                        ? Image.network(
                      coverpicurl,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    )
                        : Image.network(
                      'https://images.pexels.com/photos/20072361/pexels-photo-20072361/free-photo-of-landscape-photography.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
                  ),
                  Center(
                    child: Stack(
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: profilepicurl.isNotEmpty
                                ? NetworkImage(profilepicurl)
                                : NetworkImage(
                                'https://img.freepik.com/free-vector/businessman-character-avatar-isolated_'
                                    '24877-60111.jpg?w=740&t=st=1707932498~exp=1707933098~hmac=63fef39a600650c9d8f0c064778238717'
                                    'd1a8298782da830e68ce7818054ed6f'),
                          ),
                        ),
                        Center(
                          child: IconButton(onPressed: (){
                            _pickImage();
                            print('dp');
                          }, icon: Icon(CupertinoIcons.camera,color: Colors.white,
                              size: 30,))
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text('Name',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(fillColor: Colors.grey, filled: true,
                hintText: username,
                  suffixIcon: IconButton(onPressed: ()async{
                    final user=_auth.currentUser;
                    await _firestore.collection('User Details').doc(user!.uid).update(
                        {
                          'Username':_nameController.text
                        });
                  }, icon: Icon(Icons.check,color: Colors.black,))
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text('Handle',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                decoration: InputDecoration(fillColor: Colors.grey, filled: true,
                    hintText: user != null && user.email != null ? '${user.email!}' : 'No Email',
                  suffixIcon: IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: user != null && user.email != null ? user.email! : 'No Email'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Center(child: Text('Copied')),
                        backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: Icon(Icons.copy, color: Colors.black),
                  ),

                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text('Description',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _bioController,
                decoration: InputDecoration(fillColor: Colors.grey, filled: true,
                    hintText: userbio,
                    suffixIcon: IconButton(onPressed: ()async{
                      final user=_auth.currentUser;
                      await _firestore.collection('User Details').doc(user!.uid).update(
                          {
                            'Bio':_bioController.text
                          });
                    }, icon: Icon(Icons.check,color: Colors.black,))
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text('Privacy',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
              ],
            ),
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                ),
                Text(
                  'Keep all my subscribers private',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Spacer(),
                CupertinoSwitch(
                  value: _isPrivate, // Use a boolean variable to track the state
                  onChanged: (bool value)async{
                    await _firestore.collection('User Details').doc(user!.uid).update(
                        {
                          'channel private':value
                        });
                    setState(() {
                      _isPrivate = value; // Update the state when the switch is toggled
                    });
                    print(_isPrivate);
                  },
                ),
                SizedBox(
                  width: 20,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

}
