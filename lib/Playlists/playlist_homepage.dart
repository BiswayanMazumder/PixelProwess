import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';
class Playlist_Page extends StatefulWidget {
  final String playlistimage;
  final String playlistname;
  final String playlistid;
  final String playlist_owner;
  final String userdp;
  Playlist_Page({
    required this.playlistimage,
    required this.playlistid,
    required this.playlistname,
    required this.playlist_owner,
    required this.userdp,
  });

  @override
  State<Playlist_Page> createState() => _Playlist_PageState();
}

class _Playlist_PageState extends State<Playlist_Page> {
  bool ispublic=true;
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchpublicstatus();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
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
              SizedBox(height: 1000),
              SizedBox(
                height: 20,
              ),
              Row(
                children: [

                ],
              )
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
