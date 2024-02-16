import 'dart:async';
import 'dart:io';
import 'package:pixelprowess/Pages/test_video_if.dart';
import 'package:pixelprowess/Video%20Card/uservideo(Sample).dart';
import 'package:pixelprowess/main.dart';
import 'package:timeago/timeago.dart'as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelprowess/Pages/editprofile.dart';
import 'package:video_player/video_player.dart';
class Accountpage extends StatefulWidget {
  const Accountpage({Key? key}) : super(key: key);

  @override
  State<Accountpage> createState() => _AccountpageState();
}

class _AccountpageState extends State<Accountpage> {
  String username='';
  String coverpicurl='';
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  bool _uploading = false;
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  bool islatest=true;
  bool ispopular=false;
  bool isoldest=false;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _imageUrl;
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
    print('Cover pic $coverpicurl');
  }
  int videocount=0;

  Future<void> fetchsubscriber() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Subscriber')
          .doc(user?.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Subscribers'] as List?) ?? [];
          setState(() {
            subscriber =
                posts.map((post) => post['SubscriberUid'].toString()).toList();
          });
        }
      }
      print('following $subscriber');
    } catch (e) {
      print('Error fetching followers fetchfollowers: $e');
    }

  }
  List<String> subscriber=[];
  List<String> videos=['https://player.vimeo.com/progressive_redirect/playback/830415808/rendition/360p/file.mp4?loc=external&oauth2_token_id=57447761&signature=814150c4b842b78067aa1808a879bee2cbd5c96640853ee20e96a441ca1a0dc8',
  'https://media.istockphoto.com/id/1328671157/video/sydney-suburban-wildlife-on-cooks-river-canterbury-campsie-dulwich-hill-marrickville-ashbury.mp4?s=mp4-640x640-is&k=20&c=uNRCeA9axM4ntvdv1Rq1lWVzg8jW-F01ofv0RGXqDKQ='
  ];
  List<String>captions=["World's Costliest Ferrari",'Nature Beauty'];
  List<String> thumbnail=['https://images.pexels.com/photos/3954429/pexels-photo-3954429.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
    'https://images.pexels.com/photos/6706375/pexels-photo-6706375.jpeg?auto=compress&cs=tinysrgb&w=600'];
  List<int> views=[100,200];
  List<DateTime> uploaddate=[DateTime(2024,4,7),DateTime(2024,8,7)];
  Future<void> fetchdate() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('User Video')
          .doc(user?.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Videos'] as List?) ?? [];
          setState(() {
            uploaddate =posts.map((post) => (post['Upload Date'] as Timestamp).toDate()).toList();
          });
        }
      }
      print('video $videos');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }

  }
  Future<void> fetchviews() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('User Video')
          .doc(user?.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Videos'] as List?) ?? [];
          setState(() {
            views =posts.map((post) => int.parse(post['Views'].toString())).toList();
          });
        }
      }
      print('video $videos');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }

  }
  Future<void> fetchthumbnail() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('User Video')
          .doc(user?.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Videos'] as List?) ?? [];
          setState(() {
            thumbnail =
                posts.map((post) => post['thumbnail'].toString()).toList();
          });
        }
      }
      print('video $videos');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }

  }
  Future<void> fetchcaptions() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('User Video')
          .doc(user?.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Videos'] as List?) ?? [];
          setState(() {
            captions =
                posts.map((post) => post['captions'].toString()).toList();
          });
        }
      }
      print('video $videos');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }

  }
  List<Duration> videoLengths = [];
  Future<void> fetchvideo() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('User Video')
          .doc(user?.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Videos'] as List?) ?? [];
          setState(() {
            videos = posts.map((post) => post['videourl'].toString()).toList();
          });
          // Fetch video lengths
        }
      }
      print('video $videos');
    } catch (e) {
      print('Error fetching followers videos: $e');
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
    await fetchdate();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchusername();
    fetchVideoLengths();
    fetchprofilepic();
    fetchcoverpic();
    fetchsubscriber();
    fetchvideo();
    fetchbio();
    fetchUserDataPeriodically();
  }
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
          IconButton(onPressed: (){
            _auth.signOut();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(),));
          }, icon: Icon(Icons.logout,color: Colors.white,))
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
                      user != null && user.email != null ? '@${user.email!}' : 'No Email',
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
                        if(videos.length==0)
                            Text(
                              ' 0 Video',
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
                            ),
                        if(videos.length==1)
                          Text(
                            ' 1 Video',
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 12),
                          ),
                        if(videos.length>1)
                          Text(
                            ' ${videos.length} Videos',
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
            Center(
              child: ElevatedButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(),));
              },
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Colors.grey[900])
                  ),
                  child: Text('Manage Account',style: TextStyle(color: Colors.white),)),
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
                Text('Videos',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),)
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: (){
                  islatest=true;
                  ispopular=false;
                  isoldest=false;
                },
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(islatest?Colors.white:Colors.grey[900])),
                    child: Text('Latest',style: TextStyle(color: islatest?Colors.black:Colors.white),)),
                ElevatedButton(onPressed: (){
                  setState(() {
                    islatest=false;
                    ispopular=true;
                    isoldest=false;
                  });
                },
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(ispopular?Colors.white:Colors.grey[900])),
                    child: Text('Popular',style: TextStyle(color: ispopular?Colors.black:Colors.white),)),
                ElevatedButton(onPressed: (){
                  setState(() {
                    islatest=false;
                    ispopular=false;
                    isoldest=true;
                  });
                },
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(isoldest?Colors.white:Colors.grey[900])),
                    child: Text('Oldest',style: TextStyle(color: isoldest?Colors.black:Colors.white),)),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            for(int i=0;i<captions.length;i++)
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 20),
                      Stack(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => User_video(
                                    thumbnail: thumbnail[i],
                                    views: views[i],
                                    caption: captions[i],
                                    viddeourl: videos[i],
                                    uploaddate: uploaddate[i],
                                    Index: i,
                                  ),
                                ),
                              );
                              print('index $i');
                            },
                            child: Image.network(
                              thumbnail[i],
                              height: 150,
                              width: 150,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Text(
                              '${videoLengths[i].toString().split('.').first}',
                              // Converts Duration to string and removes milliseconds
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 20),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => User_video(
                                thumbnail: thumbnail[i],
                                views: views[i],
                                caption: captions[i],
                                viddeourl: videos[i],
                                uploaddate: uploaddate[i],
                                Index: i,
                              ),
                            ),
                          );
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
                                if (views[i] == 1)
                                  Text('${views[i]} view', style: TextStyle(color: Colors.grey)),
                                if (views[i] > 1)
                                  Text('${views[i]} views', style: TextStyle(color: Colors.grey)),
                                SizedBox(width: 10),
                                Text(
                                  timeago.format(uploaddate[i], locale: 'en_short', allowFromNow: true), // Format the upload date
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  SizedBox(
                    height: 40,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
