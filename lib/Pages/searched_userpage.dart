import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelprowess/Pages/test_video_if.dart';
import 'package:pixelprowess/Pages/upload_page.dart';
import 'package:pixelprowess/Video%20Card/VideoCard.dart';
import 'package:pixelprowess/main.dart';
import 'package:timeago/timeago.dart'as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelprowess/Pages/editprofile.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class SearchedUser extends StatefulWidget {
  final String UID;
  SearchedUser({
    required this.UID,
  });
  @override
  State<SearchedUser> createState() => _SearchedUserState();
}

class _SearchedUserState extends State<SearchedUser> {
  String username='';
  String coverpicurl='';
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
  String email='';
  TextEditingController _communityController=TextEditingController();
  Future<void> fetchemail() async{
    final docsnap=await _firestore.collection('User Details').doc(widget.UID).get();
    if(docsnap.exists){
      setState(() {
        email=docsnap.data()?['Email'];
      });
    }
  }
  Future<void> fetchVideoLengths() async {
    await fetchvideo();
    for (int i = 0; i < videos.length; i++) {
      try {
        VideoPlayerController controller = VideoPlayerController.network(videos[i]);
        await controller.initialize();
        setState(() {
          videoLengths.add(controller.value.duration);
        });
        await controller.dispose();
      } catch (e) {
        print('Error fetching video length: $e');
      }
    }
    print('Video Length $videoLengths');
  }
  void sortVideosByOldest() {
    setState(() {
      videos.sort((a, b) => uploaddate[videos.indexOf(a)].compareTo(uploaddate[videos.indexOf(b)]));
      captions.sort((a, b) => uploaddate[captions.indexOf(a)].compareTo(uploaddate[captions.indexOf(b)]));
      thumbnail.sort((a, b) => uploaddate[thumbnail.indexOf(a)].compareTo(uploaddate[thumbnail.indexOf(b)]));
      views.sort((a, b) => uploaddate[views.indexOf(a)].compareTo(uploaddate[views.indexOf(b)]));
      uploaddate.sort();
    });
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
        await _firestore.collection('profile_pictures').doc(user.uid).set({
          'url_user1': imageUrl,
          'time stamp': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('User Details').doc(user.uid).update({
          'url_user1': imageUrl,
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
  String ipAddress='';
  Future<void> fetchIPAddress() async {
    final user = _auth.currentUser;
    final docSnap = await _firestore.collection('User Details').doc(widget.UID).get();
    if (docSnap.exists) {
      setState(() {
        ipAddress = docSnap.data()?['IPAddress'] ?? '';
      });
      if (ipAddress.isNotEmpty) {
        await fetchCountryNameFromIPAddress(ipAddress);
      } else {
        print('IP address is empty.');
      }
    }
    print('IP Address $ipAddress');
  }
  String countryname = '';
  Future<void> fetchCountryNameFromIPAddress(String ipAddress) async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/$ipAddress/json/'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() { // Update state with country name
          countryname = data['country_name'];
        });
        print('Country Name: $countryname');
      } else {
        if (response.statusCode == 429) {
          // Implement backoff strategy
          await Future.delayed(Duration(seconds: 5)); // Wait for 5 seconds
          await fetchCountryNameFromIPAddress(ipAddress); // Retry the request
        } else {
          print('Failed to get country name. Status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  Future<void>fetchusername()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection('User Details').doc(widget.UID).get();
    if(docsnap.exists){
      setState(() {
        username=docsnap.data()?['Username'];
      });
    }
  }
  String profilepicurl='';
  Future<void> fetchprofilepic()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection('User Profile Pictures').doc(widget.UID).get();
    if(docsnap.exists){
      setState(() {
        profilepicurl=docsnap.data()?['Profile Pic'];
      });
    }
  }
  Future<void> fetchcoverpic()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection('User Cover Pictures').doc(widget.UID).get();
    if(docsnap.exists){
      setState(() {
        coverpicurl=docsnap.data()?['Cover Pic'];
      });
    }
    print('Cover pic $coverpicurl');
  }
  int videocount=0;
  Future<void> subscribeuser()async{
    final user=_auth.currentUser;
    await _firestore.collection('Subscribers').doc(widget.UID).set({
      'Subscriber UIDs':FieldValue.arrayUnion([
        user!.uid
      ])
    },SetOptions(merge: true));
    await _firestore.collection('Subscriptions').doc(user!.uid).set({
      'Subscriber UIDs':FieldValue.arrayUnion([
        widget.UID
      ])
    },SetOptions(merge: true));
  }
  Future<void> unsubscribeuser()async{
    final user=_auth.currentUser;
    await _firestore.collection('Subscribers').doc(widget.UID).update({
      'Subscriber UIDs':FieldValue.arrayRemove([
        user!.uid
      ])
    });
    await _firestore.collection('Subscriptions'
        '').doc(user!.uid).update({
      'Subscriber UIDs':FieldValue.arrayRemove([
        widget.UID
      ])
    });
  }
  bool issubscribed=false;
  Future<void> fetchsubscriber() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Subscribers')
          .doc(widget.UID)
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

      print('following $subscriber');
    } catch (e) {
      print('Error fetching followers fetchfollowers: $e');
    }
    if(subscriber.contains(user!.uid)){
      setState(() {
        issubscribed=true;
      });
    }
    else{
      setState(() {
        issubscribed=false;
      });
    }
  }
  List<String> subscriber=[];
  List<String> videos=[];
  List<String>captions=[];
  List<String> thumbnail=[];

  List<DateTime> uploaddate=[];
  List<String>videoid=[];
  Future<void> fetchvideoid() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('User Uploaded Videos ID')
          .doc(widget.UID)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['VID'] as List?) ?? [];
          setState(() {
            videoid =posts.map((post) => post.toString()).toList();
          });
        }
      }
      print('vids $videoid');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }

  }
  String thumbnails='';
  Future<void> fetchthumbnail() async {
    final user = _auth.currentUser;
    await fetchvideoid();
    for(String vids in videoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          thumbnails=docsnap.data()?['Thumbnail Link'];
          thumbnail.add(thumbnails);
        });
      }
    }
    print(' thumbnail $thumbnail');
  }
  String Caption='';
  Future<void> fetchcaptions() async {
    final user = _auth.currentUser;
    await fetchvideoid();
    for(String vids in videoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          Caption=docsnap.data()?['Caption'];
          captions.add(Caption);
        });
      }
    }
    print(' captions $captions');
  }
  List<Duration> videoLengths = [];
  String Videolinks='';
  Future<void> fetchvideo() async {
    await fetchvideoid();
    for(String vids in videoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          Videolinks=docsnap.data()?['Video Link'];
          videos.add(Videolinks);
        });
      }
    }
    print(' videos $videos');
  }
  DateTime Uploaddate = DateTime.now();
  Future<void> fetchuploaddate() async {
    await fetchvideoid();
    for (String vids in videoid) {
      final docsnap =
      await _firestore.collection('Global Post').doc(vids).get();
      if (docsnap.exists) {
        final timestamp = docsnap.data()?['Uploaded At'] as Timestamp;
        final uploadDateTime = timestamp.toDate(); // Convert Firestore Timestamp to DateTime
        setState(() {
          Uploaddate = uploadDateTime;
          uploaddate.add(Uploaddate);
        });
      }
    }
    print(' upload date $uploaddate');
  }

  String userbio='No bio';
  Future<void> fetchbio()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection('User Details').doc(widget.UID).get();
    if(docsnap.exists){
      setState(() {
        userbio=docsnap.data()?['Bio'];
      });
    }
  }
  bool isplaylist=false;
  void fetchUserDataPeriodically() {
    // Fetch data initially
    fetchData();

    // Set up a timer to fetch data every 2 seconds
    Timer.periodic(Duration(seconds: 2), (timer) {
      fetchData();
    });
  }
  int fetchedviews=0;
  List<int> views=[];
  Future<void> fetchviews() async{
    await fetchvideoid();
    for (String vids in videoid) {
      final docsnap =
      await _firestore.collection('Global Post').doc(vids).get();
      if (docsnap.exists) {
        final fetchviews = docsnap.data()?['Views'];
        setState(() {
          fetchedviews = fetchviews;
          views.add(fetchedviews);
        });
      }
    }
    print(' Views got $views');
  }
  List<String>communityposts=[];
  List<DateTime> commuityuploaddate=[];
  Future<void> fetchcommunityposts() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Community Posts')
          .doc(widget.UID)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Posts'] as List?) ?? [];
          setState(() {
            communityposts =
                posts.map((post) => post['Posts'].toString()).toList();
          });
        }
      }
      print('community homepage $communityposts');
    } catch (e) {
      print('Error fetching followers fetchfollowers: $e');
    }

  }
  List<DateTime>commuploadate=[];
  Future<void> fetchCommunityUploadDate() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Community Posts')
          .doc(widget.UID)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Posts'] as List?) ?? [];
          setState(() {
            commuploadate = posts
                .map((post) =>
                (post['Date of Upload'] as Timestamp).toDate())
                .toList();
          });
        }
      }
      print('community upload $commuploadate');
    } catch (e) {
      print('Error fetching comm upload date: $e');
    }
  }
  Future<void> fetchData() async {
    await fetchusername();
    await fetchsubscriber();
    await fetchprofilepic();
    await fetchcoverpic();
    await fetchbio();
    await fetchcommunityposts();
    await fetchCommunityUploadDate();
  }
  int views_video=0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchusername();
    fetchVideoLengths();
    fetchprofilepic();
    fetchthumbnail();
    fetchcoverpic();
    fetchuploaddate();
    fetchcaptions();
    fetchvideo();
    fetchbio();
    fetchemail();
    fetchsubscriber();
    fetchvideoid();
    fetchviews();
    fetchUserDataPeriodically();
    fetchcommunityposts();
    fetchCommunityUploadDate();
    fetchIPAddress();
  }
  TextEditingController _captionController=TextEditingController();
  @override
  Widget build(BuildContext context) {
    final user=_auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
        ],
        title: Text(username,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
      ),
      body: SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Container(
                height: 150,
                width: 1000,
                color: Colors.grey,
                child: coverpicurl.isNotEmpty ? Image.network(
                  coverpicurl,
                  fit: BoxFit.fitWidth,
                ) : Image.network(
                  'https://images.pexels.com/photos/20072361/pexels-photo-20072361/free-photo-of-landscape-photography.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                  fit: BoxFit.fitWidth,
                ),
              ),
              SizedBox(
                height: 35,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profilepicurl.isNotEmpty?NetworkImage(profilepicurl):
                    NetworkImage('https://img.freepik.com/free-vector/businessman-character-avatar-isolated_'
                        '24877-60111.jpg?w=740&t=st=1707932498~exp=1707933098~hmac=63fef39a600650c9d8f0c064778238717'
                        'd1a8298782da830e68ce7818054ed6f'),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 13),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if(subscriber.length==0)
                            Text(
                              'No Subscribers',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
                            ),
                          if(subscriber.length==1)
                            Text(
                              ' ${subscriber.length} Subscriber',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
                            ),
                          if(subscriber.length>1)
                            Text(
                              ' ${subscriber.length} Subscribers',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
                            ),
                          SizedBox(
                            width: 10,
                          ),
                          if(thumbnail.length==0)
                            Text(
                              ' 0 Video',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
                            ),
                          if(thumbnail.length==1)
                            Text(
                              ' 1 Video',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
                            ),
                          if(thumbnail.length>1)
                            Text(
                              ' ${thumbnail.length} Videos',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
              Padding(
                  padding: EdgeInsets.only(top: 30, left: 30),
                  child: InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(),));
                    },
                    child:Text(
                      userbio,
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 13),
                    ),
                  )
              ),
              SizedBox(
                height: 20,
              ),
              if(widget.UID==user!.uid)
                Center(
                  child: ElevatedButton(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(),));
                  },
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(Colors.grey[900])
                      ),
                      child: Text('Manage Account',style: TextStyle(color: Colors.white),)),
                ),
              if(widget.UID!=user!.uid)
                Column(
                  children: [
                    if(issubscribed)
                      Center(
                        child: ElevatedButton(onPressed: (){
                          unsubscribeuser();
                          fetchsubscriber();
                        },
                            style: ButtonStyle(
                                backgroundColor: MaterialStatePropertyAll(Colors.grey[900])
                            ),
                            child: Text('Subscribed',style: TextStyle(color: Colors.white),)),
                      ),
                    if(!issubscribed)
                      Center(
                        child: ElevatedButton(onPressed: (){
                          subscribeuser();
                          fetchsubscriber();
                        },
                            style: ButtonStyle(
                                backgroundColor: MaterialStatePropertyAll(Colors.white)
                            ),
                            child: Text('Subscribe',style: TextStyle(color: Colors.black),)),
                      ),
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
                  if(islatest)
                    Text('Videos',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
                  if(iscommunity)
                    Text('Community',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
                  if(isabout)
                    Text('About',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
                  if(isplaylist)
                    Text('Playlist',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 20,
                    ),
                    ElevatedButton(onPressed: (){
                      islatest=true;
                      iscommunity=false;
                      isabout=false;
                      isplaylist=false;
                    },
                        style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(islatest?Colors.white:Colors.grey[900])),
                        child: Text('Latest',style: TextStyle(color: islatest?Colors.black:Colors.white),)),
                    SizedBox(
                      width: 20,
                    ),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        islatest=false;
                        iscommunity=true;
                        isabout=false;
                        isplaylist=false;
                      });
                    },
                        style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(iscommunity?Colors.white:Colors.grey[900])),
                        child: Text('Community',style: TextStyle(color: iscommunity?Colors.black:Colors.white),)),
                    SizedBox(
                      width: 20,
                    ),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        islatest=false;
                        iscommunity=false;
                        isabout=true;
                        isplaylist=false;
                      });
                    },
                        style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(isabout?Colors.white:Colors.grey[900])),
                        child: Text('About',style: TextStyle(color: isabout?Colors.black:Colors.white),)),
                    SizedBox(
                      width: 20,
                    ),
                    ElevatedButton(onPressed: (){
                      setState(() {
                        islatest=false;
                        iscommunity=false;
                        isabout=false;
                        isplaylist=true;
                      });
                    },
                        style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(isplaylist?Colors.white:Colors.grey[900])),
                        child: Text('Playlists',style: TextStyle(color: isplaylist?Colors.black:Colors.white),)),
                    SizedBox(
                      width: 20,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 50,
              ),
              for(int i=0;i<thumbnail.length;i++)
                islatest?Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 20),
                        Stack(
                          children: [
                            InkWell(
                              onTap: ()async{
                                final docsnap=await _firestore.collection('Global Post').doc(videoid[i]).get();
                                if(docsnap.exists){
                                  views_video=docsnap.data()?['Views'];
                                }
                                await _firestore.collection('Global Post').doc(videoid[i]).update(
                                    {
                                      'Views':views_video+1
                                    });
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => User_video(
                                //       thumbnail: thumbnail[i],
                                //       views: views[i],
                                //       caption: captions[i],
                                //       viddeourl: videos[i],
                                //       uploaddate: uploaddate[i],
                                //       Index: i,
                                //     ),
                                //   ),
                                // );
                                print('index $i');
                              },
                              child: Image.network(
                                thumbnail[i],
                                height: 150,
                                width: 150,
                              ),
                            ),
                            // Positioned(
                            //   bottom: 5,
                            //   right: 5,
                            //   child: Text(
                            //     '${videoLengths[i].toString().split('.').first}',
                            //     // Converts Duration to string and removes milliseconds
                            //     style: TextStyle(
                            //       color: Colors.white,
                            //       fontSize: 12,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        SizedBox(width: 20),
                        InkWell(
                          onTap: ()async{
                            final docsnap=await _firestore.collection('Global Post').doc(videoid[i]).get();
                            if(docsnap.exists){
                              views_video=docsnap.data()?['Views'];
                            }
                            await _firestore.collection('Global Post').doc(videoid[i]).update(
                                {
                                  'Views':views_video+1
                                });
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => User_video(
                            //       thumbnail: thumbnail[i],
                            //       views: views[i],
                            //       caption: captions[i],
                            //       viddeourl: videos[i],
                            //       uploaddate: uploaddate[i],
                            //       Index: i,
                            //     ),
                            //   ),
                            // );
                            print('Index $i');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (captions[i].split(' ').length <= 15)
                                Text(
                                  captions[i],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (captions[i].split(' ').length > 15)
                                Text(
                                  '${captions[i].split(' ').sublist(0, 15).join(' ')}...', // Take the first 15 words and join them
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (views[i] == 0)
                                    Text('No Views', style: TextStyle(color: Colors.grey)),
                                  if (views[i] == 1)
                                    Text('${views[i]} View', style: TextStyle(color: Colors.grey)),
                                  if (views[i] > 1)
                                    Text('${views[i]} Views', style: TextStyle(color: Colors.grey)),
                                  SizedBox(width: 10),
                                  Text(
                                    timeago.format(uploaddate[i], locale: 'en_short', allowFromNow: true), // Format the upload date
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              if(widget.UID==user!.uid)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(onPressed: ()async{
                                      print('CLicked ${videoid[i]}');
                                      showDialog(context: context, builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: Colors.black,
                                          title: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Center(
                                                child: Text('Are you sure?\n'
                                                    'Video once deleted can never be recovered.',style:TextStyle(color: Colors.white,
                                                    fontWeight: FontWeight.bold,fontSize: 15
                                                ),),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  TextButton(onPressed: ()async{
                                                    final user=_auth.currentUser;
                                                    try{
                                                      await _firestore.collection('User Uploaded Videos ID').doc(user!.uid).update({
                                                        'VID':FieldValue.arrayRemove([videoid[i]])
                                                      });
                                                      await _firestore.collection('Global VIDs').doc('VIDs').update({
                                                        'VID':FieldValue.arrayRemove([videoid[i]])
                                                      });
                                                      await _firestore.collection('Global Post').doc(videoid[i]).delete();
                                                      Navigator.pop(context);
                                                    }catch(e){
                                                      print('Deletion $e');
                                                    }
                                                  }, child: Text('Delete',style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight: FontWeight.bold
                                                  ),)),
                                                  TextButton(onPressed: ()async{
                                                    Navigator.pop(context);
                                                  }, child: Text('Cancel',style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold
                                                  ),))
                                                ],
                                              ),
                                            )
                                          ],
                                        );
                                      },);
                                    }, child: Text('Delete',style: TextStyle(color: Colors.red),)),
                                    Center(
                                        child: TextButton(onPressed: ()async{
                                          showDialog(context: context, builder: (context) {
                                            return AlertDialog(
                                              backgroundColor: Colors.black,
                                              title:Center(
                                                child: Text('Edit Caption',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w300,
                                                    fontSize: 15),),
                                              ),
                                              actions: [
                                                Column(
                                                  children: [

                                                    TextField(
                                                      style: TextStyle(color: Colors.white),
                                                      controller: _captionController,
                                                      maxLength: 15,

                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                      children: [

                                                        ElevatedButton(onPressed: (){
                                                          Navigator.pop(context);
                                                        },
                                                          child: Text('Cancel',style: TextStyle(color: Colors.white),),
                                                          style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.red)),
                                                        ),
                                                        SizedBox(
                                                          width:10 ,
                                                        ),
                                                        ElevatedButton(onPressed: ()async{
                                                          if(_captionController.text.isNotEmpty){
                                                            await _firestore.collection('Global Post').doc(videoid[i]).update(
                                                                {
                                                                  'Caption':_captionController.text
                                                                });
                                                            Navigator.pop(context);
                                                          }
                                                        }, child: Text('Make Changes',style: TextStyle(color: Colors.black),),
                                                          style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.green)),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ],
                                            );
                                          },);
                                          print('Clicked ${videoid[i]}');
                                        }, child: Text('Edit',style: TextStyle(color: Colors.white),),)),
                                  ],
                                )
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 40,
                    ),
                  ],
                ):Container(),
              iscommunity?Column(
                children: [
                 widget.UID==user!.uid? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      style: GoogleFonts.abyssinicaSil(color: Colors.white),
                      controller: _communityController,
                      decoration: InputDecoration(fillColor: Colors.grey.withOpacity(0.3),
                          filled: true,
                          suffixIcon:IconButton(onPressed: ()async{
                            final user=_auth.currentUser;
                            await _firestore.collection('Community Posts').doc(user!.uid).set(
                                {
                                  'Posts':FieldValue.arrayUnion([
                                    {
                                      'Posts':_communityController.text,
                                      'Date of Upload':DateTime.now(),
                                      'User ID':user.uid,
                                    }
                                  ])
                                },SetOptions(merge: true));
                            _communityController.clear();
                          },
                              icon: Icon(Icons.send,color: Colors.white,)),
                          hintText: '  Write for community...',
                          hintStyle: GoogleFonts.abyssinicaSil(color: Colors.white)
                      ),
                    ),
                  ):Container(),
                  SizedBox(
                    height: 50,
                  ),
                  if(communityposts.length==0)
                    Text('All empty here',style: GoogleFonts.aclonica(
                        color: Colors.white,
                        fontSize: 20
                    ),),
                  for(int i=0;i<communityposts.length;i++)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width:20,
                            ),
                            CircleAvatar(
                              backgroundImage: NetworkImage(profilepicurl),
                            ),
                            SizedBox(
                              width:20,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(username,style: GoogleFonts.abyssinicaSil(color: Colors.white,fontWeight: FontWeight.bold),),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    if(widget.UID==user!.uid)
                                      InkWell(
                                          onTap: ()async{
                                            await _firestore.collection('Community Posts').doc(user!.uid).update(
                                                {
                                                  'Posts':FieldValue.arrayRemove([
                                                    {
                                                      'Posts':communityposts[i],
                                                      'Date of Upload':commuploadate[i],
                                                      'User ID':user.uid,
                                                    }
                                                  ])
                                                });
                                          },
                                          child: Text('Delete',style: TextStyle(color: Colors.red),)),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    // InkWell(
                                    //     onTap: (){},
                                    //     child: Text('Edit',style: TextStyle(color: Colors.red),))
                                  ],
                                ),
                                Text(
                                  '${timeago.format(commuploadate[i], locale: 'en_long', allowFromNow: true)}', // Format the upload date
                                  style: TextStyle(color: Colors.grey,fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Text(communityposts[i],style: GoogleFonts.abyssinicaSil(color: Colors.white,fontSize: 15),),
                        SizedBox(
                          height: 50,
                        ),
                      ],
                    ),
                  SizedBox(
                    height: 50,
                  ),
                ],
              ):Container(),
              isabout?Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 0,
                      ),
                      Text(' Description',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,fontSize: 20),),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(' $userbio',style: GoogleFonts.abyssinicaSil(color: Colors.white,fontSize: 15),),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 0,
                      ),
                      Text(' More Info',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,fontSize: 20),),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),Row(
                    children: [
                      SizedBox(
                        width: 0,
                      ),
                      Icon(CupertinoIcons.globe,color: Colors.white,),
                      Text(' www.pixelprowess.com/u/channel/${user!.uid}',style: GoogleFonts.abyssinicaSil(color: Colors.white,fontSize: 10),),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 0,
                      ),
                      Icon(CupertinoIcons.map,color: Colors.white,),
                      Text(' $ipAddress',style: GoogleFonts.abyssinicaSil(color: Colors.white,fontSize: 15),),
                    ],
                  ),
                ],
              ):Container(),
              SizedBox(
                height: 50,
              ),
            ]
        ),
      ),
    );
  }
}
