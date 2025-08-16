// lib/pages/contacts_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/app_bar.dart';
import '../chat/chat_room.dart';
import 'chat_group_page.dart';

// A custom class to hold both contact info and their registration status
class AppContact {
  final Contact contact;
  final bool isRegistered;

  AppContact({required this.contact, required this.isRegistered});
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactsPage> {
  List<AppContact> _appContacts = [];
  List<AppContact> _filteredContacts = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _isSearchActive = false;
  bool _isSelectionMode = false;
  final List<AppContact> _selectedContacts = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContactsAndCheckStatus();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _appContacts.where((appContact) {
        final displayName = appContact.contact.displayName.toLowerCase();
        final phoneNumber = appContact.contact.phones.isNotEmpty
            ? appContact.contact.phones.first.number
            : '';
        return displayName.contains(query) || phoneNumber.contains(query);
      }).toList();
    });
  }

  // void _filterContacts() {
  //   final query = _searchController.text.toLowerCase();
  //   setState(() {
  //     _filteredContacts = _appContacts.where((appContact) {
  //       final displayName = appContact.contact.displayName.toLowerCase();
  //       final phoneNumber = appContact.contact.phones.isNotEmpty
  //           ? appContact.contact.phones.first.number
  //           : '';
  //       return displayName.contains(query) || phoneNumber.contains(query);
  //     }).toList();
  //   });
  // }

  Future<void> _fetchContactsAndCheckStatus() async {
    // 1. Use permission_handler to check the status
    PermissionStatus status = await Permission.contacts.status;

    // 2. If permission is not granted, request it
    if (!status.isGranted) {
      status = await Permission.contacts.request();
    }

    // 3. Handle the final status
    if (status.isGranted) {
      // Permission is granted, proceed with fetching contacts
      setState(() {
        _permissionDenied = false;
      });
      // Call your original contact fetching logic here
      await _getContactsFromPhone();
    } else if (status.isPermanentlyDenied) {
      // Permission is permanently denied, show a dialog to open settings
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
      _showSettingsDialog();
    } else {
      // Handle other cases (denied, restricted)
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
    }
  }

  // Helper method to show a dialog that opens app settings
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Permissions Required"),
          content: const Text("Contact permissions have been permanently denied. Please go to your app settings to enable them."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Open Settings"),
              onPressed: () {
                openAppSettings(); // This opens the app's settings page
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getContactsFromPhone() async {
    // Make sure loading is true at the start
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    // Fetch contacts from the phone
    List<Contact> phoneContacts = await FlutterContacts.getContacts(withProperties: true);

    // 3. Prepare phone numbers for Firestore query
    List<String> phoneNumbersToCheck = [];
    for (var contact in phoneContacts) {
      if (contact.phones.isNotEmpty) {
        // Normalize the phone number if necessary (e.g., remove spaces, hyphens)
        // For simplicity, we'll use the raw number here.
        // In a real app, you'd want a robust normalization function.
        phoneNumbersToCheck.add(contact.phones.first.number);
      }
    }

    if (phoneNumbersToCheck.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Check registration status against Firestore in batches
    Set<String> registeredPhones = {};

    // Firestore 'whereIn' queries are limited, so we query in batches of 30.
    for (var i = 0; i < phoneNumbersToCheck.length; i += 30) {
      // Create the initial sublist
      var originalSublist = phoneNumbersToCheck.sublist(
          i,
          i + 30 > phoneNumbersToCheck.length
              ? phoneNumbersToCheck.length
              : i + 30);

      // Create a new list with spaces removed from each phone number
      var sublistWithoutSpaces = originalSublist
          .map((phoneNumber) => phoneNumber.replaceAll(' ', ''))
          .toList();

      // Use the cleaned list in the Firestore query
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', whereIn: sublistWithoutSpaces)
          .get();

      for (var doc in querySnapshot.docs) {
        registeredPhones.add(doc.data()['phone']);
      }
    }

    List<AppContact> processedContacts = [];
    for (var contact in phoneContacts) {
      if (contact.phones.isNotEmpty) {
        String? originalPhoneNumber = contact.phones.first.number;

        String cleanedPhoneNumber = originalPhoneNumber.replaceAll(RegExp(r'[\s()-]'), '');
        bool isRegistered = registeredPhones.contains(cleanedPhoneNumber);
        processedContacts.add(AppContact(contact: contact, isRegistered: isRegistered));
      }
    }

    // Sort contacts: registered users first, then alphabetically
    processedContacts.sort((a, b) {
      if (a.isRegistered && !b.isRegistered) return -1;
      if (!a.isRegistered && b.isRegistered) return 1;
      return a.contact.displayName.compareTo(b.contact.displayName);
    });

    if (mounted) {
      setState(() {
        _appContacts = processedContacts;
        _filteredContacts = _appContacts;
        _isLoading = false;
      });
    }
  }

  void _inviteContact(AppContact appContact) {
    // Use the share_plus package to invite
    Share.share('Hey! Let\'s connect on Talkbase. Download the app here: [Your App Link]');
  }

  Future<void> _chatWithContact(AppContact appContact) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || appContact.contact.phones.isEmpty) {
      debugPrint("Cannot start chat: Current user is not logged in or contact has no phone number.");
      return;
    }

    // Show a loading indicator while we find/create the chat
    // You might want to use a more sophisticated state management solution
    setState(() {
      _isLoading = true;
    });

    try {
      // STEP 1: Get the contact's user data (including uid) from Firestore.
      // Clean the phone number to match the format in your database.
      final String cleanedPhoneNumber = appContact.contact.phones.first.number.replaceAll(RegExp(r'[\s()-]'), '');

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: cleanedPhoneNumber)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        debugPrint("Could not find a registered user for this contact.");
        // Optionally, show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This contact is not a registered user.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final String contactUid = userQuery.docs.first.id;
      final List<String> participants = [currentUser.uid, contactUid]..sort();

      // STEP 2: Check if a chat room with these two participants already exists.
      final chatQuery = await FirebaseFirestore.instance
          .collection('ChatRoom')
          .where('participants', isEqualTo: participants)
          .limit(1)
          .get();

      String chatRoomId;

      if (chatQuery.docs.isNotEmpty) {
        // Chat already exists, get its ID.
        chatRoomId = chatQuery.docs.first.id;
        debugPrint("Chat room found: $chatRoomId");
      } else {
        // Chat does not exist, create a new one.
        debugPrint("No chat room found. Creating a new one.");
        chatRoomId = await _createChatRoom(
          appContact.contact.displayName, // Use contact's name for the room name
          [contactUid], // Pass the other participant's ID
        );
      }

      // STEP 3: Navigate to the chat screen.
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(chatRoomId: chatRoomId),
          ),
        );
      }

    } catch (e) {
      debugPrint("Error starting chat: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _createChatRoom(String name, List<String> participants) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Ensure the current user is not already in the list before adding
      if (!participants.contains(currentUser.uid)) {
        participants.add(currentUser.uid);
      }
    }

    // For one-on-one chats, it's good practice to sort participants
    // to create a consistent, unique identifier for the room.
    participants.sort();

    final now = DateTime.now();
    final chatRoomRef = FirebaseFirestore.instance.collection('ChatRoom').doc();

    await chatRoomRef.set({
      'id': chatRoomRef.id,
      'name': name,
      'createdBy': currentUser!.uid,
      'createdOn': now,
      'participants': participants,
      'isGroupChat': participants.length > 2,
    });

    // Return the new chat room's ID
    return chatRoomRef.id;
  }

  /// **NEW**: Builds the AppBar when search is active.
  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearchActive = false;
            _searchController.clear();
          });
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search contacts...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAwesomeAppBar(
        title: _isSelectionMode ? "Select Contacts (${_selectedContacts.length})" : "Contacts",
        leadingAction: _isSelectionMode
            ?
            IconButton(
              onPressed: _toggleSelectionMode,
              icon: const Icon(Icons.cancel),
            )
        : null,
        mainAction: !_isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.group_add),
          onPressed: _toggleSelectionMode,
          tooltip: "New Group",
        )
        : null,
        isSearchActive: _isSearchActive,
        searchController: _searchController,
        hasSearchButton: true,
        onSearchPressed: () {
          setState(() {
            _isSearchActive = true;
          });
        },
        onSearchClosed: () {
          setState(() {
            _isSearchActive = false;
            _searchController.clear();
          });
        },
      ),
      floatingActionButton: _isSelectionMode && _selectedContacts.isNotEmpty
          ? FloatingActionButton(
        onPressed: _navigateToCreateGroupPage,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.arrow_forward),
      )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_permissionDenied) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Permission to access contacts was denied. Please enable it in your phone settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    if (_filteredContacts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchContactsAndCheckStatus,
        child: Stack(
          children: <Widget>[
            ListView(),
            Center(
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'No contacts found for "${_searchController.text}"'
                    : 'No contacts found on your phone.',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    if (_appContacts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchContactsAndCheckStatus,
        child: ListView.builder(
          itemCount: _filteredContacts.length,
          itemBuilder: (context, index) {
            final appContact = _filteredContacts[index];
            final contact = appContact.contact;

            return ListTile(
              onTap: () {
                // In selection mode, tapping toggles the selection.
                if (_isSelectionMode) {
                  if (appContact.isRegistered) {
                    _toggleContactSelection(appContact);
                  }
                } else {
                  // In normal mode, tapping starts a one-on-one chat.
                  if (appContact.isRegistered) {
                    _chatWithContact(appContact);
                  } else {
                    _inviteContact(appContact);
                  }
                }
              },
              leading: CircleAvatar(
                backgroundImage: contact.photoOrThumbnail != null ? MemoryImage(contact.photoOrThumbnail!) : null,
                child: contact.photoOrThumbnail == null ? Text(contact.displayName.isNotEmpty ? contact.displayName[0] : "") : null,
              ),
              title: Text(contact.displayName),
              subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : "No number"),
              trailing: _isSelectionMode
                  ? appContact.isRegistered
                  ? Checkbox(
                    value: _selectedContacts.contains(appContact),
                    onChanged: (_) => _toggleContactSelection(appContact),
                    activeColor: Colors.purple,
                  )
                  : null
                  : appContact.isRegistered
                  ? ElevatedButton(
                onPressed: () => _chatWithContact(appContact),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Chat'),
              )
                  : OutlinedButton(
                onPressed: () => _inviteContact(appContact),
                child: const Text('Invite'),
              ),
            );
          },
        ),
      );
    }

    // Display the list of contacts wrapped in the RefreshIndicator
    return RefreshIndicator(
      onRefresh: _fetchContactsAndCheckStatus,
      child: ListView.builder(
        itemCount: _filteredContacts.length, // Use the filtered list
        itemBuilder: (context, index) {
          final appContact = _filteredContacts[index]; // Use the filtered list
          final contact = appContact.contact;

          return ListTile(
            onTap: () {
              // In selection mode, tapping toggles the selection.
              if (_isSelectionMode) {
                if (appContact.isRegistered) {
                  _toggleContactSelection(appContact);
                }
              } else {
                // In normal mode, tapping starts a one-on-one chat.
                if (appContact.isRegistered) {
                  _chatWithContact(appContact);
                } else {
                  _inviteContact(appContact);
                }
              }
            },
            leading: CircleAvatar(
              backgroundImage: contact.photoOrThumbnail != null ? MemoryImage(contact.photoOrThumbnail!) : null,
              child: contact.photoOrThumbnail == null ? Text(contact.displayName.isNotEmpty ? contact.displayName[0] : "") : null,
            ),
            title: Text(contact.displayName),
            subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : "No number"),
            trailing: appContact.isRegistered
                ? ElevatedButton(
              onPressed: () => _chatWithContact(appContact),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Chat'),
            )
                : OutlinedButton(
              onPressed: () => _inviteContact(appContact),
              child: const Text('Invite'),
            ),
          );
        },
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      // Clear selections when exiting selection mode
      if (!_isSelectionMode) {
        _selectedContacts.clear();
      }
    });
  }

  void _toggleContactSelection(AppContact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  void _navigateToCreateGroupPage() {
    if (_selectedContacts.isEmpty) return;

    // Navigate to a new page to set the group name and create the chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupPage(
          initialMembers: _selectedContacts,
        ),
      ),
    ).then((groupCreated) {
      // After returning, exit selection mode if group was created
      if (groupCreated == true) {
        _toggleSelectionMode();
      }
    });
  }
}