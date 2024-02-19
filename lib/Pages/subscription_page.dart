import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pixelprowess/Pages/searched_userpage.dart';
class Subscription_Page extends StatefulWidget {
  const Subscription_Page({Key? key}) : super(key: key);

  @override
  State<Subscription_Page> createState() => _Subscription_PageState();
}

class _Subscription_PageState extends State<Subscription_Page> {
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  List<String> subscriber=[];
  Future<void> fetchsubscriber() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Subscribers')
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchsubscriber();
    fetchusernames();
    fetchprofilepics();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Subscriptions',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
      ),
      backgroundColor: Colors.black,
      body: GridView.count(
        crossAxisCount: 2,
        children: List.generate(username.length, (index) {
          return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: subscriber[index]),));
                  print('clicked ${subscriber[index]}');
                },
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profilepicurls[index]),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(username[index],style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)
                  ],
                ),
              )
          );
        }),
      ),

    );
  }
}
