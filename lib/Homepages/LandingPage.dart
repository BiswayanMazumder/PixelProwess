import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pixelprowess/Homepages/Accountpage.dart';
import 'package:timeago/timeago.dart'as timeago;
import 'package:video_player/video_player.dart';
class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
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
      }
      print('vids homepage $videoid');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }
  }
  String thumbnails='';
  List<String> uploadeduseruid=[];
  String Uploaduids='';
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
    print(' thumbnail homepage $thumbnail');
  }
  Future<void> fetchuploadeduseruid() async {
    final user = _auth.currentUser;
    await fetchvideoid();
    for(String vids in videoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          Uploaduids=docsnap.data()?['Uploaded UID'];
          uploadeduseruid.add(Uploaduids);
        });
      }
    }
    print(' Uids homepage $uploadeduseruid');
  }
  String _profileurl='';
  List<String>Profileurls=[];
  String usernames='';
  List<String> USernames=[];
  Future<void> fetchusernames() async {
    final user = _auth.currentUser;
    await fetchuploadeduseruid();
    for(String vids in uploadeduseruid){
      final docsnap=await _firestore.collection('User Details').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          usernames=docsnap.data()?['Username'];
          USernames.add(usernames);
        });
      }
    }
    print(' username homepage $USernames');
  }
  Future<void> fetchdp() async {
    final user = _auth.currentUser;
    await fetchuploadeduseruid();
    for(String vids in uploadeduseruid){
      final docsnap=await _firestore.collection('User Profile Pictures').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          _profileurl=docsnap.data()?['Profile Pic'];
          Profileurls.add(_profileurl);
        });
      }
    }
    print(' dp homepage $Profileurls');
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
    print(' upload date homepage $uploaddate');
  }
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
  List<Duration> videoLengths = [];
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
  int views_video=0;
  List<int> views=[];
  int fetchedviews=0;
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
    print(' Views got homepage$views');
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchvideoid();
    fetchcaptions();
    fetchthumbnail();
    fetchVideoLengths();
    fetchuploaddate();
    fetchviews();
    fetchuploadeduseruid();
    fetchdp();
    fetchusernames();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for(int i=0;i<thumbnail.length;i++)
              Column(
                children: [
                  Stack(
                    children: [
                      InkWell(
                        onTap: ()async{
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Accountpage(),));
                          print('clicked video ${videos[i]}');
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
                        child: Image.network(
                          thumbnail[i],
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
                        backgroundImage: NetworkImage(Profileurls[i]),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(captions[i],style: TextStyle(color: Colors.white,fontSize: 18),),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                      ),
                      Text('${USernames[i]}', style: TextStyle(color: Colors.grey,fontSize: 12)),
                      SizedBox(
                        width: 20,
                      ),
                      if (views[i] == 0)
                        Text('No Views', style: TextStyle(color: Colors.grey,fontSize: 12)),
                      if (views[i] == 1)
                        Text('${views[i]} View', style: TextStyle(color: Colors.grey,fontSize: 12)),
                      if (views[i] > 1)
                        Text('${views[i]} Views', style: TextStyle(color: Colors.grey,fontSize: 12)),
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        timeago.format(uploaddate[i], locale: 'en_short', allowFromNow: true), // Format the upload date
                        style: TextStyle(color: Colors.grey,fontSize: 12),
                      ),
                    ],
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
