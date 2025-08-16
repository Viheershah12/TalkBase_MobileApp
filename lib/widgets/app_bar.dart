import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum MenuAction { logout }

class MyAwesomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool hasBackButton;
  final bool hasSearchButton;
  final bool isSearchActive;
  final TextEditingController? searchController;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onSearchClosed;
  final Widget? mainAction;
  final Widget? leadingAction;

  const MyAwesomeAppBar({
    super.key,
    required this.title,
    this.hasBackButton = false,
    this.hasSearchButton = false,
    this.isSearchActive = false,
    this.searchController,
    this.onSearchPressed,
    this.onSearchClosed,
    this.mainAction,
    this.leadingAction,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current theme's color scheme
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // --- UPDATED: Prioritize custom leading action ---
    final Widget? leadingWidget = isSearchActive
        ? IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: onSearchClosed,
      tooltip: 'Close Search',
    )
    // If a leadingAction is provided, use it. Otherwise, use the back button logic.
        : leadingAction ?? (hasBackButton ? const BackButton() : null);

    final Widget titleWidget = isSearchActive
        ?
        TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search contacts...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        )
        : Text(title, style: const TextStyle(fontWeight: FontWeight.bold));

    // Determine the leading widget. In search mode, it's always the close button.
    // final Widget? leadingWidget = isSearchActive
    //     ? IconButton(
    //   icon: const Icon(Icons.arrow_back),
    //   onPressed: onSearchClosed,
    //   tooltip: 'Close Search',
    // ) :
    // (hasBackButton ? const BackButton() : null);
    //
    // // Determine the title. In search mode, it's the TextField.
    // final Widget titleWidget = isSearchActive ?
    // TextField(
    //   controller: searchController,
    //   autofocus: true,
    //   decoration: const InputDecoration(
    //     hintText: 'Search contacts...',
    //     border: InputBorder.none,
    //     hintStyle: TextStyle(color: Colors.white70),
    //   ),
    //   style: const TextStyle(color: Colors.white, fontSize: 18),
    // ) :
    // Text(
    //     title,
    //     style: const TextStyle(fontWeight: FontWeight.bold)
    // );

    // Determine the action widgets.
    final List<Widget> actionWidgets = isSearchActive ?
    [
      if (searchController?.text.isNotEmpty ?? false)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => searchController?.clear(),
          tooltip: 'Clear',
        ),
    ] :
    [
      if (mainAction != null) mainAction!,
      if (hasSearchButton)
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchPressed,
          tooltip: "Search Contacts",
        ),
      PopupMenuButton<MenuAction>(
        position: PopupMenuPosition.under,
        onSelected: (MenuAction result) async {
          if (result == MenuAction.logout && context.mounted) {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuAction>>[
          PopupMenuItem<MenuAction>(
            value: MenuAction.logout,
            child: Row(
              children: [
                Icon(Icons.logout, color: colorScheme.error),
                const SizedBox(width: 8),
                const Text('Logout'),
              ],
            ),
          ),
        ],
        tooltip: "More options",
      ),
    ];

    return AppBar(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      leading: leadingWidget,
      title: titleWidget,
      actions: actionWidgets,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}