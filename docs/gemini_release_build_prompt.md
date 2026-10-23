# Gemini prompt: Donyi Prep release build (APK + AAB)

Copy everything below the line into Gemini (Gemini CLI, Antigravity or Android
Studio Gemini) with the workspace opened at `arunachal_exam_app/`.

---

You are building the release version of a Flutter app called **Donyi Prep**
(the Flutter project in `arunachal_exam_app/`, package id
`com.example.arunachal_exam_app`). It is an exam-preparation app for Arunachal
Pradesh state exams. The UI has just been redesigned on the git branch
`redesign/donyi-prep`. Your job is **only to verify, version, build, sign and
smoke-test** it. You are not designing anything.

## Ground rules (read first, follow throughout)

1. **Do not change UI, layout, colours, fonts or copy.** The redesign is
   finished. If you think something looks wrong, write it in your final report
   instead of editing it.
2. **Do not change the package id** (`applicationId` / `namespace` in
   `android/app/build.gradle`). Changing it breaks updates for existing users
   and the Firebase config.
3. **Never print, copy, commit or upload secrets:** `android/key.properties`,
   `android/app/upload-keystore.jks`, `dart_defines.env`, `.env`,
   `android/app/google-services.json`. Do not create a new keystore. If signing
   files are missing, **stop and tell the owner**: do not fall back to debug
   signing for a release.
4. **Do not touch the Supabase database, `migrations/`, or Firebase console
   settings.**
5. **Do not commit APK/AAB files.** Do not push to any remote unless the owner
   asks. The `web/` folder is a separate website deployed by GitHub Actions on
   push to `main`; leave it alone.
6. If a step fails, fix only what the failure points to, keep the fix minimal,
   and mention it in the report. If the fix would need a UI or data change,
   stop and ask.

## Step 1: Preflight

Run and record the output:

```
git status
git branch --show-current          # expect: redesign/donyi-prep
flutter --version                  # project was built with Flutter 3.47 / Dart 3.13
flutter doctor -v                  # Android toolchain must be OK
```

Confirm these exist (just check existence, do not open or print them):
`android/key.properties`, `android/app/upload-keystore.jks`,
`dart_defines.env`, `android/app/google-services.json`.

If `git status` shows the redesign as uncommitted changes, commit them on
`redesign/donyi-prep` (and only there) with:

```
git add -A
git commit -m "feat: Donyi Prep redesign: calm editorial UI, 4-tab shell, new exam engine"
```

Before committing, run `git status` again and make sure none of the secret files
from rule 3, and no `.apk`, `.aab` or `build/` output, is staged.

## Step 2: Clean, analyse, test

```
flutter clean
flutter pub get
flutter analyze        # must report: No issues found!
flutter test           # must report: All tests passed! (83 tests at hand-over)
```

Do not continue to the build if either fails. Fix the cause (not the test) and
re-run.

## Step 3: Bundle the fonts for offline first launch

The app uses Google Fonts **Inter** and **Playfair Display** through the
`google_fonts` package. That package downloads fonts at runtime, so a student
opening the app for the first time without data sees fallback fonts. Bundle
them instead:

1. Download the static TTFs from Google Fonts (fonts.google.com → Inter and
   Playfair Display → Download family; use the files in the `static/` folder).
2. Put exactly these files in `assets/google_fonts/` (names must match, because
   `google_fonts` finds bundled files by name):
   - `Inter-Light.ttf`, `Inter-Regular.ttf`, `Inter-Medium.ttf`,
     `Inter-SemiBold.ttf`, `Inter-Bold.ttf`
   - `PlayfairDisplay-Regular.ttf`, `PlayfairDisplay-Medium.ttf`,
     `PlayfairDisplay-SemiBold.ttf`
   - `OFL-Inter.txt` and `OFL-PlayfairDisplay.txt` (the licence files from
     each download)
3. In `pubspec.yaml`, under `flutter:`, add:
   ```yaml
     assets:
       - assets/google_fonts/
   ```
   Keep the existing comment line about `assets/images/` as it is.
4. Run `flutter pub get`, `flutter analyze`, `flutter test` again.

No Dart code changes are needed for this step.

## Step 4: Version

In `pubspec.yaml` change `version: 1.4.0+102` to `version: 2.0.0+200`. The
build number must be higher than any build already installed or uploaded.

## Step 5: Build

Run from `arunachal_exam_app/`:

```
# Universal APK for sharing and sideloading
flutter build apk --release --dart-define-from-file=dart_defines.env

# Smaller per-device APKs (most students' phones need the arm64-v8a one)
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.env

# Play Store bundle
flutter build appbundle --release --dart-define-from-file=dart_defines.env
```

`--dart-define-from-file` compiles in the Gemini key used by the AI tutor. Do
not echo the file's contents.

If Gradle or R8 runs out of memory: close other heavy apps and retry once.
`android/gradle.properties` is already tuned for a low-memory laptop
(`-Xmx2048m`, 2 workers), so do not raise those values without asking.

## Step 6: Verify the outputs

1. The files exist:
   - `build/app/outputs/flutter-apk/app-release.apk`
   - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (plus
     `armeabi-v7a` and `x86_64`)
   - `build/app/outputs/bundle/release/app-release.aab`
2. They are signed with the **upload key, not the debug key**:
   ```
   keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
   ```
   The owner/CN must not be `CN=Android Debug`. Report only the SHA-256
   fingerprint and the owner line, nothing else from the keystore.
3. The app name and version are right:
   ```
   <android-sdk>/build-tools/<latest>/aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk
   ```
   Expect `application-label:'Donyi Prep'`, `versionName='2.0.0'`,
   `versionCode='200'`, `package: name='com.example.arunachal_exam_app'`.
4. Record each file's size.

## Step 7: Smoke test on a real phone or emulator

Install with `adb install -r build/app/outputs/flutter-apk/app-release.apk`.
Then check each item and mark it pass or fail. Take a screenshot of each screen
marked with an asterisk.

1. First launch: "What are you preparing for?" lets you pick an exam goal, then
   shows the welcome screen.*
2. Sign in with a test account works and opens the Dashboard.
3. Dashboard*: greeting, the chosen exam goal as a large serif title, the bell
   icon, the Previous Year Papers carousel (switch APPSC / APSSB / Police), the
   Live Mock Arena card with a ticking countdown, the Study shelf list.
4. Tap **Enroll in Mock**: the button changes to "You're enrolled" and a
   message confirms the reminder.
5. PYQ Library tab*: papers grouped by year; search and the department tabs
   filter the list; tapping a paper opens a sheet with "Begin exam mode" and
   "Study with answers".
6. Exam mode*: the timer counts down at the top; selecting an option animates
   its green border; Next / Previous and swiping move between questions; the
   grid button opens the Question palette*; Submit shows a summary and then the
   Result screen* with score, accuracy and answer review.
7. Study mode: after you pick an option the correct answer and explanation
   appear and the choice cannot be changed.
8. Mock Tests tab: mocks list loads; "Build a practice set" starts a practice
   test.
9. Performance tab*: after step 6 it shows tests taken, average score, accuracy
   and the recent test; tapping it reopens the result.
10. Account (avatar on the Dashboard) → Appearance → **Dark**: every new screen
    turns dark green-black and stays readable.* Then set it back to System.
11. Phone Settings → Display → font size to the largest: the Dashboard, the
    exam screen and the palette must not show yellow-black overflow stripes or
    cut-off buttons.
12. Back button inside a running exam asks "Leave this test?" before leaving.
13. Airplane mode, then reopen the PYQ Library: it shows the saved list with
    "Offline · showing saved list".

## Step 8: Hand-over

1. Copy (do not move) the files to the folder **above** the project
   (`../`, i.e. `Arunachal Exam App/`), renamed:
   - `DonyiPrep-2.0.0-universal.apk`
   - `DonyiPrep-2.0.0-arm64-v8a.apk`
   - `DonyiPrep-2.0.0.aab`
2. Do not delete the older APKs that are already there.

## Final report (reply in this format)

```
Branch / commit: <branch> @ <short sha>
Analyze: <result>     Tests: <passed>/<total>
Fonts bundled: yes/no (list any file you could not get)
Version: 2.0.0+200
Signing: upload key, SHA-256 <fingerprint>   (or: STOPPED, reason)
Outputs:
  DonyiPrep-2.0.0-universal.apk   <size>
  DonyiPrep-2.0.0-arm64-v8a.apk   <size>
  DonyiPrep-2.0.0.aab             <size>
Smoke test: <n>/13 passed
  Failures: <item number> - <what happened> - <screenshot file>
Changes I made beyond the steps: <none, or each file + why>
Things I noticed but did not change: <list>
```
