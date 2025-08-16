import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_bar.dart';
import 'contact_page.dart';

class CreateGroupPage extends StatefulWidget {
  final List<AppContact> initialMembers;
  const CreateGroupPage({super.key, required this.initialMembers});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Get the UIDs of the selected contacts
      List<String> participantUids = [];
      for (var appContact in widget.initialMembers) {
        // You'll need a way to get the UID from an AppContact.
        // This might involve another quick Firestore lookup or storing it earlier.
        // For now, let's assume you can get it.
        final uid = await _getUidForContact(appContact);
        if (uid != null) {
          participantUids.add(uid);
        }
      }

      // 2. Add the current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !participantUids.contains(currentUser.uid)) {
        participantUids.add(currentUser.uid);
      }

      // 3. Create the chat room in Firestore
      final chatRoomRef = FirebaseFirestore.instance.collection('ChatRoom').doc();
      await chatRoomRef.set({
        'id': chatRoomRef.id,
        'name': _nameController.text.trim(),
        'createdBy': currentUser!.uid,
        'createdOn': FieldValue.serverTimestamp(),
        'participants': participantUids,
        'isGroupChat': true, // Differentiate from one-on-one chats
        'groupIconUrl': '', // Placeholder for group icon
      });

      // Pop back to the contacts page, passing 'true' to indicate success
      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper to get UID (you may need to implement this robustly)
  Future<String?> _getUidForContact(AppContact contact) async {
    final phone = contact.contact.phones.first.number.replaceAll(' ', '');
    final userQuery = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: phone).limit(1).get();
    if (userQuery.docs.isNotEmpty) {
      return userQuery.docs.first.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAwesomeAppBar(title: 'New Group', hasBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Participants", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.initialMembers.length,
                itemBuilder: (context, index) {
                  final member = widget.initialMembers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.contact.photoOrThumbnail != null ? MemoryImage(member.contact.photoOrThumbnail!) : null,
                      child: member.contact.photoOrThumbnail == null ? Text(member.contact.displayName.isNotEmpty ? member.contact.displayName[0] : "") : null,
                    ),
                    title: Text(member.contact.displayName),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createGroup,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.check),
      ),
    );
  }
}