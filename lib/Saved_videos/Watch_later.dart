import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelprowess/Pages/searched_userpage.dart';
import 'package:pixelprowess/Video%20Card/VideoCard.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer_image/shimmer_image.dart';
import 'package:timeago/timeago.dart'as timeago;
class Watch_Later extends StatefulWidget {
  const Watch_Later({Key? key}) : super(key: key);

  @override
  State<Watch_Later> createState() => _Watch_LaterState();
}

class _Watch_LaterState extends State<Watch_Later> {
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  List<String> videoid=[];
  Future<void> fetchvideoid() async {
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
            videoid =posts.map((post) => post['Video ID'].toString()).toList();
          });
        }
      }
      print('saved vids homepage $videoid');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }
  }
  List<String> thumbnail=[];
  String thumbnails='';
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
    print(' watch later thumbnail homepage $thumbnail');
  }
  String Uploaduids='';
  bool _loadeduseruid=false;
  List<String>uploadeduseruid=[];
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
    print(' watch later UIDs homepage $uploadeduseruid');
  }
  List<String> videos=[];
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
    print(' videos fetched db $videos , length ${videos.length}');
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
  List<String>captions=[];
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
  List<DateTime>uploaddate=[];
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
  List<String> subscriber=[];
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
      print('following homepage $subscriber');
    } catch (e) {
      print('Error fetching followers fetchfollowers: $e');
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchvideoid();
    fetchthumbnail();
    fetchuploadeduseruid();
    fetchvideo();
    fetchviews();
    fetchsubscriber();
    fetchusernames();
    fetchuploaddate();
    fetchdp();
    fetchcaptions();
    fetchVideoLengths();
    fetchthumbnail();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Text('Watch Later',style: GoogleFonts.abyssinicaSil(color: Colors.white,fontWeight: FontWeight.bold),),
            SizedBox(
              width: 10,),
            Icon(Icons.watch_later,color: Colors.white,)
          ],
        ),
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(CupertinoIcons.chevron_back,color: Colors.white,)),
      ),
      body: SingleChildScrollView(
        child: _loadeddatetime && _loadedviews &&_loadedviews &&_loadedcaptions &&_loadedthumbnail
            &&_loadeduseruid &&loadedusernames &&_loadeddp?Column(
          children: [
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
                            print(' clicked $i and Video fetched ${videos[i]}');
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
                              highlightColor: Colors.red,
                              imageError: 'Failed To Load Image',
                              image: thumbnail[i],
                            ),
                          )
                      ),
                      // if(videoLengths.isNotEmpty)
                      //   Positioned(
                      //     bottom: 5,
                      //     right: 5,
                      //     child: Text(
                      //       '${videoLengths[i].toString().split('.').first}',
                      //       // Converts Duration to string and removes milliseconds
                      //       style: TextStyle(
                      //         color: Colors.white,
                      //         fontSize: 12,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ),
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
                      InkWell(
                          onTap: (){
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
                          },
                          child: Text(captions[i],style: GoogleFonts.arbutusSlab(color: Colors.white,fontSize: 15),)),
                      Spacer(),
                      IconButton(onPressed: (){}, icon: Icon(Icons.more_vert,color: Colors.white,))
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
                      InkWell(
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SearchedUser(UID: uploadeduseruid[i]),));
                          },
                          child: Text('${USernames[i]}', style: TextStyle(color: Colors.grey, fontSize: 12))),
                      SizedBox(
                        width: 10,
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
                        width: 5,
                      ),
                      Text(
                        '${timeago.format(uploaddate[i], locale: 'en_long', allowFromNow: true)}', // Format the upload date
                        style: TextStyle(color: Colors.grey,fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
          ],
        ):Column(
          children: [
            SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  backgroundColor: Colors.red,
                  color: Colors.white,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
