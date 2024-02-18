import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pixelprowess/Homepages/Accountpage.dart';
import 'package:pixelprowess/Homepages/LandingPage.dart';
import 'package:pixelprowess/Navigation%20Bar/Nav_Bar.dart';
import 'package:pixelprowess/firebase_options.dart';
class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}
class _LoginState extends State<Login> {
  bool showpw = false;
  bool filledusername=false;
  bool filledpw=false;
  bool filledemail=false;
  bool filleddob=false;
  FirebaseFirestore _firestore=FirebaseFirestore.instance;
  FirebaseAuth _auth=FirebaseAuth.instance;
  TextEditingController dobController = TextEditingController();
  TextEditingController _emailcontroller = TextEditingController();
  TextEditingController _username = TextEditingController();
  TextEditingController _password = TextEditingController();
  Future<String?> fetchIPAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print('Failed to fetch IP address: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching IP address: $e');
      return null;
    }
  }

  Future<void> adduserfirestore() async {
    await adduser();
    final user = _auth.currentUser;
    if (user != null) {
      final ipAddress = await fetchIPAddress();
      if (ipAddress != null) {
        await _firestore.collection('User Details').doc(user.uid).set({
          'Email': _emailcontroller.text,
          'Password': _password.text,
          'Username': _username.text,
          'Date Of Birth': dobController.text,
          'IPAddress': ipAddress,
        });
      }
    }
  }

  Future<void> adduser()async{
    try{
      await _auth.createUserWithEmailAndPassword(email: _emailcontroller.text.toString(), password: _password.text.toString());
    }catch(e){
      print('Error $e');
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != DateTime.now())
      setState(() {
        dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchIPAddress();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            CupertinoIcons.back,
            color: CupertinoDynamicColor.withBrightness(
                color: Colors.white, darkColor: CupertinoColors.black),
          ),
        ),
        title: Text(
          'Log In',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 50,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text(
                  'Email',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _emailcontroller,
                decoration: InputDecoration(fillColor: Colors.grey, filled: true),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text(
                  'Password',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _password,
                obscureText: showpw ? false : true,
                decoration: InputDecoration(
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showpw = !showpw;
                          });
                        },
                        icon: showpw ? Icon(CupertinoIcons.eye_slash) : Icon(CupertinoIcons.eye)),
                    fillColor: Colors.grey,
                    filled: true),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: ()async{
                  await _auth.sendPasswordResetEmail(email: _emailcontroller.text);
                }, child: Text('Forgot Password?',style: TextStyle(color: Colors.red),)),
                SizedBox(
                  width: 15,
                )
              ],
            ),
            SizedBox(
              height: 40,
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                    onPressed: ()async{
                      if(_username.text.isEmpty && _password.text.isEmpty){
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text('Please enter correct credentials'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }else{
                        try{
                          await _auth.signInWithEmailAndPassword(email: _emailcontroller.text, password: _password.text);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>NavBar(),));
                        }catch(e){
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Please enter correct credentials'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.purple)),
                    child: Text('Log In', style: TextStyle(color: Colors.white),)))
          ],
        ),
      ),
    );
  }
}
