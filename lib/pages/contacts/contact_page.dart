import 'package:flutter/material.dart';
import 'package:talkbase/widgets/app_bar.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAwesomeAppBar(title: "Contacts", hasBackButton: false),
      body: const Center(
        child: Text(
          'Contacts Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}