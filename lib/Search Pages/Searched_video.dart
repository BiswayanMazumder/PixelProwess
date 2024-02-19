import 'dart:async';
import 'package:timeago/timeago.dart'as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelprowess/Pages/searched_userpage.dart';
import 'package:video_player/video_player.dart';
class Searched_video extends StatefulWidget {
  final UIDs;
  Searched_video({
    required this.UIDs,
  });
  @override
  State<Searched_video> createState() => _Searched_videoState();
}

class _Searched_videoState extends State<Searched_video> {
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  FirebaseAuth _auth=FirebaseAuth.instance;
  String thumbnail='';
  late VideoPlayerController _controller;
  late ValueNotifier<Duration> _currentPositionNotifier;
  bool _showControls = true;
  Future<void> fetchthumbnail()async{
    final docsnap=await _firestore.collection('Global Post').doc(widget.UIDs).get();
    if(docsnap.exists){
      setState(() {
        thumbnail=docsnap.data()?['Thumbnail Link'];
      });
    }
    print('thumbnail fetched $thumbnail');
  }
  String videourl='';
  Future<void> fetchvideourl()async{
    final docsnap=await _firestore.collection('Global Post').doc(widget.UIDs).get();
    if(docsnap.exists){
      setState(() {
        videourl=docsnap.data()?['Video Link'];
      });
    }
    print('video fetched $videourl');
  }
  String UID='';
  Future<void> fetchuid()async{
    final docsnap=await _firestore.collection('Global Post').doc(widget.UIDs).get();
    if(docsnap.exists){
      setState(() {
        UID=docsnap.data()?['Uploaded UID'];
      });
    }
    print('uid fetched $UID');
  }
  String username='';
  Future<void> fetchusername() async{
    await fetchuid();
    final docsnap=await _firestore.collection('User Details').doc(UID).get();
    if(docsnap.exists){
      setState(() {
        username=docsnap.data()?['Username'];
      });
    }
  }
  String caption='';
  Future<void> fetchcaption()async{
    final docsnap=await _firestore.collection('Global Post').doc(widget.UIDs).get();
    if(docsnap.exists){
      setState(() {
        caption=docsnap.data()?['Caption'];
      });
    }
    print('caption fetched $caption');
  }
  int views=0;
  Future<void> fetchviews()async{
    final docsnap=await _firestore.collection('Global Post').doc(widget.UIDs).get();
    if(docsnap.exists){
      setState(() {
        views=docsnap.data()?['Views'];
      });
    }
    print('views fetched $views');
  }
  DateTime uploaddate=DateTime.now();
  Future<void> fetchuploaddate()async{
    final docsnap=await _firestore.collection('Global Post').doc(widget.UIDs).get();
    if(docsnap.exists){
      final timestamp = docsnap.data()?['Uploaded At'] as Timestamp;
      final uploadDateTime = timestamp.toDate();
      setState(() {
        uploaddate = uploadDateTime;
      });
    }
    print('upload date fetched $uploaddate');
  }
  List<String> subscriber=[];
  bool issubscribed=false;
  Future<void> fetchsubscriber() async {
    await fetchuid();
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Subscribers')
          .doc(UID)
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

      print('following searched$subscriber');
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
  Future<void> subscribeuser()async{
    final user=_auth.currentUser;
    await fetchuid();
    await _firestore.collection('Subscribers').doc(UID).set({
      'Subscriber UIDs':FieldValue.arrayUnion([
        user!.uid
      ])
    });
  }
  Future<void> unsubscribeuser()async{
    final user=_auth.currentUser;
    await fetchuid();
    await _firestore.collection('Subscribers').doc(UID).set({
      'Subscriber UIDs':FieldValue.arrayRemove([
        user!.uid
      ])
    });
  }
  String profileurl='';
  Future<void>fetchprofilepictures()async{
    await fetchuid();
    final docsnap=await _firestore.collection('User Profile Pictures').doc(UID).get();
    if(docsnap.exists){
      setState(() {
        profileurl=docsnap.data()?['Profile Pic'];
      });
    }
    else{
      setState(() {
        profileurl='https://img.freepik.com/free-vector/businessman-character-avatar-isolated_'
            '24877-60111.jpg?w=740&t=st=1707932498~exp=1707933098~hmac=63fef39a600650c9d8f0c064778238717'
            'd1a8298782da830e68ce7818054ed6f';
      });
    }
    print('profile pics $profileurl');
  }
  bool isdisliked=false;
  List<String>dislikedusers=[];
  Future<void> fetchdislikedusers() async{
    DocumentSnapshot documentSnapshot = await _firestore
        .collection('Disliked Videos')
        .doc(widget.UIDs)
        .get();
    if (documentSnapshot.exists) {
      dynamic data = documentSnapshot.data();
      if (data != null) {
        List<dynamic> posts = (data['UIDs'] as List?) ?? [];
        setState(() {
          dislikedusers =posts.map((post) => post.toString()).toList();
        });
      }
      final user=_auth.currentUser;
      if(dislikedusers.contains(user!.uid)){
        setState(() {
          isdisliked=true;
        });
      }
      else{
        setState(() {
          isdisliked=false;
        });
      }
    }
    print('disliked users $dislikedusers');
    print('disliked  searched$isdisliked');
  }
  List<String>likedusers=[];
  bool isliked=false;
  Future<void> fetchlikedusers() async{
    await fetchuid();
    DocumentSnapshot documentSnapshot = await _firestore
        .collection('Liked Videos')
        .doc(widget.UIDs)
        .get();
    if (documentSnapshot.exists) {
      dynamic data = documentSnapshot.data();
      if (data != null) {
        List<dynamic> posts = (data['UIDs'] as List?) ?? [];
        setState(() {
          likedusers =posts.map((post) => post.toString()).toList();
        });
      }
      final user=_auth.currentUser;
      if(likedusers.contains(user!.uid)){
        setState(() {
          isliked=true;
        });
      }
      else{
        setState(() {
          isliked=false;
        });
      }
    }
    print('liked users $likedusers');
    print('liked searched $isliked');
  }
  Future<void> Likeduser() async{
    final user=_auth.currentUser;
    await _firestore.collection('Liked Videos').doc(widget.UIDs).set({
      'UIDs':FieldValue.arrayUnion([
        user!.uid
      ])
    },SetOptions(merge:true));
  }
  Future<void> dislikeduser() async{
    final user=_auth.currentUser;
    await _firestore.collection('Disliked Videos').doc(widget.UIDs).set({
      'UIDs':FieldValue.arrayUnion([
        user!.uid
      ])
    },SetOptions(merge: true));
  }
  double _sliderValue = 0.0; // Current value of the slider
  Duration _duration = Duration();
  void fetchUserDataPeriodically() {
    // Fetch data initially
    fetchData();

    // Set up a timer to fetch data every 2 seconds
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      fetchData();
    });
  }
  Future<void> fetchData() async {
    await fetchlikedusers();
    await fetchdislikedusers();
    await fetchsubscriber();
    await fetchviews();
    await fetchuploaddate();
  }
  @override
  @override
  void initState() {
    super.initState();
    fetchthumbnail();
    fetchUserDataPeriodically();
    fetchdislikedusers();
    fetchprofilepictures();
    fetchlikedusers();
    fetchcaption();
    fetchviews();
    fetchuploaddate();
    fetchuid();
    fetchsubscriber();
    fetchusername();
    fetchvideourl().then((_) {
      // Initialize VideoPlayerController after fetching the video URL
      _controller = VideoPlayerController.network(
        videourl,
      )..initialize().then((_) {
        setState(() {
          _duration = _controller.value.duration;
        });
        // Start timer to hide controls after 5 seconds
        Timer(Duration(seconds: 5), () {
          setState(() {
            _showControls = false;
          });
        });
        // Start autoplay
        _controller.play();
      });
      _currentPositionNotifier = ValueNotifier(Duration.zero);
      _controller.addListener(() {
        final position = _controller.value.position;
        _currentPositionNotifier.value = position;
        setState(() {
          _sliderValue = position.inSeconds.toDouble();
          _duration = _controller.value.duration;
        });
      });
    });
  }

  bool _isFullscreen = false;
  @override
  Widget build(BuildContext context) {
    final user=_auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _controller.value.isInitialized?GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: Stack(
                children: [
                  _controller.value.isInitialized
                      ? _isFullscreen
                      ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size?.width ?? 0,
                        height: _controller.value.size?.height ?? 0,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                      : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                      : Container(),
                  if (_controller.value.isBuffering && !_controller.value.isPlaying)
                    Positioned(
                      top: 100,
                      right:180,
                      child:  CircularProgressIndicator(
                        // Customize the circular progress indicator as needed
                        strokeWidth: 5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),),
                  if(_controller.value.isCompleted)
                    Image.network(thumbnail),
                  if (_showControls)
                    _isFullscreen? Positioned(
                      top: MediaQuery.of(context).size.height / 2 - 25,
                      left: MediaQuery.of(context).size.width / 2 - 25,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ):Positioned(
                      top: 80,
                      left: 10,
                      right: 10,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  _showControls
                      ? Positioned(
                    top: 178, // Adjust this value to change the distance between the slider and the duration text
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${Duration(seconds: _sliderValue.toInt()).toString().split('.').first}',
                                style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_duration.toString().split('.').first}',
                                style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        _controller.value.isInitialized?Slider(
                          value: _currentPositionNotifier.value.inSeconds.toDouble(),
                          min: 0,
                          max: _controller.value.duration.inSeconds.toDouble(),
                          onChanged: (newValue) {
                            final newDuration = Duration(seconds: newValue.toInt());
                            _currentPositionNotifier.value = newDuration;
                            _controller.seekTo(newDuration);
                          },
                        ):Container(),
                      ],
                    ),
                  )
                      : SizedBox.shrink(),
                  // if (_showControls)
                  //   Positioned(
                  //     top: _isFullscreen ? MediaQuery.of(context).size.height - 80 : 180,
                  //     right: _isFullscreen ? 10 : -5,
                  //     child: IconButton(
                  //       onPressed: () {
                  //         setState(() {
                  //           _isFullscreen = !_isFullscreen;
                  //         });
                  //         _toggleFullScreen();
                  //       },
                  //       icon: Icon(
                  //         _isFullscreen
                  //             ? Icons.fullscreen_exit
                  //             : Icons.fullscreen,
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
            ):Image.network(thumbnail,),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text(caption,style: GoogleFonts.arbutusSlab(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                if(views==0)
                  Text('No Views',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 13),),
                if(views==1)
                  Text('${views} view',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 13),),
                if(views>1)
                  Text('${views} views',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 13),),
                SizedBox(
                  width: 20,
                ),
                Text(
                  '${timeago.format(uploaddate, locale: 'en_short', allowFromNow: true)} ago', // Format the upload date
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w300),
                ),
              ],
            ),
            SizedBox(
              height: 35,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                ),
                // InkWell(
                //   onTap: (){
                //     Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: widget.UID),));
                //   },
                //   child: CircleAvatar(
                //     radius: 20,
                //     backgroundImage: NetworkImage(widget.profilepicurl),
                //   ),
                // ),
                SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: UID),));
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(profileurl),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: UID),));
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: widget.UID),));
                      },
                      child: Text(username,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,
                          fontSize: 12),),
                    ),
                    if(subscriber.length<=1)
                      Text('${subscriber.length} Subscriber',style: TextStyle(color: Colors.grey,fontSize: 12,fontWeight: FontWeight.bold),),
                    if(subscriber.length>1)
                      Text('${subscriber.length} Subscribers',style: TextStyle(color: Colors.grey,fontSize: 12,fontWeight: FontWeight.bold),),
                  ],
                ),
                SizedBox(
                  width: 20,
                ),
                if(UID!=user!.uid)
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
                              child: Icon(CupertinoIcons.bell,color: Colors.white,)),
                        ),
                      if(!issubscribed)
                        Center(
                          child: ElevatedButton(onPressed: (){
                            subscribeuser();
                            fetchsubscriber();
                          },
                              onLongPress: (){
                                print('hi long press');
                              },
                              style: ButtonStyle(
                                  backgroundColor: MaterialStatePropertyAll(Colors.white)
                              ),
                              child: Text('Subscribe',style: TextStyle(color: Colors.black),)),
                        ),
                    ],
                  ),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(isliked)
                  IconButton(onPressed: ()async{
                    final user=_auth.currentUser;
                    await _firestore.collection('Liked Videos').doc(widget.UIDs).set({
                      'UIDs':FieldValue.arrayRemove([
                        user!.uid
                      ])
                    });
                    fetchlikedusers();
                  }, icon: Icon(CupertinoIcons.hand_thumbsup_fill,color: Colors.white,)),
                if(!isliked)
                  IconButton(onPressed: ()async{
                    final user=_auth.currentUser;
                    await _firestore.collection('Disliked Videos').doc(widget.UIDs).set({
                      'UIDs':FieldValue.arrayRemove([
                        user!.uid
                      ])
                    });
                    Likeduser();
                    fetchlikedusers();
                  }, icon: Icon(CupertinoIcons.hand_thumbsup,color: Colors.white,)),
                SizedBox(
                  width: 50,
                ),
                if(isdisliked)
                  IconButton(onPressed: ()async{
                    final user=_auth.currentUser;
                    await _firestore.collection('Disliked Videos').doc(widget.UIDs).set({
                      'UIDs':FieldValue.arrayRemove([
                        user!.uid
                      ])
                    });
                    fetchdislikedusers();
                  }, icon: Icon(CupertinoIcons.hand_thumbsdown_fill,color: Colors.white,)),
                if(!isdisliked)
                  IconButton(onPressed: ()async{
                    dislikeduser();
                    final user=_auth.currentUser;
                    await _firestore.collection('Liked Videos').doc(widget.UIDs).set({
                      'UIDs':FieldValue.arrayRemove([
                        user!.uid
                      ])
                    });
                    fetchlikedusers();
                  }, icon: Icon(CupertinoIcons.hand_thumbsdown,color: Colors.white,)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _controller.pause();
    _currentPositionNotifier.dispose();
  }
}
