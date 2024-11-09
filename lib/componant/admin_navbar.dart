import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:panne_auto/pages/admin%20pages/home_page_admin.dart';
import 'package:panne_auto/pages/chat/messages.dart';
import 'package:panne_auto/pages/client%20pages/profile_page.dart';


class Admin_nav extends StatefulWidget {
  const Admin_nav({Key? key}) : super(key: key);

  @override
  _Admin_navState createState() => _Admin_navState();
}

class _Admin_navState extends State<Admin_nav> {
  int _selectedIndex = 0;
  final _pageController = PageController();

  static List<Widget> _widgetOptions = <Widget>[
    HomePage_admin(),
    SentMessagesScreen(), // Add the ChatsScreen to the list and replace 'currentUserId' with the id of the current user
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
            label: '',
          ),
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
            label: '',
          ),
        ],
      ),
    );
  }
}
