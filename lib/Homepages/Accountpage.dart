import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelprowess/Pages/test_video_if.dart';
import 'package:pixelprowess/Pages/upload_page.dart';
import 'package:pixelprowess/Playlists/playlist_homepage.dart';
import 'package:pixelprowess/Saved_videos/Watch_later.dart';
import 'package:pixelprowess/Video%20Card/VideoCard.dart';
import 'package:pixelprowess/main.dart';
import 'package:shimmer_image/shimmer_image.dart';
import 'package:timeago/timeago.dart'as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelprowess/Pages/editprofile.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
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
  bool iscommunity=false;
  bool isabout=false;
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
  bool _upload=true;
  Future<void> _pickImage() async {
    final user = _auth.currentUser;
    if (user!.emailVerified) {
      final pickedFile =
      await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _upload = false;
        });
      }
    } else {
      final pickedFile =
      await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _upload = false;
        });
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
          .collection('Subscribers')
          .doc(user?.uid)
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

  }
  List<String> subscriber=[];
  List<String> videos=[];
  List<String>captions=[];
  List<String> thumbnail=[];
  TextEditingController _playlistController=TextEditingController();
  List<DateTime> uploaddate=[];
  List<String>videoid=[];
  Future<void> fetchvideoid() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('User Uploaded Videos ID')
          .doc(user?.uid)
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
    print(' thumbnail $thumbnail');
  }
  String Caption='';
  bool _loadedcaption=false;
  Future<void> fetchcaptions() async {
    final user = _auth.currentUser;
    await fetchvideoid();
    for(String vids in videoid){
      final docsnap=await _firestore.collection('Global Post').doc(vids).get();
      if(docsnap.exists){
        setState(() {
          Caption=docsnap.data()?['Caption'];
          captions.add(Caption);
          _loadedcaption=true;
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
  TextEditingController _communityController=TextEditingController();
  DateTime Uploaddate = DateTime.now();
  bool _loadeduploaddate=false;
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
    Timer.periodic(Duration(milliseconds: 100), (timer) {
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
  DateTime communityUploaddate = DateTime.now();
  Future<void> fetchData() async {
    await fetchusername();
    await fetchprofilepic();
    await fetchcoverpic();
    await fetchbio();
    await fetchcommunityposts();
    await fetchCommunityUploadDate();
    await fetchplaylistid();
    await fetchplaylistname();
  }
  int views_video=0;
  List<String>communityposts=[];
  List<DateTime> commuityuploaddate=[];
  Future<void> fetchcommunityposts() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Community Posts')
          .doc(user?.uid)
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
  bool isplaylist=false;
  List<DateTime>commuploadate=[];
  Future<void> fetchCommunityUploadDate() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Community Posts')
          .doc(user?.uid)
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
      print('community upload $communityUploaddate');
    } catch (e) {
      print('Error fetching comm upload date: $e');
    }
  }
  String ipAddress='';
  Future<void> fetchIPAddress() async {
    final user = _auth.currentUser;
    final docSnap = await _firestore.collection('User Details').doc(user!.uid).get();
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

  Future<String> generateUniqueRandomNumber() async {
    String randomCombination = ''; // Initialize with an empty string
    bool unique = false;

    // Keep generating until a unique combination is found
    while (!unique) {
      randomCombination = _generateRandomCombination();
      unique = await _checkUniqueCombination(randomCombination);
    }

    // Store the random combination as a document name in Firestore
    await _storeRandomCombination(randomCombination);

    return randomCombination;
  }

  Future<bool> _checkUniqueCombination(String combination) async {
    // Check if the combination already exists in Firestore array
    QuerySnapshot querySnapshot =
    await _firestore.collection('Global Playlists').get();
    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      List<dynamic> numbers = document['VID'];
      if (numbers.contains(combination)) {
        return false; // Combination already exists, not unique
      }
    }
    return true; // Combination is unique
  }

  String _generateRandomCombination() {
    // Generate a random combination of numbers (e.g., 6 digits)
    Random random = Random();
    String combination = '';
    for (int i = 0; i < 10; i++) {
      //earlier i=6
      combination += random.nextInt(10).toString();
    }
    return combination;
  }
  Future<void> _storeRandomCombination(String combination) async {
    // Store the combination in Firestore
    final user = _auth.currentUser;
      setState(() {
        _uploading = true;
      });
      final ref = _storage.ref().child('Playlist Images/${user!.uid}/$combination');
      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      await user.updateProfile(photoURL: imageUrl);
    await _firestore.collection(user!.uid).doc(combination).set({
      'Created At': DateTime.now(),
      'Playlist Name': _playlistController.text,
      'Uploaded UID': user!.uid,
      'Image URL':_imageUrl
    });
    await _firestore.collection('Global Playlists').doc(user.uid).set({
      'VID': FieldValue.arrayUnion([combination]),
    }, SetOptions(merge: true));
    await _firestore.collection('User Uploaded Playlist ID').doc(user.uid).set({
      'VID': FieldValue.arrayUnion([combination]),
    }, SetOptions(merge: true));
    setState(() {
      _uploading = false;
      _imageUrl = imageUrl;
    });
  }
  List<String>playlistid=[];
  Future<void> fetchplaylistid() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('Global Playlists')
          .doc(user?.uid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['VID'] as List?) ?? [];
          setState(() {
            playlistid =posts.map((post) => post.toString()).toList();
          });
        }
      }
      print('playlist id $playlistid');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }

  }
  String playlistname='';
  List<String>Playlistname=[];
  String playlistdp='';
  List<String> Playlistdp=[];
  Future<void>fetchplaylistname()async{
    final user=_auth.currentUser;
    await fetchplaylistid();
    for(String ids in playlistid){
      final docsnap=await _firestore.collection(user!.uid).doc(ids).get();
      if(docsnap.exists){
        setState(() {
          playlistname=docsnap.data()?['Playlist Name'];
          Playlistname.add(playlistname);
          playlistdp=docsnap.data()?['Image URL'];
          Playlistdp.add(playlistdp);
        });
      }
    }
    print('playlist name $Playlistname');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchIPAddress();
    fetchusername();
    fetchplaylistname();
    fetchCommunityUploadDate();
    fetchVideoLengths();
    fetchprofilepic();
    fetchthumbnail();
    fetchcoverpic();
    fetchuploaddate();
    fetchsubscriber();
    fetchcaptions();
    fetchplaylistid();
    fetchvideo();
    fetchbio();
    fetchvideoid();
    fetchviews();
    fetchcommunityposts();
    fetchUserDataPeriodically();
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
          Row(
            children: [
              IconButton(onPressed: (){
                showDialog(context: context, builder: (context) {
                  return AlertDialog(
                    backgroundColor: Colors.grey.withOpacity(0.8),
                    title: Center(
                      child: Text('More Options',style: GoogleFonts.arbutusSlab(color: Colors.white,
                      fontSize: 15
                      ),),
                    ),
                    scrollable: true,
                    actions: [
                      Center(
                        child: Column(
                          children: [
                            InkWell(
                              onTap:(){
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => Watch_Later(),));
                              },
                              child: Text('Watch Later',style: GoogleFonts.abyssinicaSil(color: Colors.white,
                                  fontWeight: FontWeight.w300),),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            InkWell(
                              onTap:(){
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfile(),));
                              },
                              child: Text('Edit Profile',style: GoogleFonts.abyssinicaSil(color: Colors.white,
                                  fontWeight: FontWeight.w300),),
                            )
                          ],
                        ),
                      )
                    ],
                  );
                },);
              }, icon: Icon(Icons.more_vert,color: Colors.white,))
            ],
          )
        ],
        title: Text(username,style: GoogleFonts.arbutusSlab(color: Colors.white,fontWeight: FontWeight.bold),),
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
                    Row(
                      children: [
                        Text(username,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
                        SizedBox(
                          width: 6,
                        ),
                        if(subscriber.length>=1000)
                          Icon(Icons.verified,color: Colors.blueAccent,)
                      ],
                    ),
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
              height: 20,
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
                              Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPage(
                                  caption: captions[i],
                                  uploaddate: uploaddate[i],
                                  Index: i,
                                  viddeourl: videos[i],
                                  views: views[i],
                                  thumbnail: thumbnail[i],
                                  username: username,
                                  profilepicurl: profilepicurl,
                                  UID: user!.uid,
                                  VideoID: videoid[i]
                              ),));
                              print('index $i');
                            },
                            child: ProgressiveImage(
                              height: 150,
                              width: 150,
                              baseColor: Colors.grey.shade900,
                              highlightColor: Colors.white,
                              imageError: 'Failed To Load Image',
                              image: thumbnail[i],
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPage(
                              caption: captions[i],
                              uploaddate: uploaddate[i],
                              Index: i,
                              viddeourl: videos[i],
                              views: views[i],
                              thumbnail: thumbnail[i],
                              username: username,
                              profilepicurl: profilepicurl,
                              UID: user!.uid,
                              VideoID: videoid[i]
                          ),));
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
                                  Text('No Views', style: TextStyle(color: Colors.grey,fontSize: 12)),
                                if (views[i] == 1)
                                  Text('${views[i]} View', style: TextStyle(color: Colors.grey,fontSize: 12)),
                                if (views[i] > 1 && views[i]<=999)
                                  Text('${views[i]} Views', style: TextStyle(color: Colors.grey,fontSize: 12)),
                                if (views[i] >= 10000 && views[i]<=100000)
                                  Text('${(views[i] ~/ 1000)}K Views', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                if (views[i] > 100000 && views[i]<=9999999)
                                  Text('${(views[i] ~/ 10000)}M Views', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                SizedBox(width: 10),
                                Text(
                                  timeago.format(uploaddate[i], locale: 'en_long', allowFromNow: true), // Format the upload date
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
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
                Padding(
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
                      hintText: '  Write for community',
                      hintStyle: GoogleFonts.abyssinicaSil(color: Colors.white)
                    ),
                  ),
                ),
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
            isplaylist?Column(
              children: [
                Row(
                  children: [
                    Spacer(),
                    InkWell(
                      onTap: (){
                       showDialog(context: context, builder: (context) {
                         return AlertDialog(
                           backgroundColor: Colors.black,
                           title: Center(child: Text('Playlist Details',style: GoogleFonts.abyssinicaSil(color: Colors.white,
                           fontSize:20,fontWeight: FontWeight.bold
                           ),)),
                           actions: [
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.center,
                               children: [
                                 SizedBox(
                                   height: 10,
                                 ),
                                 Center(child: Text('Playlist Name',style: GoogleFonts.abyssinicaSil(color: Colors.white,
                                     fontSize:15
                                 ),)),
                                 Padding(
                                   padding: const EdgeInsets.all(20.0),
                                   child: TextField(
                                     controller: _playlistController,
                                     decoration: InputDecoration(
                                       hintText: 'Playlist Name',
                                       fillColor: Colors.grey,
                                       filled: true
                                     ),
                                   ),
                                 ),
                                 SizedBox(
                                   height: 20,
                                 ),
                                 Center(child: Text('Playlist Image',style: GoogleFonts.abyssinicaSil(color: Colors.white,
                                     fontSize:15
                                 ),)),
                                 SizedBox(
                                   height: 20,
                                 ),
                                 DottedBorder(
                                     borderType: BorderType.RRect,
                                     radius: Radius.circular(8),
                                     color: Colors.white,
                                     dashPattern: [10,4],
                                     strokeCap: StrokeCap.round,
                                     child: Container(
                                       width: double.infinity,
                                       height: 200,
                                       color:Colors.grey.withOpacity(0.3),
                                       child: _upload
                                           ? IconButton(
                                         onPressed: _pickImage,
                                         icon: Icon(Icons.upload, color: CupertinoColors.white),
                                       )
                                           : _image != null
                                           ? Container(
                                         width: double.infinity,
                                         height: 200,
                                         decoration: BoxDecoration(
                                           shape: BoxShape.rectangle,
                                           image: DecorationImage(
                                             image: FileImage(_image!),
                                             fit: BoxFit.fitWidth,
                                           ),
                                         ),
                                         child: IconButton(
                                           onPressed: () {
                                             setState(() {
                                               _upload = true;
                                               _image = null;
                                             });
                                           },
                                           icon: Icon(CupertinoIcons.clear,
                                               color: Colors.black),
                                         ),
                                       )
                                           : Container(),
                                     )
                                 ),
                                 SizedBox(
                                   height: 20,
                                 ),
                                 ElevatedButton(onPressed: ()async{
                                   final user=_auth.currentUser;
                                   if(_playlistController.text.isNotEmpty && _image!=null)
                                     await generateUniqueRandomNumber();
                                   Navigator.pop(context);
                                   _playlistController.clear();
                                 },
                                     child: Text('Create',style: TextStyle(color: Colors.black),),
                                 style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.green)),
                                 )
                               ],
                             )
                           ],
                           scrollable: true,
                         );
                       },) ;
                      },
                      child: Row(
                        children: [
                          Text('Create Playlist  ',style: GoogleFonts.abyssinicaSil(color: Colors.white,fontWeight: FontWeight.bold),),
                        Icon(Icons.playlist_add,color: Colors.white,),
                          SizedBox(
                            width: 10,
                          )
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 25,
                ),
                Text('Playlist Names',style: GoogleFonts.abyssinicaSil(color: Colors.white,
                fontWeight: FontWeight.bold,fontSize: 20
                ),),
                SizedBox(
                  height: 40,
                ),
                for(int i=0;i<playlistid.length;i++)
                  Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                          ),
                          InkWell(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                Playlist_Page(playlistimage: Playlistdp[i],
                                    playlistid: playlistid[i],
                                    userdp: profilepicurl,
                                    playlistname: Playlistname[i],
                                    playlist_owner: username),));
                            },
                            child: Image.network(Playlistdp[i],
                              height: 150,
                              width: 150,
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          InkWell(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                  Playlist_Page(playlistimage: Playlistdp[i],
                                      playlistid: playlistid[i],
                                      playlistname: Playlistname[i],
                                      userdp: profilepicurl,
                                      playlist_owner: username),));
                            },
                            child: Text('${Playlistname[i]}',style: GoogleFonts.abyssinicaSil(color: Colors.white,fontSize: 18),),
                          ),
                          Spacer(),
                          IconButton(onPressed: (){
                            showDialog(context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    scrollable: true,
                                    backgroundColor: Colors.black,
                                    title: Text('Edit Your Playlist Details',style: TextStyle(color: Colors.white,fontSize: 20),),
                                    actions: [
                                      Column(
                                        children: [
                                          SizedBox(
                                            height: 25,
                                          ),
                                          Center(
                                            child: Text('Playlist Names',style: GoogleFonts.abyssinicaSil(color: Colors.white,
                                                fontWeight: FontWeight.bold,fontSize: 15
                                            ),),
                                          ),
                                          SizedBox(
                                            height: 25,
                                          ),
                                          TextField(
                                            controller: _playlistController,
                                            decoration: InputDecoration(
                                                hintText: Playlistname[i],
                                                fillColor: Colors.grey,
                                                filled: true
                                            ),
                                          ),
                                          SizedBox(
                                            height: 25,
                                          ),
                                          ElevatedButton(onPressed: ()async{
                                            final user=_auth.currentUser;
                                            print('Playlist id ${playlistid[i]}');
                                            if(_playlistController.text.isNotEmpty)
                                              await _firestore.collection(user!.uid).doc(playlistid[i]).update(
                                                  {
                                                    'Playlist Name':_playlistController.text,
                                                    'Edited at':FieldValue.serverTimestamp(),
                                                  });
                                            Navigator.pop(context);
                                            setState(() {
                                              Playlistname[i]=_playlistController.text;
                                            });
                                            _playlistController.clear();

                                          },
                                            child: Text('Edit',style: TextStyle(color: Colors.black),),
                                            style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.green)),
                                          )
                                        ],
                                      )
                                    ],
                                  );
                                },);
                          }, icon: Icon(Icons.more_vert,color: Colors.white,))
                        ],
                      ),
                      SizedBox(
                        height: 50,
                      ),
                    ],
                  )
              ],
            ):Container(),
        ]),
      ),
    );
  }
}
