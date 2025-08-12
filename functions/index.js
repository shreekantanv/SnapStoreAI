/**
 * @fileoverview Cloud Functions for the AI Tool Store.
 *
 * This file defines the backend logic that handles tool execution, credit
 * management, and payment webhooks. It uses Express.js to create a simple
 * API service that is deployed as a single Cloud Function.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const app = express();

// Initialize Firebase Admin SDK
// This is required to interact with Firestore and Auth
admin.initializeApp();

const db = admin.firestore();

// --- Middleware ---

/**
 * Express middleware to verify the Firebase ID token from the Authorization header.
 * If valid, it attaches the decoded token to `req.user`.
 * If invalid, it sends a 401 Unauthorized response.
 */
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).send("Unauthorized: No token provided.");
  }

  const idToken = authHeader.split("Bearer ")[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken; // Decoded token contains uid, email, etc.
    next();
  } catch (error) {
    console.error("Error while verifying Firebase ID token:", error);
    res.status(401).send("Unauthorized: Invalid token.");
  }
};

// --- API Routes ---

/**
 * Route: POST /runTool
 * Requires authentication.
 *
 * This is the core function for running an AI tool.
 * 1. Verifies the user's token.
 * 2. Checks if the user has enough credits.
 * 3. Debits the required credits in a transaction.
 * 4. Calls the appropriate third-party AI model (stubbed).
 * 5. Returns the AI model's output.
 *
 * IMPORTANT: User prompts and AI outputs are never stored in Firestore.
 */
app.post("/runTool", authenticate, async (req, res) => {
  const { toolId, model, prompt } = req.body;
  const { uid } = req.user;

  if (!toolId || !model || !prompt) {
    return res.status(400).send("Missing required fields: toolId, model, or prompt.");
  }

  const creditsCost = model === "gpt-4" ? 2 : 1;
  const userRef = db.collection("users").doc(uid);
  const ledgerRef = userRef.collection("ledger").doc();

  try {
    // Run a transaction to ensure atomicity of credit check and debit.
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new Error("User not found."); // This will be caught and result in a 500
      }

      const creditsRemaining = userDoc.data().creditsRemaining || 0;
      if (creditsRemaining < creditsCost) {
        // Throw an error to abort the transaction.
        // We will catch this and send a 402 Payment Required.
        throw new Error("Insufficient credits.");
      }

      const newCredits = creditsRemaining - creditsCost;
      transaction.update(userRef, { creditsRemaining: newCredits });
      transaction.set(ledgerRef, {
        type: "debit",
        amount: -creditsCost,
        model: model,
        ts: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // --- AI Model Call (STUB) ---
    // In a real implementation, you would use the model name to call the correct
    // API (e.g., OpenAI, Anthropic, Google AI). The API keys should be stored
    // securely in environment variables.
    console.log(`Calling model ${model} for user ${uid}. Prompt: ${prompt}`);
    // MOCK RESPONSE:
    const aiResponse = `This is a mocked response from ${model} for your prompt: "${prompt.substring(0, 50)}..."`;

    // IMPORTANT: The prompt and response are held in memory only and not persisted.
    res.status(200).send({ result: aiResponse });

  } catch (error) {
    console.error("Error in /runTool:", error);
    if (error.message === "Insufficient credits.") {
      return res.status(402).send("Payment Required: Insufficient credits to run the tool.");
    }
    res.status(500).send("An internal error occurred.");
  }
});

/**
 * Route: POST /purchaseWebhook
 * This endpoint handles webhooks from payment providers (Stripe, Google Play, App Store).
 * 1. Verifies the webhook signature/receipt to ensure it's legitimate.
 * 2. Determines the user and the credit pack purchased.
 * 3. Atomically credits the user's account and logs the transaction.
 */
app.post("/purchaseWebhook", async (req, res) => {
  // Webhook verification and processing is highly provider-specific.
  // This is a STUB implementation.
  const { provider, payload } = req.body; // e.g., provider: 'stripe', 'google_play'

  try {
    let uid, creditsToAdd, packName;

    // --- Webhook Verification & Processing (STUB) ---
    if (provider === "stripe") {
      // 1. Verify Stripe webhook signature (essential for security).
      // const event = stripe.webhooks.constructEvent(req.rawBody, req.headers['stripe-signature'], process.env.STRIPE_WEBHOOK_SECRET);
      // 2. Handle the `checkout.session.completed` event.
      // 3. Extract metadata to identify the user and pack.
      uid = payload.client_reference_id; // Assume you passed uid in the Stripe session
      creditsToAdd = payload.credits_purchased; // Assume you have this in metadata
      packName = payload.pack_name;

    } else if (provider === "google_play" || provider === "app_store") {
      // For mobile, you'd verify the purchase receipt with the respective store's API.
      // This is a complex process involving another server-to-server call.
      uid = payload.uid;
      creditsToAdd = payload.credits_purchased;
      packName = payload.pack_name;
    } else {
      return res.status(400).send("Unsupported payment provider.");
    }

    if (!uid || !creditsToAdd) {
      return res.status(400).send("Missing user ID or credit amount from webhook payload.");
    }

    // --- Update Firestore ---
    const userRef = db.collection("users").doc(uid);
    const ledgerRef = userRef.collection("ledger").doc();

    await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        const currentCredits = userDoc.exists ? userDoc.data().creditsRemaining || 0 : 0;
        const newCredits = currentCredits + creditsToAdd;
        const isPremiumPurchase = payload.isPremium || false;

        const updateData = {
            creditsRemaining: newCredits,
        };

        if (isPremiumPurchase) {
            const premiumDurationDays = 30;
            const premiumExpires = new Date();
            premiumExpires.setDate(premiumExpires.getDate() + premiumDurationDays);

            updateData.isPremium = true;
            updateData.premiumExpires = admin.firestore.Timestamp.fromDate(premiumExpires);
        }

        if (userDoc.exists) {
            transaction.update(userRef, updateData);
        } else {
            // This case handles a new user making a purchase.
            transaction.set(userRef, {
                ...updateData,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        transaction.set(ledgerRef, {
            type: "purchase",
            amount: creditsToAdd,
            details: `Purchase of ${packName} pack`,
            ts: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

    console.log(`Successfully credited ${creditsToAdd} to user ${uid}.`);
    res.status(200).send({ success: true });

  } catch (error) {
    console.error("Error in /purchaseWebhook:", error);
    res.status(500).send("Webhook processing failed.");
  }
});

/**
 * Route: POST /logActivity
 * Requires authentication.
 * Logs a tool usage event for a premium user.
 */
app.post("/logActivity", authenticate, async (req, res) => {
    const { toolId, inputs, outputs } = req.body;
    const { uid } = req.user;

    if (!toolId || !inputs || !outputs) {
        return res.status(400).send("Missing required fields: toolId, inputs, or outputs.");
    }

    try {
        const userRef = db.collection("users").doc(uid);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            return res.status(404).send("User not found.");
        }

        const userData = userDoc.data();
        const isPremium = userData.isPremium === true &&
                          userData.premiumExpires &&
                          userData.premiumExpires.toDate() > new Date();

        if (isPremium) {
            const activityRef = db.collection("user_activity").doc();
            await activityRef.set({
                uid,
                toolId,
                inputs,
                outputs,
                ts: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        res.status(200).send({ success: true });
    } catch (error) {
        console.error("Error in /logActivity:", error);
        res.status(500).send("An internal error occurred while logging activity.");
    }
});


// Expose the Express API as a single Cloud Function
// The function name will be `api`, so the endpoint URL will be something like:
// https://<region>-<project-id>.cloudfunctions.net/api/runTool
exports.api = functions.https.onRequest(app);
