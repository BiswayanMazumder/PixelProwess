import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pixelprowess/Homepages/Accountpage.dart';
import 'package:pixelprowess/Homepages/LandingPage.dart';
import 'package:pixelprowess/Pages/login.dart';
import 'package:pixelprowess/Pages/signup.dart';
import 'package:pixelprowess/firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    FirebaseAuth _auth=FirebaseAuth.instance;
    final user=_auth.currentUser;
    return MaterialApp(
      title: 'PixelProwess',
      debugShowCheckedModeBanner: false,
      home: user!=null?LandingPage():HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purpleAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'NT ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    'Games',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    ' Call Of Duty:M',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'ive ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    'Music',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    ' Electronics Punk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'all ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    'Sports',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    ' Fantasy Sports',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'news ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    'Talk Shows',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    ' Fantasy Sports',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'dly ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    'Just Chatting',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    ' News M',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'ng ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    'Food & Drink',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                  Text(
                    ' Social Ea',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black12,
                      fontSize: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "There's something\n for you on\nPixelProwess",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 35, // Adjust the multiplier as needed
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Signup(),));
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.white),
                      elevation: MaterialStatePropertyAll(10),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Add some spacing between buttons
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.purpleAccent),
                      elevation: MaterialStatePropertyAll(10),
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
