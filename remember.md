# Project Reminders & Launch Notes

## 1. Firebase Authentication: Enable Email/Password Provider
- **Status**: Currently OFF in the live Firebase project (`arunachal-exam-app`).
- **Action Required**: Must be toggled on manually in the Firebase Console:
  1. Go to Firebase Console → **Authentication** → **Sign-in method**.
  2. Click **Add new provider** → select **Email/Password**.
  3. Toggle **Enable** (leave "Email link / passwordless" unchecked) and click **Save**.
- **Impact**: Until Email/Password provider is enabled in Firebase Console, email registration and sign-in will fail (only Google sign-in works).
- **Fingerprints & Config**: The 4 SHA fingerprints (upload key and debug key) are added to the Dawnlit Android app in Firebase, and `google-services.json` contains the Google sign-in clients.

## 2. UI/UX Style Direction: White-and-Black Direction
- Updated `docs/ui_ux_upgrade_prompt.md` and notes with the white-and-black design direction.
- High-contrast, clean, airy, editorial styling optimized for clarity and large font scaling (130%+ text).

## 3. Release & Keystore Configuration
- **Package ID**: `com.zap.dawnlit`
- **Application Name**: `Dawnlit`
- **Keystore**: `android/app/upload-keystore.jks` with `android/key.properties` (gitignored).
- **Build Commands**:
  - Universal APK: `flutter build apk --release --dart-define-from-file=dart_defines.env`
  - Per-ABI APK: `flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.env`

