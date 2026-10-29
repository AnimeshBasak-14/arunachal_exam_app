# Dawnlit launch setup

Console steps the code can't do for you, in order. Each says how to check it worked.

## 1. Package name: done

The app ID is **`com.zap.dawnlit`** (Android `applicationId`, iOS and macOS bundle ID).
It can never change after the first Play upload. Until step 2 is done, Android builds fail
with "No matching client found for package name 'com.zap.dawnlit'", because
`google-services.json` still describes the old ID.

## 2. Firebase Authentication (fixes the "weird Gmail picker")

Firebase project: `arunachal-exam-app`.

1. **Authentication → Sign-in method**: Google is on. Also click **Add new provider →
   Email/Password** and enable it (not the "Email link" option). Without it, email registration
   and sign-in are refused. SMS multi-factor is not needed.
2. **Project settings → Your apps → Add app → Android**: package name `com.zap.dawnlit`,
   nickname *Dawnlit*, and add these SHA fingerprints:

   | Key | SHA-1 | SHA-256 |
   | --- | --- | --- |
   | Upload key (`upload-keystore.jks`) | `31:CA:CA:07:61:B9:01:BD:3D:F5:E0:FC:CE:A0:ED:69:1D:B9:8E:75` | `61:69:EE:D6:32:B9:39:0E:6D:55:3F:0D:FB:D5:BC:2C:DA:75:8B:16:48:8E:D0:19:F0:BA:26:29:1C:16:4D:CA` |
   | Debug key (this PC) | `89:12:6D:33:88:3A:1C:8F:F7:A3:45:95:1F:8B:5B:BC:43:32:22:58` | `4E:EB:63:B2:7D:1D:B8:EB:4D:A3:48:B4:91:C6:3D:81:96:37:B7:9B:1B:0F:6A:B4:C2:77:4C:A0:3A:29:50:10` |
   | Play app signing key | copy from Play Console → Setup → App signing after the first upload | |

3. Download the new `google-services.json` into `android/app/`.
   **Check:** it now contains an `oauth_client` entry with `"client_type": 3`. Without it,
   Google sign-in shows "isn't available right now".
4. **Authentication → Templates**: set the sender name to *Dawnlit* for the verification and
   password-reset emails.

## 3. Firestore security rules

The app now signs everyone in with Firebase, so the database can be locked to each owner.
Deploy `firestore.rules` **when the new version is live** (older app versions don't sign in to
Firebase and will stop syncing profiles):

```
npm i -g firebase-tools
firebase login
firebase deploy --only firestore:rules
```

Or paste the file into Firebase Console → Firestore → Rules → Publish.

## 4. Google Maps key

1. Google Cloud Console (same project) → enable **Maps SDK for Android** (and **for iOS**).
   Mobile map loads are free; a billing account must still be attached.
2. Create an API key restricted to **Android apps** with the package name and the SHA-1s above,
   and to the Maps SDK APIs only.
3. Put it in `android/local.properties` (not in git):

   ```
   MAPS_API_KEY=AIza...
   ```

   For iOS create `ios/Flutter/Secrets.xcconfig` with `MAPS_API_KEY = AIza...`.
   **Check:** the GK map shows land and labels, not a blank grey grid.

## 5. AI tutor proxy (keeps the AI key out of the app)

Waiting on the choice of model. When it's chosen, update the model name in two places:
`AiService.model` in `lib/core/services/ai_service.dart` and `ALLOWED_MODELS` in
`supabase/functions/ai-tutor/index.ts`. If the model isn't a Gemini model, the proxy's
upstream URL and request format change too.


Release builds have no Gemini key, so the tutor calls the Supabase Edge Function in
`supabase/functions/ai-tutor`, which checks the user's Firebase sign-in:

```
npm i -g supabase
supabase login
supabase link --project-ref fllopztywwblbucvaths
supabase secrets set GEMINI_API_KEY=your-key FIREBASE_PROJECT_ID=arunachal-exam-app
supabase functions deploy ai-tutor --no-verify-jwt
```

Then in Google Cloud Console restrict the Gemini key to the *Generative Language API*, and set a
daily quota cap. **Check:** in a release build, the AI tutor answers a question.

## 6. Release build

Build **without** `--dart-define-from-file=.env` (that file holds server secrets):

```
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to a closed test track first. New
personal developer accounts need at least 12 testers for 14 days before production access.

## 7. Play Console forms

- **Data safety**: the app collects name, email, optional phone and city, optional profile photo
  (stored with the account), test results, and crash/analytics data (Firebase). No ads, no
  advertising ID (removed from the manifest).
- **Account deletion**: in-app at Account → Delete account. Play also asks for a web link where
  people can request deletion.
- **Government apps policy**: the store listing must say the app is independent and not affiliated
  with APPSC/APSSB (the same disclaimer is in Account → About).
