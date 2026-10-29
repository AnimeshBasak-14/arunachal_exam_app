# Agent prompt: Dawnlit UI/UX upgrade and full audit

Copy everything below the line into your coding agent (Antigravity, Claude Code, etc.).

---

You are working on **Dawnlit** (by ZAP), the Flutter exam-prep app in
`arunachal_exam_app/`. Students in Arunachal Pradesh use it to prepare for APPSC,
APSSB and Arunachal Police exams, mostly on cheap Android phones, often with the
system font size turned up. The owner's own phone runs at **130% text**.

Your job has two parts:

1. **Upgrade**: make every screen follow the existing Dawnlit look: modern, airy,
   light, calm, simple. Do not invent a new style; extend the one that exists.
2. **Audit and fix**: find every UI and UX problem in the app, rank them, fix
   them, and prove the fixes with screenshots and tests.

## Ground rules

- **Keep the look.** Reuse the design system below. If something is missing, add
  it to the design system (a token or a shared widget), then use it. Never style
  one screen by hand.
- **Never invent data.** No fake notifications, stats, ranks, users, news, papers,
  answer keys or "Today" items. Missing data is shown as an honest empty state.
- **Facts must be correct.** GK, grammar and map content is studied for exams. Do
  not add or change facts unless you verify them against a source (Wikidata,
  Wikipedia, official sites) and say which. Omit rather than guess.
- **Don't look official.** No APPSC/APSSB logos, no state emblem, no wording that
  implies the app is run by or approved by the government.
- **Don't change behaviour you weren't asked to change.** In particular leave
  sign-in logic (`lib/core/services/auth_gateway.dart`,
  `lib/features/auth/viewmodel/auth_viewmodel.dart`), `firestore.rules`, the AI
  proxy (`supabase/functions/ai-tutor`) and data services alone, except to fix a
  bug you can show.
- **No secrets in git.** `.env`, `dart_defines.env`, `android/key.properties`,
  `android/local.properties`, keystores and `ios/Flutter/Secrets.xcconfig` stay
  local. Never build with `--dart-define-from-file=.env`.
- **Do not commit or push** unless the owner asks. Keep `flutter analyze` at zero
  issues and all tests passing after each step.

## The design system (read these files first)

| What | Where |
| --- | --- |
| Colour, type and spacing tokens | `lib/core/theme/aura.dart` (`Aura`, `AuraType`, `AuraSpace`) |
| Material theme built from the tokens | `lib/core/theme/app_theme.dart` |
| Shared widgets | `lib/core/widgets/aura/aura_widgets.dart`, `user_avatar.dart`, `wordmark.dart` |
| Form pages | `lib/features/auth/view/auth_widgets.dart` |
| Scrolling content pages | `lib/features/learn/view/study_widgets.dart` |
| Reference screens (copy these patterns) | `dashboard_screen.dart`, `account_screen.dart`, `state_gk_screen.dart`, `login_screen.dart`, `learn_feed_screen.dart` |

**Palette** (finalized by the owner; don't change it):
Child of Light `#F0F4F8` (background), Aruba Aqua `#D2DDD4` (tint; accent in
dark mode), Portsmouth Bay `#A1ACAC` (borders only: too light for text),
Blackish Green `#5E6161` (secondary text), Atlantic Waves `#233E42` (the one
accent), Vantablack `#010101` (text; dark background). Muted ochre, brick and
green are kept only for review, wrong and correct states.

**What "the Dawnlit look" means:**

- One accent colour. Everything else is ink on a soft background.
- Titles in Playfair Display (`AuraType.serif`); everything else in Inter
  (`AuraType.sans`). Numbers that change use `AuraType.digits`.
- Small uppercase `Eyebrow` labels above titles and sections.
- Content sits in `GlassCard` / `GlassList` with a hairline border and a very
  soft shadow. No heavy shadows, no bright gradients, no coloured card fills.
- 20 px side gutter (`AuraSpace.gutter`), radius 20 for cards and 14 for
  controls, generous vertical space (24–34 px between sections).
- Cupertino icons, thin and quiet. No emoji in the interface.
- Motion is short and soft: 200–260 ms, `Curves.easeOutCubic`. Haptic ticks on
  meaningful taps only.
- Copy is plain, short and calm: sentence case, no exclamation marks, no hype.
  Errors say what happened and what to do next.

**Page patterns:**

- **Scrolling page:** `StudyPage` (pinned bar with `AuraBarTint`: clear at rest,
  frosted when content scrolls under).
- **Form page:** `FormPage` + `PasswordField` + `FormError` + `BusyButton`.
- **Tab pages:** the 4-tab shell in `lib/features/shell/view/app_shell.dart`.
- **Full screen:** the Learn feed and the GK map. Overlays use `_RoundButton`-style
  controls on `surfaceSolid`.
- **States:** loading uses `SkeletonBox`, empty and error use `AuraEmpty` with one
  clear action, offline shows a quiet one-line note.

**Hard rules for code:**

- No `Color(0x…)` or `Colors.<name>` in feature code. Use `context.aura` tokens
  (`Colors.transparent` is fine).
- No `AppColors` / `AppSpacing` in new or touched code; they are legacy.
- No raw `TextStyle(...)`; use `AuraType`.
- Every tap target is at least 48×48 dp. Every icon-only button has a `tooltip`.

## Part A: known issues (fix these first)

**A1. The "correct / success" green is hardcoded.**
`Color(0xFF2F6B55)` is repeated in `learn_feed_screen.dart`,
`grammar_quiz_screen.dart`, `grammar_hub_screen.dart`, `bookmarks_screen.dart`,
`gk_map_screen.dart` and others. Add `success` (and a dark-mode value with at
least 4.5:1 contrast on `#010101`) to `Aura` in `aura.dart`, include it in
`lerp`, and replace every copy. Likewise, add an `onDanger` token and replace
`Colors.white` on danger buttons (`account_screen.dart`, `auth_widgets.dart`).

**A2. The admin editors are still old-style.**
`lib/features/admin/view/question_flagger_screen.dart` (about 2,000 lines) and
`question_review_screen.dart` (about 1,000 lines) use `AppColors` and are wrapped
in `_legacy(...)` in `lib/main.dart`. Move them to Aura components without
removing any feature (filters, inline editing, image previews, the AI repair
button, save and approve flows). Test them in light and dark. Then delete
`_legacy`, `AppTheme.legacyTheme`, `lib/core/theme/app_colors.dart` and
`app_spacing.dart` if nothing else uses them.

**A3. Leaving a timed test loses progress without asking.**
The close button in `grammar_quiz_screen.dart` pops straight away. Reuse
`lib/core/widgets/leave_test_dialog.dart` (as the exam screen does) when at least
one question has been answered, and handle the Android back gesture the same way
(`PopScope`).

**A4. News looks "offline" on the web build.**
Browsers block the RSS feeds (CORS), so `current_affairs_gk_screen.dart` shows
the offline state on web. On `kIsWeb`, show an honest note ("Live news is
available in the Android app") instead of "You're offline".

**A5. The map is blank grey without a Maps key.**
Debug builds without `MAPS_API_KEY` show an empty grid. Detect a missing key
(for example a `--dart-define=MAPS_ENABLED=true` flag set in release builds) and
show an `AuraEmpty` explaining that the map needs setup, instead of a broken map.

**A6. Screenshot failures folder.**
`test/screenshots/failures/` is created when renders differ. Add it to
`.gitignore` next to `test/screenshots/goldens/`.

## Part B: full audit

1. **List every screen.** Take every `GoRoute` in `lib/main.dart`, the 4 shell
   tabs, and every bottom sheet and dialog (search for `showModalBottomSheet` and
   `showDialog`). Put them in a table: route, file, how a user reaches it. Flag
   anything a user can't reach, and **ask the owner before deleting** it.
2. **Check each screen against this list**, in light and dark mode, at 360 px and
   412 px wide, at 100%, 130% and 200% text:
   - Layout: no overflow, clipping or text cut mid-word; nothing hidden behind the
     status bar, notch, keyboard or bottom bar; long names and titles wrap or
     truncate gracefully.
   - Consistency: same page pattern, title style, spacing, buttons and icons as
     the reference screens; no leftover old styles.
   - States: loading, empty, error, offline and slow-network all look intentional
     and offer a way forward. Pull-to-refresh where content is live.
   - Interaction: tap targets ≥ 48 dp; obvious primary action; destructive
     actions confirm first; double taps don't submit twice; back always goes
     somewhere sensible; forms move focus with Next and submit with Done; the
     keyboard never covers the focused field.
   - Accessibility: text contrast ≥ 4.5:1 (3:1 for large text); icon buttons have
     tooltips or `Semantics` labels; meaning never relies on colour alone
     (pair it with an icon or word).
   - Copy: plain and calm, consistent names (for example "Sign in", never mixed
     with "Log in"), no emoji, no fake urgency, no official-sounding claims.
   - Performance: no jank when scrolling long lists (use builders), images sized
     and cached, no work in `build` that should be done once.
3. **Rank every finding**: P0 (crash, data loss, security, misleading or false
   content), P1 (broken flow or unreadable at 130%), P2 (inconsistent with the
   design system), P3 (polish). For each finding give the file and line, the
   cause, and the fix.
4. **Fix P0–P2 in full**, and P3 where the change is small. Fix the cause in the
   shared design system when the same problem appears on several screens.

## Part C: verify

Run all of these and paste the results in your report. The PC has limited
memory, so stop Gradle daemons between heavy steps (`android\gradlew.bat --stop`)
and run tests with `-j 2`.

```
flutter analyze
flutter test -j 2
flutter test --tags screenshots --run-skipped --update-goldens test/screenshots
flutter build apk --release
```

- Add every screen you touch to `test/screenshots/study_screens_test.dart`
  (signed-in and signed-out as appropriate, light and dark), render them, and
  **look at every PNG** before calling the work done.
- Add widget tests for any flow you change (for example the leave-test dialog).

## Part D: report back with

1. The screen inventory table from B1.
2. The findings table: priority, screen, file:line, problem, fix, status (fixed,
   or not fixed and why).
3. Before/after screenshots for the 10 most visible changes.
4. Any open questions for the owner (screens to delete, copy decisions, data you
   couldn't verify).
5. The command outputs from Part C, including failures, quoted exactly.
