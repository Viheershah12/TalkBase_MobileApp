// Import the specific v2 functions and types we need
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {getMessaging} from "firebase-admin/messaging";

// Initialize the Firebase Admin SDK
admin.initializeApp();

// Get instances of Firestore and Cloud Messaging
const db = admin.firestore();

// Define and export the Cloud Function using the new v2 syntax
export const sendNotificationOnNewMessage = onDocumentCreated(
  // The path to listen to, with wildcards for dynamic IDs
  "ChatRoom/{chatRoomId}/messages/{messageId}",

  // The event handler, which now receives a single 'event' object
  async (event) => {
    // Get the data from the newly created document
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event.");
      return;
    }
    const messageData = snapshot.data();

    // Get the dynamic values from the path using event.params
    const chatRoomId = event.params.chatRoomId;
    const senderId = messageData.senderId;
    const senderName = messageData.senderName;
    const messageText = messageData.message;

    // Get the chat room to find all participants
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

    // Get the FCM tokens for all participants except the sender
    for (const userId of participants) {
      if (userId !== senderId) {
        const userDoc = await db.collection("users").doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          // Assuming fcmTokens is an array in your user document
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

    // Send the notification to all collected tokens
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

export const incrementUnreadCounter = onDocumentCreated(
  "ChatRoom/{chatRoomId}/messages/{messageId}",
  async (event) => {
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
