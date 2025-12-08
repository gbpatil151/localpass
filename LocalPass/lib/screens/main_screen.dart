import 'package:flutter/material.dart';
import 'package:localpass/screens/event_feed_screen.dart';
import 'package:localpass/screens/my_passes_screen.dart';
import 'package:localpass/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of screens to display based on the selected index
  static final List<Widget> _widgetOptions = <Widget>[
    EventFeedScreen(), // Index 0: Event Feed
    MyPassesScreen(),  // Index 1: My Passes
    ProfileScreen(),   // Index 2: Profile & Wallet
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body displays the selected screen
      body: _widgetOptions.elementAt(_selectedIndex),

      // Persistent Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'My Passes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}