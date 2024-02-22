import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class Notification_Page extends StatefulWidget {
  const Notification_Page({Key? key}) : super(key: key);

  @override
  State<Notification_Page> createState() => _Notification_PageState();
}

class _Notification_PageState extends State<Notification_Page> {
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  List<String> subscriber=[];
  Future<void> fetchsubscriber() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Subscriptions')
          .doc(user!.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Subscriber UIDs'] as List?) ?? [];
          setState(() {
            subscriber =
                posts.map((post) => post.toString()).toList();
          });
        }

      }

      print('following subs $subscriber');
    } catch (e) {
      print('Error fetching followers fetchfollowers: $e');
    }
  }
  List<String>username=[];
  String usernames='';
  Future<void> fetchusernames() async {
    final user = _auth.currentUser;
    await fetchsubscriber();
    List<String> newUploadedUserIds = [];
    for (String vids in subscriber) {
      final docsnap = await _firestore.collection('User Details').doc(vids).get();
      if (docsnap.exists) {
        newUploadedUserIds.add(docsnap.data()?['Username']);
      }
    }
    setState(() {
      username = List.from(newUploadedUserIds); // Update uploadeduseruid with newUploadedUserIds
    });
    print(' username subscribed homepage $username');
  }
  List<String>profilepicurls=[];
  String dpurls='';
  Future<void> fetchprofilepics() async {
    final user = _auth.currentUser;
    await fetchsubscriber();
    List<String> newUploadedUserIds = [];
    for (String vids in subscriber) {
      final docsnap = await _firestore.collection('User Profile Pictures').doc(vids).get();
      if (docsnap.exists) {
        newUploadedUserIds.add(docsnap.data()?['Profile Pic']);
      }
      else{
        newUploadedUserIds.add('https://img.freepik.com/free-vector/businessman-character-avatar-isolated_'
            '24877-60111.jpg?w=740&t=st=1707932498~exp=1707933098~hmac=63fef39a600650c9d8f0c064778238717'
            'd1a8298782da830e68ce7818054ed6f');
      }
    }
    setState(() {
      profilepicurls = List.from(newUploadedUserIds); // Update uploadeduseruid with newUploadedUserIds
    });
    print(' profile subscribed homepage $profilepicurls');
  }
  String thumbnails='';
  List<String> uploadeduseruid=[];
  List<String> thumbnail=[];
  Future<void> fetchthumbnail() async {
    final user = _auth.currentUser;
    await fetchsubscriber();
    for(String vids in subscriber){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          thumbnails=docsnap.data()?['Thumbnail Link'];
          thumbnail.add(thumbnails);
        });
      }
    }
    print(' thumbnail notification $thumbnail');
  }
  void fetchUserDataPeriodically() {
    // Fetch data initially
    fetchData();

    // Set up a timer to fetch data every 2 seconds
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      fetchData();
    });
  }
  Future<void> fetchData() async {
    await fetchsubscriber();
    await fetchusernames();
    await fetchprofilepics();
    await fetchthumbnail();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchsubscriber();
    fetchusernames();
    fetchprofilepics();
    fetchthumbnail();
    fetchUserDataPeriodically();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications',style: GoogleFonts.arbutusSlab(color: Colors.white),),
        centerTitle: false,
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(CupertinoIcons.back,color: Colors.white,)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            for(int i=0;i<username.length;i++)
              Column(
                children: [
                  SizedBox(
                    height:40 ,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 10,
                      ),
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(profilepicurls[i]),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text('${username[i]} just uploaded a video',style: GoogleFonts.arbutusSlab(color: Colors.white,fontWeight: FontWeight.bold,
                        fontSize: 10
                      ),),
                    ],
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
