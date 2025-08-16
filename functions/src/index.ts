// Use modern ES module imports for all packages
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineString} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {getMessaging} from "firebase-admin/messaging";

// It's good practice to use the TypeScript version of this package if using TS
import {RtcTokenBuilder, RtcRole} from "agora-access-token";

// Initialize the Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// --- NEW (v2): Define environment variables securely ---
// You'll need to set these values when deploying or using the Firebase CLI
// firebase functions:config:set agora.app_id="YOUR_ID"
// firebase functions:config:set agora.app_certificate="YOUR_CERTIFICATE"
const AGORA_APP_ID = defineString("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineString("AGORA_APP_CERTIFICATE");

export const sendCallNotification = onDocumentCreated(
  "calls/{callId}",
  async (event) => {
    const callData = event.data?.data();
    if (!callData) {
      console.log("No call data found.");
      return;
    }

    const receiverId = callData.receiverId;
    const callerName = callData.callerName;
    const channelName = callData.channelName;

    // Get the receiver's FCM token(s) from the 'users' collection
    const userDoc = await admin.firestore().collection("users")
      .doc(receiverId)
      .get();

    if (!userDoc.exists) {
      console.log(`User ${receiverId} not found.`);
      return;
    }

    // Assuming you store tokens in an array
    const tokens = userDoc.data()?.fcmTokens;
    if (!tokens || tokens.length === 0) {
      console.log(`No FCM tokens for user ${receiverId}.`);
      return;
    }

    // Send the notification
    console.log(`Sending call notification to user ${receiverId}`);
    return getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Incoming Call",
        body: `${callerName} is calling you.`,
      },
      // IMPORTANT: Send the call info in the data payload
      data: {
        type: "INCOMING_CALL",
        channelName: channelName,
        callerName: callerName,
      },
      // Set high priority for calls
      android: {
        priority: "high",
      },
    });
  }
);

// --- REFACTORED (v2): generateAgoraToken ---
export const generateAgoraToken = onCall(async (request) => {
  // Ensure the user is authenticated.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const channelName = request.data.channelName;
  // const uid = request.auth.uid; // Use the authenticated user's UID

  if (!channelName) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with a channelName."
    );
  }

  // Set the role and expiration time for the token.
  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600; // 1 hour
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  // Build the token, making sure to use .value() for the defined params
  const token = RtcTokenBuilder.buildTokenWithUid(
    AGORA_APP_ID.value(),
    AGORA_APP_CERTIFICATE.value(),
    channelName,
    0,
    role,
    privilegeExpiredTs
  );

  return {token: token};
});


// --- UNCHANGED (Already v2): sendNotificationOnNewMessage ---
export const sendNotificationOnNewMessage = onDocumentCreated(
  "ChatRoom/{chatRoomId}/messages/{messageId}",
  async (event) => {
    // ... your existing code for this function is correct
    // (The logic inside this function does not need to be changed)
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event.");
      return;
    }
    const messageData = snapshot.data();
    const chatRoomId = event.params.chatRoomId;
    const senderId = messageData.senderId;
    const senderName = messageData.senderName;
    const messageText = messageData.message;
    const chatRoomRef = db.collection("ChatRoom").doc(chatRoomId);
    const chatRoomDoc = await chatRoomRef.get();
    if (!chatRoomDoc.exists) {
      console.log("Chat room not found.");
      return;
    }
    const chatRoomData = chatRoomDoc.data();
    if (!chatRoomData || !chatRoomData.participants) {
      console.log("No participants found in the chat room.");
      return;
    }
    const participants: string[] = chatRoomData.participants;
    const tokens: string[] = [];
    for (const userId of participants) {
      if (userId !== senderId) {
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          if (userData && userData.fcmTokens) {
            tokens.push(...userData.fcmTokens);
          }
        }
      }
    }
    if (tokens.length === 0) {
      console.log("No device tokens to send notifications to.");
      return;
    }
    console.log(`Sending notification to ${tokens.length} tokens.`);
    return getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: `New message from ${senderName}`,
        body: messageText,
      },
      data: {
        chatRoomId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    });
  }
);


// --- UNCHANGED (Already v2): incrementUnreadCounter ---
export const incrementUnreadCounter = onDocumentCreated(
  "ChatRoom/{chatRoomId}/messages/{messageId}",
  async (event) => {
    // ... your existing code for this function is correct
    // (The logic inside this function does not need to be changed)
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event.");
      return;
    }
    const messageData = snapshot.data();
    const senderId = messageData.senderId;
    const chatRoomRef = admin.firestore()
      .collection("ChatRoom")
      .doc(event.params.chatRoomId);
    const chatRoomDoc = await chatRoomRef.get();
    if (!chatRoomDoc.exists) {
      console.log("Chat room not found.");
      return;
    }
    const chatRoomData = chatRoomDoc.data();
    if (!chatRoomData || !chatRoomData.participants) {
      console.log("No participants found.");
      return;
    }
    const batch = admin.firestore().batch();
    const participants: string[] = chatRoomData.participants;
    participants.forEach((userId) => {
      if (userId !== senderId) {
        const unreadCountField = `unreadCounts.${userId}`;
        batch.update(chatRoomRef, {
          [unreadCountField]: admin.firestore.FieldValue.increment(1),
        });
      }
    });
    return batch.commit();
  }
);
