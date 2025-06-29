import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Assuming you use Firebase

// An enum is a good practice for defining menu values for type safety
enum MenuAction { logout }

class MyAwesomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool hasBackButton;

  const MyAwesomeAppBar({
    super.key,
    required this.title,
    this.hasBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      centerTitle: true,
      elevation: 0,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      automaticallyImplyLeading: hasBackButton,
      actions: [
        // Replace your IconButton with PopupMenuButton
        PopupMenuButton<MenuAction>(
          position: PopupMenuPosition.under,
          // This is the callback that is called when a menu item is selected.
          onSelected: (MenuAction result) async {
            switch (result) {
              case MenuAction.logout:
              // --- YOUR LOGOUT LOGIC GOES HERE ---
                debugPrint("Logout action selected");
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
                break;
            }
          },
          // This is the builder for the menu items.
          itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuAction>>[
            const PopupMenuItem<MenuAction>(
              value: MenuAction.logout,
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
            // You can add more PopupMenuItems here for other options
            // const PopupMenuItem<MenuAction>(
            //   value: MenuAction.settings,
            //   child: Text('Settings'),
            // ),
          ],
          // Optional: You can add a tooltip for accessibility
          tooltip: "More options",
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}