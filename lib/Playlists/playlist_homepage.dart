import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:timeago/timeago.dart'as timeago;
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelprowess/Video%20Card/VideoCard.dart';
class Playlist_Page extends StatefulWidget {
  final String playlistimage;
  final String playlistname;
  final String playlistid;
  final String playlist_owner;
  final String userdp;
  bool ischangeable;
  Playlist_Page({
    required this.playlistimage,
    required this.playlistid,
    required this.playlistname,
    required this.playlist_owner,
    required this.userdp,
    required this.ischangeable,
  });

  @override
  State<Playlist_Page> createState() => _Playlist_PageState();
}

class _Playlist_PageState extends State<Playlist_Page> {
  bool ispublic=true;
  String bio='Please set your bio';
  FirebaseAuth _auth=FirebaseAuth.instance;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  Future<void> fetchpublicstatus()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection(user!.uid).doc(widget.playlistid).get();
    if(docsnap.exists){
      setState(() {
        ispublic=docsnap.data()?['Public'];
      });
    }
  }
  Future<void> fetchplaylistbio()async{
    final user=_auth.currentUser;
    final docsnap=await _firestore.collection(user!.uid).doc(widget.playlistid).get();
    if(docsnap.exists){
      setState(() {
        bio=docsnap.data()?['Bio'];
      });
    }
  }
  TextEditingController _bioController=TextEditingController();
  List<String>videoid=[];
  Future<void> fetchvideoid() async {
    final user = _auth.currentUser;
    try {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('User Uploaded Playlist ID')
          .doc(widget.playlistid)
          .get();

      if (documentSnapshot.exists) {
        dynamic data = documentSnapshot.data();
        if (data != null) {
          List<dynamic> posts = (data['VIDs'] as List?) ?? [];
          setState(() {
            videoid =posts.map((post) => post.toString()).toList();
          });
        }
      }
      print('vids playlist $videoid');
    } catch (e) {
      print('Error fetching followers videos: $e');
    }
  }
  List<String>videos=[];
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
    print(' videos fetched playlist $videos , length ${videos.length}');
  }
  String thumbnails='';
  List<String>thumbnail=[];
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
    print(' thumbnail playlist $thumbnail');
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
    print(' UIDs playlist $uploadeduseruid');
  }
  String Caption='';
  List<String>captions=[];
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
    print(' captions playlist $captions');
  }
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
    print(' username playlist $USernames');
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
    print(' dp playlist $Profileurls');
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
    print(' Views got playlist$views');
  }
  List<String>subscriber=[];
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
      print('following playlist $subscriber');
    } catch (e) {
      print('Error fetching followers fetchfollowers: $e');
    }
  }
  List<DateTime>uploaddate=[];
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchpublicstatus();
    fetchplaylistbio();
    fetchvideoid();
    fetchvideo();
    fetchthumbnail();
    fetchuploadeduseruid();
    fetchcaptions();
    fetchdp();
    fetchusernames();
    fetchsubscriber();
    fetchviews();
    fetchuploaddate();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (uploaddate.isEmpty || captions.isEmpty || thumbnail.isEmpty ||
                Profileurls.isEmpty || views.isEmpty || videoid.isEmpty ||
                videos.isEmpty || uploadeduseruid.isEmpty)
              Column(
                children: [
                  SizedBox(height: 50,),
                  Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.red,
                        color: Colors.white,
                      )
                  )
                ],
              ),
            if(uploaddate.isNotEmpty && captions.isNotEmpty && thumbnail.isNotEmpty && Profileurls.isNotEmpty && views.isNotEmpty
                && videoid.isNotEmpty && videos.isNotEmpty && uploadeduseruid.isNotEmpty)
              Stack(
                children: [
                  // Foreground Image
                  Image.network(
                    widget.playlistimage, // Replace this with your image asset
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                  ),
                  // Background Blur
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: Colors.black.withOpacity(0.8), // Adjust opacity as needed
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            IconButton(onPressed: (){
                              Navigator.pop(context);
                            }, icon: Icon(CupertinoIcons.back,color: Colors.white,))
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius:15,
                              backgroundImage: NetworkImage(widget.userdp),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Column(
                              children: [
                                Text(widget.playlist_owner,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                                if(ispublic)
                                  Text('Public',style: GoogleFonts.aBeeZee(color: Colors.grey),),
                                if(!ispublic)
                                  Text('Private',style: GoogleFonts.aBeeZee(color: Colors.grey),),
                                if(widget.ischangeable)
                                  InkWell(
                                      onTap: ()async{
                                        setState(() {
                                          ispublic=!ispublic;
                                        });
                                        final user=_auth.currentUser;
                                        if(ispublic)
                                          await _firestore.collection(user!.uid).doc(widget.playlistid).update(
                                              {
                                                'Public':true
                                              });
                                        if(!ispublic)
                                          await _firestore.collection(user!.uid).doc(widget.playlistid).update(
                                              {
                                                'Public':false
                                              });
                                      },
                                      child: Text('Change',style: GoogleFonts.aBeeZee(color: Colors.green),)),
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Center(
                          child: Image.network(widget.playlistimage,width: 250,height: 250,),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(widget.playlistname,style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold,fontSize: 20
                        ),),
                        SizedBox(
                          height: 20,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(bio,style: GoogleFonts.abyssinicaSil(color: Colors.grey,fontSize: 15,),),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black,
                              child: IconButton(onPressed: (){}, icon: Icon(Icons.download_outlined,color: Colors.white,)),
                            ),
                            if(widget.ischangeable)
                              CircleAvatar(
                                backgroundColor: Colors.black,
                                child: IconButton(onPressed: ()async{
                                  final user=_auth.currentUser;
                                  showDialog(context: context, builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.black,
                                      title: Center(
                                          child: Text('Edit Bio',style: TextStyle(color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15
                                          ),)),
                                      actions: [
                                        Column(
                                          children: [
                                            SizedBox(
                                              height: 25,
                                            ),
                                            Center(
                                              child: Text('Playlist Bio',style: GoogleFonts.abyssinicaSil(color: Colors.white,
                                                  fontWeight: FontWeight.bold,fontSize: 15
                                              ),),
                                            ),
                                            SizedBox(
                                              height: 25,
                                            ),
                                            TextField(
                                              controller: _bioController,
                                              decoration: InputDecoration(
                                                  hintText:bio,
                                                  fillColor: Colors.grey,
                                                  filled: true
                                              ),
                                            ),
                                            SizedBox(
                                              height: 25,
                                            ),
                                            ElevatedButton(onPressed: ()async{
                                              final user=_auth.currentUser;
                                              if(_bioController.text.isNotEmpty)
                                                await _firestore.collection(user!.uid).doc(widget.playlistid).update(
                                                    {
                                                      'Bio':_bioController.text,
                                                      'Edited at':FieldValue.serverTimestamp(),
                                                    });
                                              Navigator.pop(context);
                                              setState(() {
                                                bio=_bioController.text;
                                              });
                                              _bioController.clear();
                                            },
                                              child: Text('Edit',style: TextStyle(color: Colors.black),),
                                              style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.green)),
                                            )
                                          ],
                                        )
                                      ],
                                    );
                                  },);
                                }, icon: Icon(Icons.edit,color: Colors.white,)),
                              ),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPage(
                                    caption: captions[0],
                                    uploaddate:uploaddate[0] ,
                                    Index: 0,
                                    viddeourl: videos[0],
                                    views: views[0],
                                    thumbnail: thumbnail[0],
                                    username: USernames[0],
                                    profilepicurl: Profileurls[0],
                                    UID: uploadeduseruid[0],
                                    VideoID: videoid[0]),));
                              }, icon: Icon(Icons.play_arrow,color: Colors.black,)),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.black,
                              child: IconButton(onPressed: (){
                                Clipboard.setData(ClipboardData(text: 'www.pixelprowess.com/playlist/${widget.playlistid}/share=${widget.ischangeable}'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Center(child: Text('Copied Successfully')),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }, icon: Icon(Icons.share_rounded,color: Colors.white,)),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.black,
                              child: IconButton(onPressed: (){
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.black,
                                      title: Center(
                                        child: Text('Edit Playlist',style: GoogleFonts.abyssinicaSil(
                                          color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold
                                        ),),
                                      ),
                                      actions: [
                                        Center(
                                          child: Column(
                                            children: [
                                              InkWell(
                                                onTap:(){},
                                                child: Text('Edit Playlist Cover Image',style: GoogleFonts.abyssinicaSil(
                                                    color: Colors.white,fontSize: 15
                                                ),),
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              InkWell(
                                                onTap:(){},
                                                child: Text('Edit Playlist Bio',style: GoogleFonts.abyssinicaSil(
                                                    color: Colors.white,fontSize: 15
                                                ),),
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              InkWell(
                                                onTap:(){},
                                                child: Text('Delete Playlist',style: GoogleFonts.abyssinicaSil(
                                                    color: Colors.red,fontSize: 15
                                                ),),
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              InkWell(
                                                onTap:()async{
                                                  setState(() {
                                                    ispublic=!ispublic;
                                                  });
                                                  final user=_auth.currentUser;
                                                  if(ispublic)
                                                    await _firestore.collection(user!.uid).doc(widget.playlistid).update(
                                                      {
                                                        'Public':true
                                                      });
                                                  if(!ispublic)
                                                    await _firestore.collection(user!.uid).doc(widget.playlistid).update(
                                                      {
                                                        'Public':false
                                                      });
                                                  Navigator.pop(context);
                                                },
                                                child: ispublic?Text('Make Private',style: GoogleFonts.abyssinicaSil(
                                                    color: Colors.red,fontSize: 15
                                                ),):Text('Make Public',style: GoogleFonts.abyssinicaSil(
                                                    color: Colors.green,fontSize: 15
                                                ),),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    );
                                  },
                                );
                              }, icon: Icon(Icons.more_vert,color: Colors.white,)),
                            ),
                          ],
                        ),
                        if(thumbnails.isNotEmpty && captions.isNotEmpty)
                          for(int i=0;i<videoid.length;i++)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 10,
                                    ),
                                    InkWell(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPage(
                                            caption: captions[i],
                                            uploaddate:uploaddate[i] ,
                                            Index: i,
                                            viddeourl: videos[i],
                                            views: views[i],
                                            thumbnail: thumbnail[i],
                                            username: USernames[i],
                                            profilepicurl: Profileurls[i],
                                            UID: uploadeduseruid[i],
                                            VideoID: videoid[i]),));
                                      },
                                      child: Image.network(thumbnail[i],height: 150,width: 150,),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(captions[i],style: GoogleFonts.abyssinicaSil(color: Colors.white,fontWeight: FontWeight.bold),),
                                        Row(
                                          children: [
                                            Text(
                                                '${views[i]} Views • ${timeago.format(uploaddate[i], locale: 'en_long', allowFromNow: true)}',
                                                style: TextStyle(color: Colors.grey, fontSize: 12)
                                            ),
                                          ],
                                        ),

                                      ],
                                    ),
                                    Spacer(),
                                   if(widget.ischangeable)
                                     IconButton(onPressed: ()async{
                                       showDialog(context: context, builder: (context) {
                                         return AlertDialog(
                                           backgroundColor: Colors.black,
                                           title: Center(child: Text('Delete The Video',style: GoogleFonts.abyssinicaSil(color: Colors.white,fontSize: 15),)),
                                           actions: [
                                             Column(
                                               crossAxisAlignment: CrossAxisAlignment.center,
                                               children: [
                                                 Text('Video once deleted cannot be recovered and added to the playlist.\n'
                                                     '\nAre you Sure?',style: GoogleFonts.abyssinicaSil(
                                                     color: Colors.red,fontSize: 15,fontWeight: FontWeight.bold
                                                 ),),
                                                 SizedBox(
                                                   height: 20,
                                                 ),
                                                 Row(
                                                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                   children: [
                                                     ElevatedButton(onPressed: (){}, child: Text('Go Back',style: TextStyle(color: Colors.black),
                                                     ),
                                                       style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.green)),
                                                     ),
                                                     ElevatedButton(onPressed: ()async{
                                                       await _firestore.collection('User Uploaded Playlist ID').doc(widget.playlistid).update(
                                                           {
                                                             'VIDs':FieldValue.arrayRemove([
                                                               videoid[i]
                                                             ])
                                                           });
                                                       Navigator.pop(context);
                                                     }, child: Text('Delete',style: TextStyle(color: Colors.white),
                                                     ),
                                                       style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.red)),
                                                     ),
                                                   ],
                                                 )
                                               ],
                                             )
                                           ],
                                         );
                                       },);
                                     }, icon: Icon(Icons.more_vert,color: Colors.white,))
                                  ],
                                ),
                              ],
                            ),
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
    ],
        ),
      ),
    );
  }
}
