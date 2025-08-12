// functions/index.js

/**
 * Cloud Functions (GCF v2) for the AI Tool Store.
 * - Express app exposed via v2 onRequest
 * - Firestore transactions for credits/ledger
 * - xAI (Grok) via OpenAI-compatible SDK
 */

// Firebase Admin (modular)

const { onRequest } = require("firebase-functions/v2/https");
const express = require("express");
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");

// Initialize Admin with default credentials (provided by GCF v2)
initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const auth = getAuth();

const app = express();
app.use(express.json());

// Lazy-load OpenAI only when needed (avoid startup crashes)
function getXaiClient() {
  const key = 'resolveXaiKey()';
  if (!key) return null;
  const OpenAI = require("openai");
  return new OpenAI({ apiKey: key, baseURL: "https://api.x.ai/v1" });
}

// ----- Auth middleware
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization || "";
  if (!authHeader.startsWith("Bearer ")) {
    return res.status(401).send("Unauthorized: No token provided.");
  }
  try {
    const idToken = authHeader.slice("Bearer ".length);
    const decoded = await auth.verifyIdToken(idToken);
    req.user = decoded;
    next();
  } catch {
    return res.status(401).send("Unauthorized: Invalid token.");
  }
};

// ----- Health check
app.get("/", (_req, res) => res.status(200).send({ ok: true }));

// ----- Routes
app.post("/runTool", authenticate, async (req, res) => {
  const { toolId, model, prompt } = req.body || {};
  const { uid } = req.user || {};
  if (!toolId || !model || !prompt) {
    return res.status(400).send("Missing required fields: toolId, model, or prompt.");
  }

  const creditsCost = model === "gpt-4" ? 2 : 1;
  const userRef = db.collection("users").doc(uid);
  const ledgerRef = userRef.collection("ledger").doc();

  try {
    // Atomic debit
    await db.runTransaction(async (tx) => {
      const userDoc = await tx.get(userRef);
      if (!userDoc.exists) throw new Error("User not found.");

      const creditsRemaining = userDoc.data().creditsRemaining || 0;
      if (creditsRemaining < creditsCost) throw new Error("Insufficient credits.");

      tx.update(userRef, { creditsRemaining: creditsRemaining - creditsCost });
      tx.set(ledgerRef, {
        type: "debit",
        amount: -creditsCost,
        model,
        ts: FieldValue.serverTimestamp(),
      });
    });

    let aiResponse;

    if (toolId === "political_leaning_analyzer") {
      const xai = getXaiClient();
      if (!xai) {
        return res.status(500).send("Server not configured for AI calls (missing API key).");
      }

      const completion = await xai.chat.completions.create({
        model: "grok-4", // replace with your available model ID if needed
        messages: [
          {
            role: "system",
            content:
              "You analyze political leaning from public social activity. Return JSON with: leaning (0..1), summary (string), topicBreakdown (array of {topic, tag, score}), keywordClouds (array of string arrays). No extra text.",
          },
          { role: "user", content: `Analyze political leaning for: ${prompt}` },
        ],
        response_format: { type: "json_object" },
        temperature: 0.2,
      });

      const content = completion.choices?.[0]?.message?.content || "{}";
      try {
        aiResponse = JSON.parse(content);
      } catch {
        aiResponse = { summary: content };
      }
    } else {
      aiResponse = `Mocked response from ${model} for: "${String(prompt).slice(0, 50)}..."`;
    }

    return res.status(200).send({ result: aiResponse });
  } catch (err) {
    if (err.message === "Insufficient credits.") {
      return res.status(402).send("Payment Required: Insufficient credits to run the tool.");
    }
    return res.status(500).send("An internal error occurred.");
  }
});

app.post("/purchaseWebhook", async (req, res) => {
  const { provider, payload } = req.body || {};
  try {
    let uid, creditsToAdd, packName;

    if (provider === "stripe") {
      uid = payload?.client_reference_id;
      creditsToAdd = payload?.credits_purchased;
      packName = payload?.pack_name;
    } else if (provider === "google_play" || provider === "app_store") {
      uid = payload?.uid;
      creditsToAdd = payload?.credits_purchased;
      packName = payload?.pack_name;
    } else {
      return res.status(400).send("Unsupported payment provider.");
    }

    if (!uid || !creditsToAdd) {
      return res.status(400).send("Missing user ID or credit amount from webhook payload.");
    }

    const userRef = db.collection("users").doc(uid);
    const ledgerRef = userRef.collection("ledger").doc();

    await db.runTransaction(async (tx) => {
      const userDoc = await tx.get(userRef);
      const currentCredits = userDoc.exists ? userDoc.data().creditsRemaining || 0 : 0;

      const updateData = { creditsRemaining: currentCredits + creditsToAdd };

      const isPremiumPurchase = !!payload?.isPremium;
      if (isPremiumPurchase) {
        const premiumExpires = new Date();
        premiumExpires.setDate(premiumExpires.getDate() + 30);
        updateData.isPremium = true;
        updateData.premiumExpires = Timestamp.fromDate(premiumExpires);
      }

      if (userDoc.exists) tx.update(userRef, updateData);
      else tx.set(userRef, { ...updateData, createdAt: FieldValue.serverTimestamp() });

      tx.set(ledgerRef, {
        type: "purchase",
        amount: creditsToAdd,
        details: `Purchase of ${packName} pack`,
        ts: FieldValue.serverTimestamp(),
      });
    });

    return res.status(200).send({ success: true });
  } catch {
    return res.status(500).send("Webhook processing failed.");
  }
});

app.post("/logActivity", authenticate, async (req, res) => {
  const { toolId, inputs, outputs } = req.body || {};
  const { uid } = req.user || {};
  if (!toolId || !inputs || !outputs) {
    return res.status(400).send("Missing required fields: toolId, inputs, or outputs.");
  }

  try {
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) return res.status(404).send("User not found.");

    const data = userDoc.data();
    const isPremium =
      data.isPremium === true &&
      data.premiumExpires &&
      data.premiumExpires.toDate() > new Date();

    if (isPremium) {
      await db.collection("user_activity").doc().set({
        uid,
        toolId,
        inputs,
        outputs,
        ts: FieldValue.serverTimestamp(),
      });
    }

    return res.status(200).send({ success: true });
  } catch {
    return res.status(500).send("An internal error occurred while logging activity.");
  }
});

// Export GCF v2 HTTPS function
exports.api = onRequest(
  { region: "us-central1", cors: true, memory: "512MiB", cpu: 1, timeoutSeconds: 120 },
  app
);