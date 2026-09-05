# Bolt's Journal - Critical Learnings

## 2025-05-20 - Memoizing Leaderboard Calculation in Flutter Riverpod
**Learning:** Performing list cloning (`[...]`) and sorting (`sort()`) directly inside a Flutter widget's `build()` method causes unnecessary heap allocations and `O(N log N)` sorting overhead on every animation frame or parent widget rebuild (e.g., when Riverpod state triggers re-renders). Extracting state computation into a Riverpod Provider ensures the leaderboard is computed and sorted only when underlying dependencies (like user state/rating) change.
**Action:** Always compute/derive sorted lists in Riverpod providers or `useMemoized`/`Provider` rather than inline in `Widget.build`.
