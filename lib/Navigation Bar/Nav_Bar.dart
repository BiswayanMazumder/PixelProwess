import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:pixelprowess/Homepages/Accountpage.dart';
import 'package:pixelprowess/Homepages/LandingPage.dart';
import 'package:pixelprowess/Pages/upload_page.dart';
class NavBar extends StatefulWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final _pageController = PageController(initialPage: 0);
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  final List screens=[
    LandingPage(),
    Upload_Page(),
    Accountpage()
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      backgroundColor: Colors.black,

      bottomNavigationBar: GNav(
          haptic: true,
          curve: Curves.bounceInOut,
          rippleColor: Colors.yellow,
          tabActiveBorder: Border.all(color: Colors.green,
              style: BorderStyle.solid),
          hoverColor: Colors.white,
          activeColor: Colors.black,
          color: Colors.deepPurpleAccent,
          // rippleColor: Colors.green,
          tabBackgroundColor: Colors.green,
          selectedIndex: _index,
          // tabBorder: Border.all(color: Colors.red),
          gap: 1,
          onTabChange: (value){
            setState(() {
              _index=value;
            });
          },
          tabs: [
            GButton(icon: Icons.home,
              rippleColor: Colors.green,
              backgroundColor: Colors.red,
            ),

            GButton(icon: Icons.add_box_outlined,
              backgroundColor: Colors.lightGreenAccent,
            ),
            GButton(icon: Icons.person,
              backgroundColor: Colors.blue,
              haptic: true,
              debug: true,
            ),
          ]
      ),
    );
  }
}
