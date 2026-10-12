# Reminders: pending before Play Store launch

## 1. Change the Android application ID
The app still uses the placeholder `com.example.arunachal_exam_app`. The Play Store
rejects `com.example.*`, and the ID can never change after the first upload.

Steps when ready:
1. Pick the final ID, e.g. `in.arunachalexam.app`.
2. Firebase Console → Project settings → Add app → Android, using the new package name.
3. Download the new `google-services.json` → replace `android/app/google-services.json`.
4. Update `applicationId` in `android/app/build.gradle` and the Kotlin package /
   folder path of `MainActivity.kt`.
5. Add the SHA-1 of `android/app/upload-keystore.jks` to the new Firebase Android app
   (needed for Google Sign-In):
   `keytool -list -v -keystore android/app/upload-keystore.jks -alias upload`

## 2. Review Firestore security rules
There is no `firestore.rules` in this repo, so the live rules are unknown.
`web_admin_portal.html` writes to Firestore with only the web API key, which works
only if the rules allow unauthenticated writes.

Steps:
1. Firebase Console → Firestore Database → Rules: check for `allow read, write: if true;`
   or rules that expired in "test mode".
2. Restrict writes to signed-in admins, and users to their own `users/{uid}` document.
3. Commit the rules as `firestore.rules` so they are reviewed with the code.

## Related, already done (2026-10-10)
- Supabase writes locked to admins (`migrations/006_lock_down_writes.sql`, applied).
- Release builds are signed with `android/app/upload-keystore.jks` (gitignored). Keep
  that file and `android/key.properties` backed up somewhere safe; enroll in Play App
  Signing on first upload so a lost upload key can be reset.
- Build command: `flutter build apk --release --dart-define-from-file=dart_defines.env`
