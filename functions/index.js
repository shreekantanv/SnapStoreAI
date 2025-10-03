/**
 * @fileoverview Cloud Functions for the AI Tool Store.
 *
 * This file is now minimal after the removal of the API service.
 * It previously defined the backend logic that handled tool execution,
 * credit management, and payment webhooks. It now only initializes
 * the Firebase Admin SDK, but contains no active Cloud Functions.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
require("dotenv").config();

// Initialize Firebase Admin SDK
// This is required for any potential future backend interactions with
// Firestore or Auth.
admin.initializeApp();

// All API endpoints (`/runTool`, `/purchaseWebhook`, `/logActivity`) and the
// Express app have been removed as per the user's request to eliminate the
// backend API service.