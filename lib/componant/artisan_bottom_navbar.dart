import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:panne_auto/pages/artisan_page/request_page.dart';
import 'package:panne_auto/pages/artison_page.dart';
import 'package:panne_auto/pages/chat/messages.dart';
import 'package:panne_auto/pages/client%20pages/profile_page.dart';

class ArtisanNavbar extends StatefulWidget {
  const ArtisanNavbar({super.key});

  @override
  State<ArtisanNavbar> createState() => _ArtisanNavbarState();
}

class _ArtisanNavbarState extends State<ArtisanNavbar> {
  int _selectedIndex = 0;
  final _pageController = PageController();

  static final List<Widget> _widgetOptions = <Widget>[
    ArtisanPage(),
    RequestPage(),
    SentMessagesScreen(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 60,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        destinations: [
          NavigationDestination(
              icon: Icon(
                FeatherIcons.home,
                color: Color(0xFF235A81),
              ),
              label: ''),
          NavigationDestination(
              icon: Icon(
                FeatherIcons.list,
                color: Color(0xFF235A81),
              ),
              label: ''),
          NavigationDestination(
            icon: Icon(
              FeatherIcons
                  .messageCircle, // Use an appropriate icon for the chat page
              color: Color(0xFF235A81),
            ),
            label: '',
          ),
          NavigationDestination(
              icon: Icon(
                FeatherIcons.settings,
                color: Color(0xFF235A81),
              ),
              label: ''),
        ],
      ),
    );
  }
}
