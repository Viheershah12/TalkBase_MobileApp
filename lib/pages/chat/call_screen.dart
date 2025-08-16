// import 'dart:async';
//
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// // Your Agora App ID from the console
// const String appId = "890a102a965942f7bb1b7f1a9b249d8c";
//
// class CallScreen extends StatefulWidget {
//   final String channelName;
//   final String? token; // The token is required for production apps
//
//   const CallScreen({
//     super.key,
//     required this.channelName,
//     this.token,
//   });
//
//   @override
//   State<CallScreen> createState() => _CallScreenState();
// }
//
// class _CallScreenState extends State<CallScreen> {
//   late RtcEngine _engine; // The Agora engine instance
//
//   int? _remoteUid; // UID of the remote user
//   bool _localUserJoined = false;
//   bool _isMuted = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initAgora();
//   }
//
//   // --- Initialize Agora ---
//   Future<void> _initAgora() async {
//     // Request camera and microphone permissions
//     await [Permission.microphone, Permission.camera].request();
//
//     // Create the engine
//     _engine = createAgoraRtcEngine();
//     await _engine.initialize(RtcEngineContext(appId: appId));
//
//     // Set up event handlers
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//           debugPrint("local user ${connection.localUid} joined");
//           setState(() => _localUserJoined = true);
//         },
//         onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//           debugPrint("remote user $remoteUid joined");
//           setState(() => _remoteUid = remoteUid);
//         },
//         onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
//           debugPrint("remote user $remoteUid left channel");
//           setState(() => _remoteUid = null);
//           Navigator.of(context).pop(); // End call when the other user leaves
//         },
//       ),
//     );
//
//     // Enable video and join the channel
//     await _engine.enableVideo();
//     await _engine.startPreview();
//     await _engine.joinChannel(
//       token: widget.token!, // Use the token passed to the widget
//       channelId: widget.channelName,
//       uid: 0, // Let Agora assign a UID
//       options: const ChannelMediaOptions(),
//     );
//   }
//
//   // --- Clean up resources when the widget is disposed ---
//   @override
//   void dispose() {
//     _dispose();
//     super.dispose();
//   }
//
//   Future<void> _dispose() async {
//     await _engine.leaveChannel();
//     await _engine.release();
//   }
//
//   // --- Build the UI ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Remote user's video
//           Center(child: _remoteVideo()),
//           // Local user's video
//           Align(
//             alignment: Alignment.topLeft,
//             child: SizedBox(
//               width: 120,
//               height: 160,
//               child: _localUserJoined
//                   ? AgoraVideoView(
//                 controller: VideoViewController(
//                   rtcEngine: _engine,
//                   canvas: const VideoCanvas(uid: 0),
//                 ),
//               )
//                   : const Center(child: CircularProgressIndicator()),
//             ),
//           ),
//           // Call controls
//           _toolbar(),
//         ],
//       ),
//     );
//   }
//
//   // --- UI Helper Widgets ---
//
//   // Widget for the remote user's video feed
//   Widget _remoteVideo() {
//     if (_remoteUid != null) {
//       return AgoraVideoView(
//         controller: VideoViewController.remote(
//           rtcEngine: _engine,
//           canvas: VideoCanvas(uid: _remoteUid),
//           connection: RtcConnection(channelId: widget.channelName),
//         ),
//       );
//     } else {
//       return const Text(
//         'Waiting for user to join...',
//         textAlign: TextAlign.center,
//       );
//     }
//   }
//
//   // Widget for the call controls at the bottom
//   Widget _toolbar() {
//     return Container(
//       alignment: Alignment.bottomCenter,
//       padding: const EdgeInsets.symmetric(vertical: 48),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           // Mute button
//           RawMaterialButton(
//             onPressed: () {
//               setState(() => _isMuted = !_isMuted);
//               _engine.muteLocalAudioStream(_isMuted);
//             },
//             shape: const CircleBorder(),
//             elevation: 2.0,
//             fillColor: _isMuted ? Colors.blueAccent : Colors.white,
//             padding: const EdgeInsets.all(12.0),
//             child: Icon(
//               _isMuted ? Icons.mic_off : Icons.mic,
//               color: _isMuted ? Colors.white : Colors.blueAccent,
//               size: 20.0,
//             ),
//           ),
//           // Hang up button
//           RawMaterialButton(
//             onPressed: () => Navigator.of(context).pop(),
//             shape: const CircleBorder(),
//             elevation: 2.0,
//             fillColor: Colors.redAccent,
//             padding: const EdgeInsets.all(15.0),
//             child: const Icon(Icons.call_end, color: Colors.white, size: 35.0),
//           ),
//           // Switch camera button
//           RawMaterialButton(
//             onPressed: () => _engine.switchCamera(),
//             shape: const CircleBorder(),
//             elevation: 2.0,
//             fillColor: Colors.white,
//             padding: const EdgeInsets.all(12.0),
//             child: const Icon(
//               Icons.switch_camera,
//               color: Colors.blueAccent,
//               size: 20.0,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }