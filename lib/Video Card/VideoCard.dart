import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixelprowess/Pages/searched_userpage.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart'as timeago;
import 'package:like_button/like_button.dart';
class VideoPage extends StatefulWidget {
  final String caption;
  final String UID;
  final DateTime uploaddate;
  final int Index;
  final String viddeourl;
  final int views;
  final String thumbnail;
  final String username;
  final String profilepicurl;
  final String VideoID;
  VideoPage({
    required this.caption,
    required this.uploaddate,
    required this.Index,
    required this.viddeourl,
    required this.views,
    required this.thumbnail,
    required this.username,
    required this.profilepicurl,
    required this.UID,
    required this.VideoID
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _controller;
  late ValueNotifier<Duration> _currentPositionNotifier;
  bool _showControls = true;
  bool _isFullscreen = false;
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  double _sliderValue = 0.0; // Current value of the slider
  Duration _duration = Duration();
  List<String> subscriber=[];
  List<String> likedusers=[];
  bool isliked=false;
  List<String> dislikedusers=[];
  bool isdisliked=false;
  Future<void> Likeduser() async{
    final user=_auth.currentUser;
    await _firestore.collection('Liked Videos').doc(widget.VideoID).set({
      'UIDs':FieldValue.arrayUnion([
        user!.uid
      ])
    },SetOptions(merge:true));
  }
  Future<void> dislikeduser() async{
    final user=_auth.currentUser;
    await _firestore.collection('Disliked Videos').doc(widget.VideoID).set({
      'UIDs':FieldValue.arrayUnion([
        user!.uid
      ])
    },SetOptions(merge: true));
  }
  Future<void> fetchlikedusers() async{
    DocumentSnapshot documentSnapshot = await _firestore
        .collection('Liked Videos')
        .doc(widget.VideoID)
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
    print('liked $isliked');
  }
  Future<void> fetchdislikedusers() async{
    DocumentSnapshot documentSnapshot = await _firestore
        .collection('Disliked Videos')
        .doc(widget.VideoID)
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
    print('liked users $dislikedusers');
    print('disliked $isdisliked');
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
    await fetchlikedusers();
    await fetchdislikedusers();
  }
  @override
  void initState() {
    super.initState();
    fetchlikedusers();
    fetchdislikedusers();
    fetchUserDataPeriodically();
    _controller = VideoPlayerController.network(
      widget.viddeourl,
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

  }

  @override
  Widget build(BuildContext context) {
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
                    Image.network(widget.thumbnail),
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
                        Slider(
                          value: _currentPositionNotifier.value.inSeconds.toDouble(),
                          min: 0,
                          max: _controller.value.duration.inSeconds.toDouble(),
                          onChanged: (newValue) {
                            final newDuration = Duration(seconds: newValue.toInt());
                            _currentPositionNotifier.value = newDuration;
                            _controller.seekTo(newDuration);
                          },
                        ),
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
            ):Image.network(widget.thumbnail,),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text(widget.caption,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
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
                if(widget.views==0)
                  Text('No Views',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 13),),
                if(widget.views==1)
                  Text('${widget.views} view',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 13),),
                if(widget.views>1)
                  Text('${widget.views} views',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 13),),
                SizedBox(
                  width: 20,
                ),
                Text(
                  '${timeago.format(widget.uploaddate, locale: 'en_short', allowFromNow: true)} ago', // Format the upload date
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w300),
                ),
              ],
            ),
            SizedBox(
              height: 35,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: widget.UID),));
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.profilepicurl),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: widget.UID),));
                  },
                  child: Text(widget.username,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                )
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
                    await _firestore.collection('Liked Videos').doc(widget.VideoID).set({
                      'UIDs':FieldValue.arrayRemove([
                        user!.uid
                      ])
                    });
                    fetchlikedusers();
                  }, icon: Icon(CupertinoIcons.hand_thumbsup_fill,color: Colors.white,)),
                if(!isliked)
                  IconButton(onPressed: ()async{
                    final user=_auth.currentUser;
                    await _firestore.collection('Disliked Videos').doc(widget.VideoID).set({
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
                    await _firestore.collection('Disliked Videos').doc(widget.VideoID).set({
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
                    await _firestore.collection('Liked Videos').doc(widget.VideoID).set({
                      'UIDs':FieldValue.arrayRemove([
                        user!.uid
                      ])
                    });
                    fetchlikedusers();
                  }, icon: Icon(CupertinoIcons.hand_thumbsdown,color: Colors.white,)),
              ],
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFullScreen() {
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _controller.pause();
    _currentPositionNotifier.dispose();
  }
}
