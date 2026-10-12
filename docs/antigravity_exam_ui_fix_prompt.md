# Antigravity prompt: exam app (Exam Prep Center) fixes and simpler filters

Copy everything below the line into Antigravity.

---

You are working on the Flutter exam-prep app in `arunachal_exam_app/`. It is
used by students preparing for APSSB and APPSC exams on cheap Android phones,
often with the system font size turned up. The goal: a student finds the right
paper and starts it in **two taps**, with no confusing filters.

All problems below were found by reading the code. Each has a root cause and a
file. Fix the cause, not the symptom.

## Ground rules

- **Do not change the Supabase database or run migrations** without the owner's
  approval. Reading from the database through the app as it does today is fine.
  If a fix needs a schema change, write the SQL as a new file in `migrations/`,
  marked "NOT APPLIED", and tell the owner.
- **Do not invent questions, papers, answer keys, years or marking schemes.** If
  data is missing, show it as missing.
- No secrets in git (`dart_defines.env`, keystores and `.env` stay local).
- Commit in small steps. Keep `flutter analyze` clean. Add the tests listed in
  Part D.
- Test at 360 px wide with the **system font size at 130%**, since the owner's
  phone uses large text, plus normal size and web at 1440 px.

---

## Part A: Bugs in the PYQ tab (`lib/features/home/view/pyq_hub_screen.dart`)

### A1. Fake and duplicate papers are shown and can't be started properly

- **Cause:** `_defaultCatalog` (lines ~115–229) is a hard-coded list of 10
  papers (e.g. "APPSC CCE 2024 Prelims Paper I, 100 questions").
  `_fetchLivePapersFromSupabase` (~247–294) **adds every catalog paper whose id
  is not in the database**. Database rows have different ids, so the same exam
  appears twice:
  - the real one, e.g. "APSSB-CGLE-2024 Official PYQ" with 5 questions
  - a catalog one, "APSSB CGL 2024 Combined Graduate Level", claiming 54
    questions

  Catalog papers that have no questions in the database still show "Exam Mode"
  and "Study Mode" buttons. If the network fails, the student only sees the fake
  catalog.
- **Fix:**
  - Delete `_defaultCatalog`. Show only papers that exist in the database.
  - Offline: show the last successful list from a local cache, with an
    "Offline · showing saved list" note. If there is no cache, show an empty
    state with Retry.
  - Hide papers with 0 questions.
  - Papers with fewer questions than the official count: show an
    "Incomplete · 5 of 54" pill. Leave the official count field empty if
    unknown, rather than guessing.

### A2. Missing data is replaced with made-up values

- **Cause:** `PyqPaperItem.fromSupabase` (~34–63) fills in defaults:
  - `exam_code` → `'APSSB-CGLE'`
  - `year` → `2024`
  - `subject` → `'General Studies'`
  - question count → `50`
  - marking → `+2/−0.5`
  - duration guessed from the question count

  So "VOCAB NOTES" shows as "Year 2024 · +2/−0.5 · 120 mins" even if none of
  that was entered, and it matches the 2024 year filter.
- **Fix:**
  - Make these fields nullable. Show "—" or hide the item when a field is
    missing.
  - Never filter on a defaulted value.
  - Also: "VOCAB NOTES" is study material, not a previous-year paper. It should
    not be listed under PYQ (`paper_type=PYQ`). Show the owner which database
    rows look mislabelled; do not change them yourself.

### A3. "Exam Mode" and "Study Mode" load questions by exam code + year, not by paper

- **Cause:**
  - `_launchExamMode` (~786–831) opens
    `/mock-test/${paper.examCode}/full?paperType=PYQ&year=…`.
  - `_launchStudyMode` (~833) opens `/pyq-paper?code=…&year=…`.

  The paper's `id` is never passed. Two papers with the same code and year (for
  example two APSSB-ENGLISH 2024 sets) get **mixed together**. Catalog codes
  like `APSSB-CGLE` don't match database codes like `APSSB-CGLE-2024`, so the
  student gets the wrong questions or none.
- **Fix:** pass the paper id (`test_id`) through the route, and have
  `MockTestScreen` and the PYQ paper screen load questions by `test_id`. Keep
  the old route parameters working only for the older links.

### A4. The search "clear" button doesn't clear the box

- **Cause:** the `TextField` (~468) has no `TextEditingController`.
  `onPressed: () => setState(() => _searchQuery = '')` resets the filter, but
  the typed text stays visible.
- **Fix:** use a controller, clear it, and unfocus.

### A5. Filters show a ✓ inside the closed dropdown and cut off text

- **Cause:** `_buildFilterDropdown` (~329–392) builds each menu item as a `Row`
  with a check icon. With no `selectedItemBuilder`, the closed button reuses
  that row. That's why the screenshot shows "All Exams ✓ ⌄" and
  "All Subje…✓ ⌄". The container is a fixed `height: 36` with 11 px text, which
  clips at 130% font size.
- **Fix:** replace these dropdowns entirely (see Part B).

### A6. Filter options are hard-coded and don't match the data or the selected board

- **Cause:** `_exams`, `_years` and `_subjects` (~83–112) are fixed lists.
  - Exams mix boards: CCE is APPSC and CGL is APSSB, but both appear under each
    board, so picking CCE on APSSB always shows nothing.
  - Years stop at 2020–2025.
  - Subjects are free text that must match the database `subject` exactly, so
    "Elementary Maths" ≠ "Elementary Mathematics".
  - Switching board does not reset the exam filter.
  - The Mock tab (`mock_hub_screen.dart:77`) uses yet another vocabulary
    ("Maths", "GK", "GA").
  - The Custom tab (`custom_practice_modal.dart:32`) uses a third one.
- **Root fix:** the database already has proper catalogs:
  `exam_catalog`, `subject_catalog`, `topic_catalog`, and `subject_code` /
  `topic_code` on `questions` (see `migrations/005_systematic_taxonomy_schema.sql`).
  - Build all filter options from those tables, or from the distinct values in
    the loaded papers.
  - Include a **count** with each option and hide options with 0 results.
  - Use one shared `Subject` name list across PYQ, Mock and Custom.

### A7. The header takes half the screen and never scrolls away

- **Cause:** `exams_hub_screen.dart` has a `NestedScrollView` with a title bar
  and a pinned PYQ / Mock / Custom switcher. Inside it, `PyqHubScreen` is
  **another `Scaffold`** with a fixed `Column`: board pills, search box,
  3 dropdowns, and an optional "Practice …" button. Only the paper list below
  them scrolls. In the screenshot, about 45% of the screen is controls before the
  first paper. The board selector is a third level of tabs, inside tabs, inside a
  page.
- **Fix:**
  - Remove the inner `Scaffold`.
  - Make the board, search and filter controls part of the scrolling content
    (slivers), so they scroll away.
  - Keep only one compact pinned row (see Part B).

### A8. Paper cards: duplicated info and a badge row that runs off the edge

- **Cause:** `_buildPaperCard` (~603–784) shows these in a single `Row`
  (not a `Wrap`):
  - the exam code
  - the year
  - the marking ("+2 / −0.5")
  - the duration ("120m")

  Then a second row repeats "120 mins" and "+2 / −0.5 Marking". The title often
  repeats the code too ("APSSB-CGLE-2024 Official PYQ (2024)"). At 130% font,
  the first row overflows on the right ("120m" is cut off in the screenshot).
- **Fix:** see the card spec in Part B.

### A9. The streak pop-up covers the bottom navigation

- **Cause:** `home_screen.dart:~95` shows a default (fixed) `SnackBar`. It sits
  over the bottom nav, which is not the `Scaffold`'s `bottomNavigationBar`.
  122 `SnackBar(` calls exist; only 1 sets a `behavior`.
- **Fix:**
  - Add a `snackBarTheme` with `behavior: SnackBarBehavior.floating`, rounded
    corners and a bottom margin that clears the nav bar.
  - Show the streak reward as a small celebratory toast at the top, or as a
    one-time card on Home. Never cover the navigation.

---

## Part B: New PYQ / Mock / Custom design (simple for students)

Students think in this order: **"My exam → which year → start."** Design for
that.

### B1. "My exam" picker, set once

- At the top of the Exam Prep Center, show a pill: **"🎯 APSSB CGL ▾"**.
- Tapping it opens a bottom sheet with two short lists, built from
  `exam_catalog` with paper counts:
  - APSSB: CGL, CHSL, CSLE, MTS, UDC…
  - APPSC: CCE, ESE…
- Save the choice to the user profile and `SharedPreferences`. On first launch,
  ask once.
- This **replaces** both the APSSB / APPSC board pills and the "Exam" dropdown.
- An "All exams" option exists at the bottom of the sheet.

### B2. One row of quick chips instead of dropdowns

- Under the pill is one horizontal, scrollable row of chips:
  `All · Full papers · English · Maths · GS · Reasoning · AP GK`.
- Chips come from `subject_catalog`, with counts. Hide chips with 0 papers.
- Single-select, one line each, 32–36 px tall, sized to the text.
- They are **not** fixed-height boxes. They must work at 130% font size.
- No year dropdown. Show the list **grouped by year**, with sticky year
  headers: "2025", "2024", …
- Search becomes a 🔍 icon at the end of the chip row. Tapping it expands a
  search field; Clear works (see A4).
- When any filter is on, show "12 papers · Clear" above the list.

### B3. Paper card: compact, one action

```text
CGL 2024 · General Studies                  [Incomplete 5/54]
54 Qs · 60 min · +2 / −0.5
[ Start test ]                                   Study ›
```

- **Title:** a clean name built from the data (exam + year + subject), not the
  raw `exam_code`.
- **One meta line**, wrapping if needed. Nothing is repeated.
- **Primary button "Start test"** (timed). It opens the existing confirmation
  dialog, simplified to 3 bullet lines.
- **"Study ›"** is a text button: answers are shown as you go.
- Card padding 12–14 px, radius 12, no shadow plus a 1 px border, so more cards
  fit on screen.

### B4. Mock tab

Same pattern as PYQ: the same "My exam" pill, the same subject chips, mocks
grouped by level (Easy / Medium / Hard) instead of a level dropdown, and the
same card.

### B5. Custom test (`lib/widgets/custom_practice_modal.dart`): rebuild as 3 steps

Current bugs (root causes):

- **Downloads the whole question bank:** it fetches every question with
  passages and tests joined (`~87–105`), with no topic filter and no limit. On
  mobile data it is slow or times out after 8 s.
- **Topic matching is a guess:**
  - matches by substring on the subject or the question text (`~119–133`)
  - "Polity" matches any "studies" subject, so all of General Studies
  - "Geography" matches any question that contains the word
- **Silently ignores the student's choice:** if nothing matches, it uses the
  **entire pool** (`~135–137`). A student who picks "Syllogisms" can get polity
  questions with no warning.
- **Last-resort fallback:** if the database fetch fails, it uses
  `QuestionRepository.allQuestions`. That is the old bundled set, many of which
  have no answer keys.
- **`review_status=neq.flagged`:** in PostgREST this also drops rows where
  `review_status` is NULL. The comment says "only approved", but the code does
  not do that. Decide with the owner which statuses students should see.
- **The spinner never stops:** `_isGenerating` is never reset after a
  successful start. When the student comes back to the tab, the button is stuck
  loading.
- **Can't deselect the last topic:** you can't deselect the last topic (`~283`),
  and it doesn't explain why.
- **Inconsistent navigation:** it uses `Navigator.push(MaterialPageRoute…)`
  while the rest of the app uses go_router.
- **Raw errors:** errors show the raw exception text to students.

New flow (one screen, no numbering, no long descriptions):

1. **What to practise:** subject chips with counts, from `subject_catalog`.
   After a subject is picked, show optional topic chips from `topic_catalog`.
2. **How many:** chips 10 · 20 · 50. Disable a chip if fewer questions exist
   ("only 14 available").
3. **Mode:** a two-option switch, "Timed" or "Learn" (answers shown).
4. **Optional source toggle** under "More options": PYQ, Mock or both.

The **Start** button says exactly what you'll get: "Start 20 Maths questions".

Query the database **server-side** by `subject_code` / `topic_code` /
`paper_type` with `limit` and random ordering (an RPC, if one is needed, goes
as a NOT-APPLIED migration for the owner). If there are not enough questions,
tell the student; never substitute other topics.

### B6. New colour system ("Night & Signal") with light and dark mode

The owner wants the same look across all their apps: **black background with
white text, green and orange accents in dark mode; white background with black
text, green and orange accents in light mode.** Modern, flat and compact.
**No gradients of any kind**, and no left-to-right or diagonal fades.

Replace `lib/core/theme/app_colors.dart` and build a proper light **and** dark
`ThemeData` from these tokens. All text pairs were checked at ≥ 4.5:1 contrast.

| Role | Dark | Light |
| --- | --- | --- |
| Background | `#0B0B0C` | `#FFFFFF` |
| Surface (cards, sheets, nav) | `#161618` | `#F4F4F5` |
| Raised (inputs, chips) | `#1F1F22` | `#FFFFFF` + 1 px border |
| Border / divider | `#2A2A2E` | `#E4E4E7` |
| Text | `#FFFFFF` | `#0B0B0C` |
| Secondary text | `#A1A1AA` | `#52525B` |
| **Orange**: primary buttons ("Start test"), selected chip, active tab, exam picker pill | `#FF7A1A`, with `#0B0B0C` text on it | `#FF6A00` fill with `#0B0B0C` text; `#C2410C` for orange text |
| **Green**: correct answers, scores, streaks, "Available", success | `#22C55E` | `#15803D` text, `#ECFDF3` tint |
| Wrong answer / error | `#F87171` | `#B91C1C` |
| Warning ("Incomplete") | `#FBBF24` | `#B45309` |

Rules:

- **Never put white text on orange:** 2.9:1, which fails. Text on orange is
  always near-black.
- **Quiz feedback:** green = correct, red = wrong, orange = selected or "your
  answer". Never use green and orange as decoration next to each other.
- **Remove the old colours:**
  - the emerald / teal / amber / blue / neon palette
  - the "orb" tints
  - the glass surfaces (`glassSurface`, `orbMint` etc.)
  - the per-card amber "Year", teal and blue badges

  Metadata is grey; there is one accent per screen.
- **Remove hard-coded colours** (`Colors.white`, `0xFFF8FAFC`,
  `Colors.amber.shade900`, `Color(0xFF059669)`…) across `lib/` and use theme
  colours. Run `grep -rn "Color(0x\|Colors\." lib/` and fix every hit outside
  the theme file.
- **Theme setting:** Auto / Light / Dark in Profile, defaulting to Auto.
- **SnackBars, dialogs and the bottom nav** use the surface colours, not green
  fills.
- **Text scaling:**
  - No fixed heights on anything that contains text.
  - Every control must work with `MediaQuery.textScaler` at 1.3.
  - Clamp the app-wide text scale at 1.4 so layouts stay usable on very large
    settings.
- **Tap targets:** at least 44 px.

---

## Part C: Quick wins elsewhere (do after A and B)

- **Supabase setup:**
  - The project URL and publishable key are hard-coded in 8 files:
    `admin_session.dart`, `question_repository.dart`, `bookmarks_screen.dart`,
    `mock_hub_screen.dart`, `pyq_hub_screen.dart`, `custom_practice_modal.dart`,
    and the two admin screens.
  - Move them into **one** config class that reads `--dart-define` values, so
    the project can change without editing 8 files. Publishable keys are meant
    to be public, so this is about maintainability, not a leak.
- **Raw HTTP calls:** each screen builds raw REST URLs by hand. Create one
  `ExamRepository` with typed methods:
  - `papers(board, examCode)`
  - `questionsForTest(testId)`
  - `practiceQuestions(subject, topic, count)`

  It handles caching and errors in one place.

---

## Part D: Tests to add

1. **PYQ list:**
   - with a fake repository returning 3 papers (one with no year, one with
     0 questions), it shows 2 papers;
   - the 0-question paper is hidden;
   - the no-year paper shows no year and does not appear under the "2024"
     group.
2. **No duplicates:** with database rows plus no network, the screen never shows
   a paper that isn't in the repository (protects against A1).
3. **Starting a paper:** tapping "Start test" navigates with the paper's
   `test_id` (protects against A3).
4. **Search:** typing and then tapping clear empties the text field (A4).
5. **Layout:** at 360×780 with text scale 1.3, the PYQ, Mock and Custom tabs
   render with no overflow exceptions.
6. **Custom test:**
   - if the repository returns fewer questions than requested, the screen shows
     the "only N available" message and does not pad with other topics;
   - the Start button is not stuck loading after returning from a test.

## Definition of done

- A student can open Exam Prep Center, see their exam pre-selected, and start a
  real paper in 2 taps.
- No fake or duplicate papers.
- No dropdowns.
- Nothing is cut off at 130% text size.
- `flutter analyze` is clean and all tests pass.
- Screenshots of PYQ, Mock, Custom and the exam picker sheet, at 360 px with
  130% text, for the owner to review.
