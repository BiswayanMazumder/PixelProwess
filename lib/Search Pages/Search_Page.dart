import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixelprowess/Search%20Pages/Searched_video.dart';
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController=TextEditingController();
  bool isShowUser = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(CupertinoIcons.back,color: Colors.white,)),
        title: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white)
          ),
          child: AnimatedTextField(
            style: GoogleFonts.arbutusSlab(color: Colors.white),
            animationType: Animationtype.slide, // Use Animationtype.slide for Slide animations
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search,color: Colors.white,),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
            onSubmitted: (String _) {
              print(_);
              setState(() {
                isShowUser = true;
              });
            },
            hintTextStyle: GoogleFonts.arbutusSlab(color: Colors.white),
            hintTexts: [
              'Search for "Ronaldo"',
              'How to make custard?',
              'Search for "Chennai"',
              'The Railway Man Trailer'
            ],
          ),
        )
      ),
      backgroundColor: Colors.black,
      body: isShowUser
          ? FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('Global Post')
            .where('Caption',
            isGreaterThanOrEqualTo: _searchController.text)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return ListView.builder(
            itemCount: (snapshot.data! as dynamic).docs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 30,top: 20,right: 20),
                child: ListTile(
                    leading:InkWell(
                      onTap: (){
                        String userId =
                            (snapshot.data! as dynamic).docs[index].id;
                        print('User ID: $userId');
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Searched_video(UIDs: userId),));
                      },
                      child: Image.network((snapshot.data! as dynamic).docs[index]['Thumbnail Link'],fit: BoxFit.fitWidth,),
                    ),
                    title: InkWell(
                      onTap: (){
                        String userId =
                            (snapshot.data! as dynamic).docs[index].id;
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Searched_video(UIDs: userId),));
                        print('User ID: $userId');
                      },
                      child:Text(
                        (snapshot.data! as dynamic).docs[index]['Caption'],
                        style: TextStyle(color: Colors.white,),
                      ),
                    ),
                ),
              );
            },
          );
        },
      )
          : // Display images in a 3x3 grid
      Container()
    );
  }
}
