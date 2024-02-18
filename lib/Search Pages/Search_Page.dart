import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        title: TextFormField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            hintText: 'Search PixelProwess',
            hintStyle: TextStyle(color: Colors.grey,fontWeight: FontWeight.w400),
            fillColor: Colors.grey[900]
          ),
          onFieldSubmitted: (String _) {
            print(_);
            setState(() {
              isShowUser = true;
            });
          },
        ),
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
                        style: TextStyle(color: Colors.white),
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
