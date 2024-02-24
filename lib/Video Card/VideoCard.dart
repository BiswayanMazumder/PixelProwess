import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelprowess/Pages/searched_userpage.dart';
import 'package:shimmer_image/shimmer_image.dart';
import 'package:typing_animation/typing_animation_code.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart'as timeago;
import 'package:translator/translator.dart';
import 'package:http/http.dart' as http;
import 'package:like_button/like_button.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
    await _firestore.collection('Subscriptions').doc(user!.uid).update({
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
  List<String> videourls=[];
  bool issaved=false;
  bool isprivate=false;
  Future<void> fetchisprivate() async {
    final user = _auth.currentUser;
    try {
      final docsnap=await _firestore.collection('User Details').doc(widget.UID).get();
      if(docsnap.exists){
        setState(() {
          isprivate=docsnap.data()?['channel private'];
        });
      }
    } catch (e) {
      print('Error fetching followers privacy: $e');
    }
    print('is private $isprivate');
  }
  Future<void> fetchvideourls() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Users Saved Videos')
          .doc(user!.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Saved Video Details'] as List?) ?? [];
          setState(() {
            videourls =posts.map((post) => post['Video Link'].toString()).toList();
          });
        }
      }
      if(videourls.contains(widget.viddeourl)){
        setState(() {
          issaved=true;
        });
      }
      print('saved homepage $videourls');
      print('saved video $issaved');
    } catch (e) {
      print('Error fetching followers videos: $e');
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
  List<String> subscribers=[];
  List<String> videos=[];
  List<String> captions=[];
  List<String> thumbnail=[];
  List<DateTime> uploaddate=[];
  List<String> videoid=[];
  Future<void> fetchvideoid() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Global VIDs')
          .doc('VIDs')
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['VID'] as List?) ?? [];
          setState(() {
            videoid =posts.map((post) => post.toString()).toList();
          });
        }
        for(String vids in videoid){
          if(vids==widget.VideoID){
            videoid.remove(vids);
          }
        }
      }
      print('vids homepage $videoid');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }
  }
  String thumbnails='';
  List<String> uploadeduseruid=[];
  bool _loadedthumbnail=false;
  Future<void> fetchthumbnail() async {
    final user = _auth.currentUser;
    await fetchvideoid();
    for(String vids in videoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          thumbnails=docsnap.data()?['Thumbnail Link'];
          thumbnail.add(thumbnails);
          _loadedthumbnail=true;
        });
      }
    }
    print(' thumbnail homepage $thumbnail');
  }
  String Uploaduids='';
  bool _loadeduseruid=false;
  Future<void> fetchuploadeduseruid() async {
    final user = _auth.currentUser;
    await fetchvideoid();
    List<String> newUploadedUserIds = [];
    for (String vids in videoid) {
      final docsnap = await _firestore.collection('Global Post').doc(vids).get();
      if (docsnap.exists) {
        newUploadedUserIds.add(docsnap.data()?['Uploaded UID']);
      }
    }
    setState(() {
      uploadeduseruid = List.from(newUploadedUserIds); // Update uploadeduseruid with newUploadedUserIds
      _loadeduseruid=true;
    });
    print(' UIDs homepage $uploadeduseruid');
  }

  int usernameIndex = 0;
  String _profileurl='';
  List<String>Profileurls=[];
  String usernames='';
  List<String> USernames=[];
  bool loadedusernames=false;
  Future<void> fetchusernames() async {
    final user = _auth.currentUser;
    await fetchuploadeduseruid();
    List<String> newusernames = []; // Create a new list to store usernames
    try {
      List<String> uploadedUserIdsCopy = List.from(uploadeduseruid); // Make a copy of the list
      for (String vids in uploadedUserIdsCopy) {
        final docsnap = await _firestore.collection('User Details').doc(vids).get();
        if (docsnap.exists) {
          setState(() {
            usernames = docsnap.data()?['Username'];
            newusernames.add(usernames); // Add the username to the new list
            loadedusernames=true;
          });
        }
      }
      setState(() {
        USernames.addAll(newusernames); // Add all usernames to the USernames list after the loop
      });
    } catch (e) {
      print('username error $e');
    }
    print(' username homepage $USernames');
  }
  bool _loadeddp=false;
  Future<void> fetchdp() async {
    final user = _auth.currentUser;
    await fetchuploadeduseruid();
    List<String> uploadedUserIdsCopy = List.from(uploadeduseruid); // Make a copy of the list
    for (String vids in uploadedUserIdsCopy) {
      final docsnap = await _firestore.collection('User Profile Pictures').doc(vids).get();
      if (docsnap.exists) {
        setState(() {
          _profileurl=docsnap.data()?['Profile Pic'];
          Profileurls.add(_profileurl);
          _loadeddp=true;
        });
      }
      else{
        setState(() {
          Profileurls.add('https://img.freepik.com/free-vector/businessman-character-avatar-isolated_'
              '24877-60111.jpg?w=740&t=st=1707932498~exp=1707933098~hmac=63fef39a600650c9d8f0c064778238717'
              'd1a8298782da830e68ce7818054ed6f');
        });
      }
    }
    print(' dp homepage $Profileurls');
  }
  String Caption='';
  bool _loadedcaptions=false;
  Future<void> fetchcaptions() async {
    final user = _auth.currentUser;
    await fetchvideoid();
    for(String vids in videoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          Caption=docsnap.data()?['Caption'];
          captions.add(Caption);
          _loadedcaptions=true;
        });
      }
    }
    print(' captions homepage $captions');
  }
  DateTime Uploaddate = DateTime.now();
  bool _loadeddatetime=false;
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
          _loadeddatetime=true;
        });
      }
    }
    print(' upload date homepage $uploaddate');
  }
  String Videolinks='';
  Future<void> fetchvideo() async {
    await fetchvideoid();
    List<String> newUploadedUserIds = [];
    for(String vids in videoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        newUploadedUserIds.add(docsnap.data()?['Video Link']);
      }
    }
    setState(() {
      videos=List.from(newUploadedUserIds);
    });
    print(' videos $videos');
  }
  List<Duration> videoLengths = [];
  bool _loadedvideolength=false;
  Future<void> fetchVideoLengths() async {
    await fetchvideo();
    for (int i = 0; i < videos.length; i++) {
      try {
        VideoPlayerController controller = VideoPlayerController.network(videos[i]);
        await controller.initialize();
        setState(() {
          videoLengths.add(controller.value.duration);
          _loadedvideolength=true;
        });
        await controller.dispose();
      } catch (e) {
        print('Error fetching video length: $e');
      }
    }
    print('Video Length $videoLengths');
  }
  int views_video=0;
  List<int> views=[];
  int fetchedviews=0;
  bool _loadedviews=false;
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
          _loadedviews=true;
        });
      }
    }
    print(' Views got homepage$views');
  }
  Future<void> fetchsubscribers() async {
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
            subscribers =
                posts.map((post) => post['SubscriberUid'].toString()).toList();
          });
        }
      }
      print('following homepage $subscriber');
    } catch (e) {
      print('Error fetching followers fetchfollowers: $e');
    }

  }
  // Future<void> fetchvideoids() async {
  //   final user = _auth.currentUser;
  //   try {
  //     DocumentSnapshot documentSnapshot = await _firestore
  //         .collection('User Uploaded Videos ID')
  //         .doc(widget.UID)
  //         .get();
  //
  //     if (documentSnapshot.exists) {
  //       dynamic data = documentSnapshot.data();
  //       if (data != null) {
  //         List<dynamic> posts = (data['VID'] as List?) ?? [];
  //         setState(() {
  //           videoid =posts.map((post) => post.toString()).toList();
  //         });
  //       }
  //       for(String vids in videoid){
  //         if(vids==widget.VideoID){
  //           videoid.remove(vids);
  //         }
  //       }
  //     }
  //     print('vids homepage $videoid');
  //   } catch (e) {
  //     print('Error fetching followers videos: $e');
  //   }
  // }
  List<String> queueuids=[];
  Future<void> fetchqueueuploadeduseruid() async {
    final user = _auth.currentUser;
    await fetchqueuevideoid();
    List<String> newUploadedUserIds = [];
    for (String vids in queueuvideoid) {
      final docsnap = await _firestore.collection('Global Post').doc(vids).get();
      if (docsnap.exists) {
        newUploadedUserIds.add(docsnap.data()?['Uploaded UID']);
      }
    }
    setState(() {
      queueuids = List.from(newUploadedUserIds); // Update uploadeduseruid with newUploadedUserIds
      _loadeduseruid=true;
    });
    print(' UIDs queue $queueuids');
  }
  List<String> queueuvideoid=[];
  Future<void> fetchqueuevideoid() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Queue')
          .doc(user!.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['Queue UIDs'] as List?) ?? [];
          setState(() {
            queueuvideoid =posts.map((post) => post.toString()).toList();
          });
        }
      }
      print('queue homepage $queueuvideoid');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }
  }
  String _queuedp='';
  List<String> queuedp=[];
  Future<void> fetchqueuedp() async {
    final user = _auth.currentUser;
    await fetchqueueuploadeduseruid();
    List<String> uploadedUserIdsCopy = List.from(queueuids); // Make a copy of the list
    for (String vids in uploadedUserIdsCopy) {
      final docsnap = await _firestore.collection('User Profile Pictures').doc(vids).get();
      if (docsnap.exists) {
        setState(() {
          _queuedp=docsnap.data()?['Profile Pic'];
          queuedp.add(_queuedp);
          _loadeddp=true;
        });
      }
      else{
        setState(() {
          queuedp.add('https://img.freepik.com/free-vector/businessman-character-avatar-isolated_'
              '24877-60111.jpg?w=740&t=st=1707932498~exp=1707933098~hmac=63fef39a600650c9d8f0c064778238717'
              'd1a8298782da830e68ce7818054ed6f');
        });
      }
    }
    print(' dp queue $queuedp');
  }
  String queueCaption='';
  List<String> queuecaptions=[];
  Future<void> fetchqueuecaptions() async {
    final user = _auth.currentUser;
    await fetchqueuevideoid();
    for(String vids in queueuvideoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          queueCaption=docsnap.data()?['Caption'];
          queuecaptions.add(queueCaption);
          _loadedcaptions=true;
        });
      }
    }
    print(' captions queue $queuecaptions');
  }
  String queueusernames='';
  List<String> Queueusernames=[];
  String _queueusername='';
  Future<void> fetchqueueusernames() async {
    final user = _auth.currentUser;
    await fetchqueueuploadeduseruid();
    List<String> newusernames = []; // Create a new list to store usernames
    try {
      List<String> uploadedUserIdsCopy = List.from(queueuids); // Make a copy of the list
      for (String vids in uploadedUserIdsCopy) {
        final docsnap = await _firestore.collection('User Details').doc(vids).get();
        if (docsnap.exists) {
          setState(() {
            queueusernames = docsnap.data()?['Username'];
            newusernames.add(queueusernames); // Add the username to the new list
            loadedusernames=true;
          });
        }
      }
      setState(() {
        Queueusernames.addAll(newusernames); // Add all usernames to the USernames list after the loop
      });
    } catch (e) {
      print('username error $e');
    }
    print(' username queue $Queueusernames');
  }
  List<int> queueviews=[];
  int fetchedqueueviews=0;
  Future<void> fetchqueueviews() async{
    await fetchvideoid();
    for (String vids in queueuvideoid) {
      final docsnap =
      await _firestore.collection('Global Post').doc(vids).get();
      if (docsnap.exists) {
        final fetchviews = docsnap.data()?['Views'];
        setState(() {
          fetchedqueueviews = fetchviews;
          queueviews.add(fetchedqueueviews);
          _loadedviews=true;
        });
      }
    }
    print(' Views got queue$queueviews');
  }
  DateTime queueUploaddate = DateTime.now();
  List<DateTime>queueuploaddate=[];
  Future<void> fetcqueuehuploaddate() async {
    await fetchqueuevideoid();
    for (String vids in queueuvideoid) {
      final docsnap =
      await _firestore.collection('Global Post').doc(vids).get();
      if (docsnap.exists) {
        final timestamp = docsnap.data()?['Uploaded At'] as Timestamp;
        final uploadDateTime = timestamp.toDate(); // Convert Firestore Timestamp to DateTime
        setState(() {
          queueUploaddate = uploadDateTime;
          queueuploaddate.add(queueUploaddate);
          _loadeddatetime=true;
        });
      }
    }
    print(' upload date queue $queueuploaddate');
  }
  String queueVideolinks='';
  List<String> queuevideos=[];
  Future<void> fetchqueuevideo() async {
    await fetchqueuevideoid();
    List<String> newUploadedUserIds = [];
    for(String vids in queueuvideoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        newUploadedUserIds.add(docsnap.data()?['Video Link']);
      }
    }
    setState(() {
      queuevideos=List.from(newUploadedUserIds);
    });
    print(' queue videos $queuevideos');
  }
  String queuethumbnails='';
  List<String> Queuethumbnails=[];
  Future<void> fetchqueuethumbnail() async {
    final user = _auth.currentUser;
    await fetchqueuevideoid();
    for(String vids in queueuvideoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          queuethumbnails=docsnap.data()?['Thumbnail Link'];
          Queuethumbnails.add(queuethumbnails);
          _loadedthumbnail=true;
        });
      }
    }
    print(' thumbnail queue $Queuethumbnails');
  }
  Future<void> fetchData() async {
    await fetchlikedusers();
    await fetchvideourls();
    await fetchdislikedusers();
    await fetchsubscriber();
    await fetchisprivate();
    await fetchqueuevideoid();
    // await fetchvideoids();
  }
  bool showqueue=true;
  @override
  void initState() {
    super.initState();
    fetchqueueviews();
    fetchqueuevideoid();
    fetchqueuethumbnail();
    fetchqueuevideo();
    fetcqueuehuploaddate();
    fetchqueueusernames();
    fetchqueueuploadeduseruid();
    fetchlikedusers();
    fetchvideoid();
    fetchqueuecaptions();
    fetchisprivate();
    fetchcaptions();
    fetchthumbnail();
    // fetchvideoids();
    fetchuploaddate();
    fetchviews();
    fetchqueuedp();
    fetchuploadeduseruid();
    fetchqueuevideoid();
    fetchvideourls();
    fetchdp();
    fetchusernames();
    fetchvideo();
    fetchsubscriber();
    // fetchusernames();
    fetchVideoLengths();
    fetchdislikedusers();
    fetchsubscribers();
    fetchUserDataPeriodically();
    fetchsubscriber();
    print('VIdeo url ${widget.viddeourl}');
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
            ):Center(
              child:Image.network(widget.thumbnail,),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text(widget.caption,style: GoogleFonts.arbutusSlab(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
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
                  'Uploaded ${timeago.format(widget.uploaddate, locale: 'en_long', allowFromNow: true)}', // Format the upload date
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: widget.UID),));
                      },
                      child: Row(
                        children: [
                          Text(widget.username,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,
                              fontSize: 12),),
                          SizedBox(
                            width: 12,
                          ),
                          if(subscriber.length>=1000)
                            Icon(Icons.verified,color: Colors.blueAccent,size: 18,)
                        ],
                      ),
                    ),
                    widget.UID==user!.uid?Row(
                      children: [
                        if(subscriber.length<=1)
                          Text('${subscriber.length} Subscriber',style: TextStyle(color: Colors.grey,fontSize: 12,fontWeight: FontWeight.bold),),
                        if(subscriber.length>1)
                          Text('${subscriber.length} Subscribers',style: TextStyle(color: Colors.grey,fontSize: 12,fontWeight: FontWeight.bold),),
                      ],
                    ):isprivate?Container():Row(
                      children: [
                        if(subscriber.length<=1)
                          Text('${subscriber.length} Subscriber',style: TextStyle(color: Colors.grey,fontSize: 12,fontWeight: FontWeight.bold),),
                        if(subscriber.length>1)
                          Text('${subscriber.length} Subscribers',style: TextStyle(color: Colors.grey,fontSize: 12,fontWeight: FontWeight.bold),),
                      ],
                    )
                  ],
                ),
                SizedBox(
                  width: 20,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle, // Use BoxShape.rectangle for an oval-like shape
                      borderRadius: BorderRadius.circular(50), // Adjust the border radius to get the desired oval shape
                      color: Colors.grey[900], // Optional: set the background color
                    ),
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if(isliked)
                          IconButton(onPressed: ()async{
                            final user=_auth.currentUser;
                            await _firestore.collection('Liked Videos').doc(widget.VideoID).update({
                              'UIDs':FieldValue.arrayRemove([
                                user!.uid
                              ])
                            });
                            fetchlikedusers();
                          }, icon: Icon(CupertinoIcons.hand_thumbsup_fill,color: Colors.white,)),
                        if(!isliked)
                          IconButton(onPressed: ()async{
                            final user=_auth.currentUser;
                            await _firestore.collection('Disliked Videos').doc(widget.VideoID).update({
                              'UIDs':FieldValue.arrayRemove([
                                user!.uid
                              ])
                            });
                            Likeduser();
                            fetchlikedusers();
                          }, icon: Icon(CupertinoIcons.hand_thumbsup,color: Colors.white,)),
                        Text('${likedusers.length}',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                        SizedBox(
                          width: 50,
                        ),
                        if(isdisliked)
                          IconButton(onPressed: ()async{
                            final user=_auth.currentUser;
                            await _firestore.collection('Disliked Videos').doc(widget.VideoID).update({
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
                            await _firestore.collection('Liked Videos').doc(widget.VideoID).update({
                              'UIDs':FieldValue.arrayRemove([
                                user!.uid
                              ])
                            });
                            fetchlikedusers();
                          }, icon: Icon(CupertinoIcons.hand_thumbsdown,color: Colors.white,)),
                        Text('${dislikedusers.length}',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  if(!issaved)
                    IconButton(onPressed: ()async{
                      await _firestore.collection('Users Saved Videos').doc(user!.uid).set(
                          {
                            'Saved Video Details':FieldValue.arrayUnion([
                              {
                                'Thumbnail': widget.thumbnail,
                                'Video Link':widget.viddeourl,
                                'User ID':widget.UID,
                                'Profile Picture':widget.profilepicurl,
                                'Username':widget.username,
                                'Video ID':widget.VideoID,
                              }
                            ])
                          },SetOptions(merge: true));
                    }, icon: Icon(Icons.watch_later,color: Colors.white,)),
                  if(issaved)
                    IconButton(onPressed: ()async{
                      await _firestore.collection('Users Saved Videos').doc(user!.uid).update(
                          {
                            'Saved Video Details':FieldValue.arrayRemove([
                              {
                                'Thumbnail': widget.thumbnail,
                                'Video Link':widget.viddeourl,
                                'User ID':widget.UID,
                                'Profile Picture':widget.profilepicurl,
                                'Username':widget.username,
                                'Video ID':widget.VideoID,
                              }
                            ])
                          });
                      setState(() {
                        issaved=false;
                      });
                    }, icon: Icon(Icons.delete_rounded,color: Colors.red,)),
                ],
              ),
            ),
            SizedBox(
              height: 45,
            ),
            queueuvideoid.length>0?Column(
              children: [
                Container(
                  height: 80,
                  width: 350,
                  color: Colors.grey.shade900,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'Added To Queue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            showqueue = !showqueue;
                          });
                          print('showqueue $showqueue');
                        },
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                      )
                    ],
                  ),
                ),
                if (captions.isEmpty) // Check if captions list is empty
                  Container(
                      height: 80,
                      width: 350,
                      color: Colors.grey.withOpacity(0.8),
                      child: Center(
                          child: CircularProgressIndicator())) // Display circular progress indicator
                else if (showqueue) // Check if showqueue is true
                  Container(
                    height: 300,
                    width: 350,
                    color: Colors.grey.withOpacity(0.8),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int a = 0; a < queueuvideoid.length; a++)
                            Row(
                              children: [
                                Container(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ProgressiveImage(
                                      image: Queuethumbnails[a],
                                      height: 80,
                                      width: 80,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      queuecaptions[a],
                                      style: GoogleFonts.abyssinicaSil(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      Queueusernames[a],
                                      style: GoogleFonts.abyssinicaSil(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${queueviews[a]}',
                                          style: GoogleFonts.abyssinicaSil(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          timeago.format(
                                            queueuploaddate[a],
                                            locale: 'en_long',
                                            allowFromNow: true,
                                          ), // Format the upload date
                                          style: GoogleFonts.abyssinicaSil(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            )
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  height: 20,
                )
              ],
            ):Container(),
            SizedBox(
              height: 20,
            ),
            for(int i=0;i<captions.length;i++)
              Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Stack(
                    children: [
                      InkWell(
                          onTap: ()async{
                            Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPage(caption: captions[i],
                                uploaddate: uploaddate[i],
                                Index: i,
                                VideoID:  videoid[i],
                                viddeourl: videos[i],
                                views: views[i],
                                thumbnail: thumbnail[i],
                                username: USernames[i],
                                UID: uploadeduseruid[i],
                                profilepicurl: Profileurls[i]),));
                            final docsnap=await _firestore.collection('Global Post').doc(videoid[i]).get();
                            if(docsnap.exists){
                              views_video=docsnap.data()?['Views'];
                            }
                            await _firestore.collection('Global Post').doc(videoid[i]).update(
                                {
                                  'Views':views_video+1
                                });
                            print('index $i');
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                border:Border.all(
                                    color: Colors.white
                                )
                            ),
                            child: ProgressiveImage(
                              height: 300,
                              width: 1280,
                              baseColor: Colors.grey.shade900,
                              highlightColor: Colors.white,
                              imageError: 'Failed To Load Image',
                              image: thumbnail[i],
                            ),
                          )
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
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                      ),
                      InkWell(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: uploadeduseruid[i]),));
                        },
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(Profileurls[i]),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(captions[i],style: GoogleFonts.arbutusSlab(color: Colors.white,fontSize: 15),),
                    ],
                  ),
                  SizedBox(
                    height: 1,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                      ),
                      //[Biswayan Mazumder, Biswayan Mazumder, Biswayan Mazumder, CodeZify-Flutter Developer , CodeZify-Flutter Developer , CodeZify-Flutter Developer , Biswayan Mazumder]
                      //[0LrVRSIKdRVgAWWVt9Qhv8PguJG3, 0LrVRSIKdRVgAWWVt9Qhv8PguJG3, 0LrVRSIKdRVgAWWVt9Qhv8PguJG3, h0YLztPREjeQeV2ELA9iFu0qGNa2, h0YLztPREjeQeV2ELA9iFu0qGNa2, h0YLztPREjeQeV2ELA9iFu0qGNa2, 0LrVRSIKdRVgAWWVt9Qhv8PguJG3]
                      Text('${USernames[i]}', style: TextStyle(color: Colors.grey, fontSize: 12)),

                      SizedBox(
                        width: 20,
                      ),
                      if (views[i] == 0)
                        Text('No Views', style: TextStyle(color: Colors.grey,fontSize: 12)),
                      if (views[i] == 1)
                        Text('${views[i]} View', style: TextStyle(color: Colors.grey,fontSize: 12)),
                      if (views[i] > 1 && views[i]<=999)
                        Text('${views[i]} Views', style: TextStyle(color: Colors.grey,fontSize: 12)),
                      if (views[i] >= 10000 && views[i]<=100000)
                        Text('${(views[i] ~/ 1000)}K Views', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      if (views[i] > 100000 && views[i]<=9999999)
                        Text('${(views[i] ~/ 10000)}M Views', style: TextStyle(color: Colors.grey, fontSize: 12)),

                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        timeago.format(uploaddate[i], locale: 'en_long', allowFromNow: true), // Format the upload date
                        style: TextStyle(color: Colors.grey,fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
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
