import 'package:flutter/material.dart';
import 'package:memoir/screens/calendar_screen.dart';
import 'package:memoir/screens/graph_view_screen.dart';
import 'package:memoir/screens/image_gallery_screen.dart';
import 'package:memoir/screens/map_screen.dart';
import 'package:memoir/screens/person_list_screen.dart';
import 'package:memoir/screens/settings_screen.dart';


class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[

    PersonListScreen(),
    CalendarScreen(),
    MapScreen(),
    SettingsScreen(),
    // ImageGalleryScreen(),
    // GraphViewScreen(),



  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            // selectedIcon: Icon(Icons.people),
            icon: Icon(Icons.people_alt),
            label: 'Contacts',
          ),
          NavigationDestination(
            // selectedIcon: Icon(Icons.calendar_today),
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            // selectedIcon: Icon(Icons.map),
            icon: Icon(Icons.location_on_outlined),
            label: 'Map',
          ),
          NavigationDestination(
            // selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
          // NavigationDestination(
          //   selectedIcon: Icon(Icons.photo_library),
          //   icon: Icon(Icons.photo_library_outlined),
          //   label: 'Gallery',
          // ),
          // NavigationDestination(
          //   selectedIcon: Icon(Icons.hub),
          //   icon: Icon(Icons.hub_outlined),
          //   label: 'Graph',
          // ),

        ],
      ),
    );
  }
}