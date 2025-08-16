// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// import 'call_screen.dart'; // Your existing Agora call screen
//
// class IncomingCallScreen extends StatefulWidget {
//   final String callerName;
//   final String channelName;
//
//   const IncomingCallScreen({
//     super.key,
//     required this.callerName,
//     required this.channelName,
//   });
//
//   @override
//   State<IncomingCallScreen> createState() => _IncomingCallScreenState();
// }
//
// class _IncomingCallScreenState extends State<IncomingCallScreen> {
//   // --- Logic for Declining the Call ---
//   Future<void> _declineCall() async {
//     try {
//       // Update the call document in Firestore to show it was declined
//       await FirebaseFirestore.instance
//           .collection('calls')
//           .doc(widget.channelName)
//           .update({'status': 'declined'});
//     } catch (e) {
//       print("Error declining call: $e");
//     } finally {
//       // Close the incoming call screen
//       if (mounted) {
//         Navigator.pop(context);
//       }
//     }
//   }
//
//   // --- Logic for Accepting the Call ---
//   Future<void> _acceptCall() async {
//     try {
//       // 1. Update the call document to show it was accepted
//       await FirebaseFirestore.instance
//           .collection('calls')
//           .doc(widget.channelName)
//           .update({'status': 'accepted'});
//
//       // 2. Fetch an Agora token for the receiver
//       final token = await _fetchAgoraToken(widget.channelName); // You need this function
//
//       // 3. Navigate to the actual call screen, replacing the incoming call screen
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CallScreen(
//               channelName: widget.channelName,
//               token: token,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       print("Error accepting call: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error accepting call: ${e.toString()}')),
//         );
//       }
//     }
//   }
//
//   // NOTE: You'll need to have the _fetchAgoraToken function available here.
//   // It's best to move it to a dedicated service class.
//   Future<String> _fetchAgoraToken(String channelName) async {
//     // ... your existing token fetching logic using Firebase Functions ...
//     return "YOUR_FETCHED_TOKEN"; // Placeholder
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.purple.shade800, Colors.black54],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             // Caller Info
//             Column(
//               children: [
//                 const CircleAvatar(
//                   radius: 60,
//                   backgroundColor: Colors.white24,
//                   child: Icon(Icons.person, size: 70, color: Colors.white),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   widget.callerName,
//                   style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   "Incoming Call...",
//                   style: TextStyle(fontSize: 18, color: Colors.white70),
//                 ),
//               ],
//             ),
//
//             // Action Buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Decline Button
//                 _buildActionButton(
//                   onPressed: _declineCall,
//                   icon: Icons.call_end,
//                   backgroundColor: Colors.red,
//                   label: "Decline",
//                 ),
//
//                 // Accept Button
//                 _buildActionButton(
//                   onPressed: _acceptCall,
//                   icon: Icons.call,
//                   backgroundColor: Colors.green,
//                   label: "Accept",
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper widget for the action buttons
//   Widget _buildActionButton({
//     required VoidCallback onPressed,
//     required IconData icon,
//     required Color backgroundColor,
//     required String label,
//   }) {
//     return Column(
//       children: [
//         RawMaterialButton(
//           onPressed: onPressed,
//           shape: const CircleBorder(),
//           elevation: 2.0,
//           fillColor: backgroundColor,
//           padding: const EdgeInsets.all(18.0),
//           child: Icon(icon, color: Colors.white, size: 35.0),
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
//       ],
//     );
//   }
// }