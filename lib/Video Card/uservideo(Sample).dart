import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart'as timeago;
import 'package:like_button/like_button.dart';
class User_video extends StatefulWidget {
  final String caption;
  final DateTime uploaddate;
  final int Index;
  final String viddeourl;
  final int views;
  final String thumbnail;

  User_video({
    required this.caption,
    required this.uploaddate,
    required this.Index,
    required this.viddeourl,
    required this.views,
    required this.thumbnail,
  });

  @override
  State<User_video> createState() => _User_videoState();
}

class _User_videoState extends State<User_video> {
  late VideoPlayerController _controller;
  late ValueNotifier<Duration> _currentPositionNotifier;
  bool _showControls = true;
  bool _isFullscreen = false;
  String username='';
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
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
  double _sliderValue = 0.0; // Current value of the slider
  Duration _duration = Duration();
  List<String> subscriber=[];
  bool isliked=false;
  bool isdisliked=false;
  List<String> dislikeduser=[];
  Future<void> fetchdislike() async{
    final user=_auth.currentUser;
    try{
      DocumentSnapshot documentSnapshot=await _firestore
          .collection('dislikes')
          .doc('dislikes')
          .get();
      if(documentSnapshot.exists){
        dynamic data=documentSnapshot.data();
        if(data!=null){
          List<dynamic> posts=(data['dislike'] as List?)??[];
          setState(() {
            dislikeduser=posts.map((post) => post['userid'].toString()).toList();
          });
        }
      }
    }catch(e){
      print('dislike error $e');
    }
    print('userid disliked$likeduser');
  }
  Future<void> isuserdisliked() async {
    await fetchdislike();
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        isdisliked = dislikeduser.contains(user.uid);
      });
    }
  }
  Future<void> increaseCount() async {
    await isuserliked();
    final user = _auth.currentUser;
    if (user != null) {
      if(isliked){
        await _firestore.collection('Likes').doc('likes').set({
          'like': FieldValue.arrayUnion([
            {'userid': user.uid}
          ])
        },SetOptions(merge: true));
      }
      if(!isliked){
        await _firestore.collection('Likes').doc('likes').set({
          'like': FieldValue.arrayRemove([
            {'userid': user.uid}
          ])
        },SetOptions(merge: true));
      }
    } else {
      print('User is not authenticated.');
      // Handle the case where the user is not authenticated.
    }
  }
  List<String> likeduser=[];
  Future<void> fetchlike() async{
    final user=_auth.currentUser;
    try{
      DocumentSnapshot documentSnapshot=await _firestore
          .collection('Likes')
          .doc('likes')
          .get();
      if(documentSnapshot.exists){
        dynamic data=documentSnapshot.data();
        if(data!=null){
          List<dynamic> posts=(data['like'] as List?)??[];
          setState(() {
            likeduser=posts.map((post) => post['userid'].toString()).toList();
          });
        }
      }
    }catch(e){
      print('like error $e');
    }
    print('userid $likeduser');
  }
  Future<void> isuserliked() async {
    await fetchlike();
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        isliked = likeduser.contains(user.uid);
      });
    }
  }

  Future<void>fetchdataperiodically()async{
    Timer.periodic(Duration(seconds: 2), (timer) {
      fetchlike();
      fetchusername();
      fetchprofilepic();
      fetchusername();
      isuserliked();
      isuserdisliked();
      fetchdislike();
    });
  }
  @override
  void initState() {
    super.initState();
    fetchusername();
    fetchdataperiodically();
    fetchsubscriber();
    fetchprofilepic();
    fetchlike();
    isuserliked();
    isuserdisliked();
    fetchdislike();
    print('is liked $isliked');
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
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(profilepicurl),
                ),
                SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 15),),
                    SizedBox(height: 5,),
                    if(subscriber.length==0)
                      Text('No Subscriber',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 12),),
                    if(subscriber.length==1)
                      Text('${subscriber.length} Subscriber',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 12),),
                    if(subscriber.length>1)
                      Text('${subscriber.length} Subscriber',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.w300,fontSize: 12),),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isliked?IconButton(onPressed: ()async{
                  final user=_auth.currentUser;
                  print('liked ');
                  await _firestore.collection('Likes').doc('likes').set({
                    'like': FieldValue.arrayRemove([
                      {'userid': user!.uid}
                    ])
                  },SetOptions(merge: true));
                }, icon: Icon(CupertinoIcons.hand_thumbsup_fill,color: Colors.white,)):
                IconButton(onPressed: ()async{
                  final user=_auth.currentUser;
                  print('unliked ');
                  await _firestore.collection('dislikes').doc('dislikes').set({
                    'dislike': FieldValue.arrayRemove([
                      {'userid': user!.uid}
                    ])
                  },SetOptions(merge: true));
                  await _firestore.collection('Likes').doc('likes').set({
                    'like': FieldValue.arrayUnion([
                      {'userid': user!.uid}
                    ])
                  },SetOptions(merge: true));
                }, icon: Icon(CupertinoIcons.hand_thumbsup,color: Colors.white,)),

                if(likeduser.length==1)
                  Text('${likeduser.length}',style: TextStyle(color: Colors.white),),
                if(likeduser.length>1)
                  Text('${likeduser.length}',style: TextStyle(color: Colors.white),),
                SizedBox(
                  width: 20,
                ),
                isdisliked?IconButton(onPressed: ()async{
                  final user=_auth.currentUser;
                  print('liked ');
                  await _firestore.collection('dislikes').doc('dislikes').set({
                    'dislike': FieldValue.arrayRemove([
                      {'userid': user!.uid}
                    ])
                  },SetOptions(merge: true));
                }, icon: Icon(CupertinoIcons.hand_thumbsdown_fill,color: Colors.white,)):
                IconButton(onPressed: ()async{
                  final user=_auth.currentUser;
                  print('unliked ');
                  await _firestore.collection('Likes').doc('likes').set({
                    'like': FieldValue.arrayRemove([
                      {'userid': user!.uid}
                    ])
                  },SetOptions(merge: true));
                  await _firestore.collection('dislikes').doc('dislikes').set({
                    'dislike': FieldValue.arrayUnion([
                      {'userid': user!.uid}
                    ])
                  },SetOptions(merge: true));

                }, icon: Icon(CupertinoIcons.hand_thumbsdown,color: Colors.white,)),
                if(dislikeduser.length==1)
                  Text('${dislikeduser.length}',style: TextStyle(color: Colors.white),),
                if(dislikeduser.length>1)
                  Text('${dislikeduser.length}',style: TextStyle(color: Colors.white),)
              ],
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
