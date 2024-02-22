import 'package:flutter/material.dart';
import 'package:google_gemini/google_gemini.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const apiKey = "AIzaSyCjzkbxVm2FFTvTteG2b3xOlCtMd-skjJw";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const support_sections(),
    );
  }
}

class support_sections extends StatefulWidget {
  const support_sections({
    Key? key,
  }) : super(key: key);

  @override
  State<support_sections> createState() => _support_sectionsState();
}

class _support_sectionsState extends State<support_sections> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        initialIndex: 0,
        length: 1,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Welcome To Dotti"),
              centerTitle: false,
              bottom: const TabBar(
                tabs: [
                  Tab(text: "Text Only"),
                ],
              ),
            ),
            body: const TabBarView(
              children: [TextOnly()],
            )));
  }
}

// ------------------------------ Text Only ------------------------------

class TextOnly extends StatefulWidget {
  const TextOnly({
    Key? key,
  }) : super(key: key);

  @override
  State<TextOnly> createState() => _TextOnlyState();
}

class _TextOnlyState extends State<TextOnly> {
  bool loading = false;
  List textChat = [];
  List textWithImageChat = [];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _controller = ScrollController();

  final gemini = GoogleGemini(
    apiKey: apiKey,
  );
  String? username = 'User 1';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> fetchUsername() async {
    final user = _auth.currentUser;
    final docSnap =
    await _firestore.collection('User Details').doc(user?.uid).get();
    if (docSnap.exists) {
      setState(() {
        username = docSnap.data()?['Username'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchChat(); // Call fetchChat to retrieve chat messages
  }

  void fromText({required String query}) async {
    final user = _auth.currentUser;

    // Save the user's message to Firestore
    await _firestore.collection('Chats').doc(user?.uid).collection('Messages').add({
      "role": username,
      "text": query,
      "type": "user",
      "timestamp": Timestamp.now(),
    });

    setState(() {
      loading = true;
      textChat.add({
        "role": username,
        "text": query,
        "type": "user",
      });
      _textController.clear();
    });
    scrollToTheEnd();

    gemini.generateFromText(query).then((value) async {
      // Save the response from Gemini to Firestore
      await _firestore.collection('Chats').doc(user?.uid).collection('Messages').add({
        "role": "Dotti",
        "text": value.text,
        "type": "gemini",
        "timestamp": Timestamp.now(),
      });

      setState(() {
        loading = false;
        textChat.add({
          "role": "Dotti",
          "text": value.text,
          "type": "gemini",
        });
      });
      scrollToTheEnd();
    }).onError((error, stackTrace) {
      setState(() {
        loading = false;
        textChat.add({
          "role": "Dotti",
          "text": error.toString(),
          "type": "error",
        });
      });
      scrollToTheEnd();
    });
  }


  Future<void> fetchChat() async {
    final user = _auth.currentUser;
    final messagesSnapshot = await _firestore.collection('Chats').doc(user?.uid).collection('Messages').orderBy('timestamp').get();

    setState(() {
      textChat = messagesSnapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  void scrollToTheEnd() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _controller,
                itemCount: textChat.length,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  // Add a null check before calling substring
                  final role = textChat[index]["role"];
                  return ListTile(
                    isThreeLine: true,
                    leading: CircleAvatar(
                      child: Text(role != null ? role.substring(0, 1) : ''), // Check for null
                    ),
                    title: Text(
                      role ?? '', // Check for null
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(textChat[index]["text"] ?? ''), // Check for null
                  );
                },
              ),

            ),
            Container(
              alignment: Alignment.bottomRight,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: "Type a message",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide.none),
                        fillColor: Colors.transparent,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  IconButton(
                    icon: loading
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.send),
                    onPressed: () {
                      if (_textController.text.isNotEmpty) fromText(query: _textController.text);
                    },
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
