/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.createAdminUser = functions.https.onRequest(async (req, res) => {
  try {
    // Create user with email and password
    const userRecord = await admin.auth().createUser({
      email: "admin@gmail.com",
      password: "Admin@123",
      emailVerified: true,
    });

    // Set custom claims
    await admin.auth().setCustomUserClaims(userRecord.uid, {
      roles: ["admin"],
    });

    // Create admin document in Firestore
    await admin.firestore().collection("adminUsers").doc(userRecord.uid).set({
      email: "admin@gmail.com",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      role: "admin",
    });

    // Create user profile
    await admin.firestore().collection("users").doc(userRecord.uid).set({
      name: "Admin",
      email: "admin@gmail.com",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      role: "admin",
    });

    res.json({
      message: "Admin user created successfully",
      uid: userRecord.uid,
    });
  } catch (error) {
    console.error("Error creating admin user:", error);
    res.status(500).json({
      error: "Failed to create admin user",
      details: error.message,
    });
  }
});
