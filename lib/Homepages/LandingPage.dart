import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelprowess/Homepages/Accountpage.dart';
import 'package:pixelprowess/Pages/searched_userpage.dart';
import 'package:pixelprowess/Video%20Card/VideoCard.dart';
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
      }
      print('vids homepage $videoid');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }
  }
  String thumbnails='';
  List<String> uploadeduseruid=[];
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
  String Uploaduids='';
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
    });
    print(' UIDs homepage $uploadeduseruid');
  }

  int usernameIndex = 0;
  String _profileurl='';
  List<String>Profileurls=[];
  String usernames='';
  List<String> USernames=[];
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
    print(' captions homepage $captions');
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
    fetchcaptions();
    fetchthumbnail();
    fetchuploaddate();
    fetchviews();
    fetchuploadeduseruid();
    fetchdp();
    fetchusernames();
    fetchvideo();
    fetchsubscriber();
    // fetchusernames();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          Row(
            children: [
              IconButton(onPressed: (){}, icon: AnimatedIcon(icon: AnimatedIcons.ellipsis_search, progress: kAlwaysCompleteAnimation,color: Colors.white,))
            ],
          )
        ],
        title: Row(
          children: [
            Image.network('https://emkldzxxityxmjkxiggw.supabase.co/storage/v1/object/public/PixelProwess/_3983829c-0a3e-4628-9b05-4eec15080e79.jpg',
              height: 50,
              width: 50,
            ),
            SizedBox(
              width: 10,
            ),
            Text('𝓟𝓲𝔁𝓮𝓵𝓟𝓻𝓸𝔀𝓮𝓼𝓼',style: TextStyle(color: Colors.white),)
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                            child: Image.network(
                              thumbnail[i],
                            ),
                          )
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
                      Text(captions[i],style: GoogleFonts.abhayaLibre(color: Colors.white,fontSize: 18),),
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
}
