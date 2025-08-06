# AI Tool Store - MVP Skeleton
[![Built by Jules](https://img.shields.io/badge/Built_by-Jules-blueviolet)](https://anthropic.com)

This repository contains the production-ready MVP skeleton for the **AI Tool Store**, a Flutter and Firebase application. This project was scaffolded by Jules based on a detailed project specification.

The goal of this skeleton is to provide a clean, scalable, and compilable foundation for building a cross-platform app where users can purchase and use credits for various AI tools.

## Key Features & Architecture

*   **Cross-Platform Client**: A single Flutter codebase (`/client`) for Android, iOS, and Web (PWA).
*   **Serverless Backend**: Firebase Cloud Functions (`/functions`) act as a secure "token gateway" to interact with third-party AI models and manage the credit ledger.
*   **Secure by Design**: Client-side writes to Firestore are disabled. All mutations (debiting/crediting) are handled by the backend, which validates user identity via Firebase Auth tokens.
*   **Stateless Backend Logic**: User prompts and AI model outputs are never persisted in the database, ensuring user privacy.
*   **Dynamic Tools**: Tools are defined by JSON files in `client/assets/tools`, allowing for easy addition or modification of tools without deploying a new app version.

## Project Structure

```
.
├── client/              # Flutter Application (Frontend)
│   ├── assets/
│   │   └── tools/       # JSON tool definitions
│   ├── lib/
│   │   ├── main.dart    # App entry point
│   │   ├── src/
│   │   │   ├── api/         # Service for calling backend
│   │   │   ├── features/    # Screen-based features (UI)
│   │   │   ├── models/      # Dart data models
│   │   │   ├── routing/     # GoRouter configuration
│   │   │   ├── services/    # Services (e.g., Firestore)
│   │   │   └── shared/      # Shared widgets and providers
│   │   └── firebase_options.dart # Placeholder for Firebase config
│   └── pubspec.yaml
├── functions/           # Firebase Cloud Functions (Backend)
│   ├── index.js         # Main backend logic
│   ├── package.json
│   └── .env.example     # Example environment variables
└── firestore.rules      # Security rules for Firestore
```

## Getting Started

### 1. Firebase Project Setup

1.  **Create a Firebase Project**: Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
2.  **Enable Authentication**: In the Firebase Console, go to `Authentication` -> `Sign-in method` and enable **Google** and **Anonymous** sign-in providers.
3.  **Enable Firestore**: Go to `Firestore Database` and create a new database in production mode.
4.  **Upgrade to Blaze Plan**: Cloud Functions (especially with third-party API calls) and Stripe webhooks require the "Blaze" (Pay-as-you-go) plan.

### 2. Configure Flutter Client (`/client`)

1.  **Install FlutterFire CLI**: If you haven't already, install the Firebase CLI and FlutterFire CLI:
    ```bash
    npm install -g firebase-tools
    dart pub global activate flutterfire_cli
    ```
2.  **Configure Firebase for Flutter**: Navigate to the `client` directory and run the configuration command. This will replace the placeholder `lib/firebase_options.dart`.
    ```bash
    cd client
    flutterfire configure
    ```
    Follow the prompts to select your Firebase project and the platforms you want to support.
3.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the App**:
    ```bash
    flutter run
    ```

### 3. Configure Cloud Functions (`/functions`)

1.  **Install Dependencies**: Navigate to the `functions` directory:
    ```bash
    cd functions
    npm install
    ```
2.  **Set Environment Variables**:
    *   Copy `.env.example` to a new `.env` file: `cp .env.example .env`.
    *   Open `.env` and fill in the required API keys for the AI models (OpenAI, Anthropic, etc.) and your Stripe secret keys.
    *   **IMPORTANT**: The `.env` file is used for local emulation. For deployment, you must set these as secrets in the Google Cloud Secret Manager, which is the recommended secure way to handle them.
        ```bash
        firebase functions:secrets:set YOUR_SECRET_NAME
        ```
3.  **Deploy Functions**: From the `functions` directory, deploy your API:
    ```bash
    firebase deploy --only functions
    ```
    After deployment, Firebase will give you the URL for your API. You must update the `_baseUrl` constant in `client/lib/src/api/api_service.dart` with this URL.

### 4. Set Firestore Security Rules

1.  In the Firebase Console, go to `Firestore Database` -> `Rules`.
2.  Copy the content of the `firestore.rules` file from this repository and paste it into the rules editor.
3.  Click **Publish**.

---
This skeleton provides all the necessary wiring. The next steps would be to build out the UI for each screen, implement the payment flows using the `in_app_purchase` and `flutter_stripe` packages, and replace the mocked AI model calls in `functions/index.js` with actual API calls.
