# QA Repair Log

## Repository Inspection

- App target: `WristList`
- Test targets: `WristListTests`, `WristListUITests`
- Architecture: SwiftUI app using SwiftData models, local sample data seeding, and tab-based navigation across Feed, Discover, My List, and Profile.
- Data layer: `WristlistDataController` owns sample seeding, review persistence, saved state, comments, ranking updates, and discovered festival imports.
- Network/API dependency: `FestivalExternalSearchService` calls the Wikipedia API for external festival discovery. No production event-provider backend, account auth, map provider, ticket-link provider, or push-notification backend is currently connected.
- Existing UI tests were template launch/performance tests only; meaningful user-flow coverage is currently concentrated in `WristListTests`.
- Worktree already contained many modified files. I did not revert or overwrite unrelated changes.

## Iteration 1: Build, Test Harness, Simulator Access

### Tested

- Built the app with Xcode MCP `BuildProject`.
- Attempted targeted unit tests with Xcode MCP `RunSomeTests`.
- Attempted full unit/UI test run with Xcode MCP `RunAllTests`.
- Probed simulator availability with `xcrun simctl list devices available --json`.
- Reviewed Feed, Discover, Festival Detail, Review Flow, My List, Profile, Settings, user profile detail, search, data controller, and sample data source paths.

### Result

- Build passed once via Xcode MCP:
  - `buildResult`: `The project built successfully.`
- Test execution is blocked in this session:
  - `RunSomeTests` timed out after 120 seconds.
  - `RunAllTests` timed out after 120 seconds.
- Manual simulator QA is blocked in this session:
  - `simctl` reports `CoreSimulatorService connection became invalid`.
  - The sandbox cannot access CoreSimulator logs/device set.
  - Escalated simulator access is disabled by host policy.
- Command-line `xcodebuild` is not a valid fallback here:
  - Swift macro execution fails under sandbox with `SwiftDataMacros` / `PreviewsMacros` malformed-response errors.
  - The command-line failure is an environment/tooling limitation, not a confirmed app compile failure.

### Fix

- No app fix from this iteration; logged the environment blocker and continued with source-level QA.

## Iteration 2: Profile Review Lookup After Profile Edits

### Tested

- Inspected profile editing and profile detail flows.
- Traced how a profile's reviews are selected for display after the profile name changes.

### Failure

- `UserProfileDetailView` matched reviews by `review.userName == displayName`.
- If the current user edits their display name, existing reviews keep the old stored `userName` and disappear from their own profile detail page.

### Fix

- Added stable `userID` to `UserProfileDetailView`.
- Updated all initializers to carry `review.userID`, `profile.id`, or `UserSearchResult.id`.
- Changed profile review lookup to match by stable user ID first, with handle/name fallback only when no user ID is available.
- Added `profileDetailKeepsCurrentUserReviewsAfterDisplayNameChange()`.

### Status

- Swift parser checks passed for the changed files.
- Full build/test rerun is blocked by the Xcode MCP timeout and CoreSimulator issue described above.

## Iteration 3: Hidden Review Privacy In Profile Surfaces

### Tested

- Inspected profile detail and user search paths for `isVisibleToFriends` handling.

### Failure

- Profile detail could include hidden reviews for other users because the review lookup did not enforce `isVisibleToFriends`.
- User search could include hidden review festival context for other users.

### Fix

- Updated `UserProfileDetailView.reviewsForProfile(...)` to show hidden reviews only for the current user's own profile.
- Updated `UserSearchService` to build other users' review counts and festival context from visible reviews only.
- Added `profileDetailHidesPrivateReviewsForOtherUsers()`.
- Extended `userSearchMatchesNameHandleAndFestivalContext()` to verify a hidden Maya review does not make Maya appear for a hidden festival search.

### Status

- Swift parser checks passed for the changed files.
- Full build/test rerun is blocked by the environment issues above.

## Iteration 4: External Festival Search Result Quality

### Tested

- Probed the Wikipedia API for `Beyond Wonderland music festival`.
- Reviewed parser behavior for pages that mention the searched festival but are not festival pages.

### Failure

- The external search parser could include adjacent pages, such as an event promoter page, if the page body mentioned the searched festival and contained festival-related terms.

### Fix

- Tightened `FestivalExternalSearchService.looksLikeFestivalResult(...)`.
- Festival pages still pass when the title matches the query and the page has festival context.
- Body-only matches now require the page description itself to look like a festival descriptor.
- Extended `externalSearchParserReturnsFestivalPagesOnly()` with an `Insomniac (promoter)` fixture that mentions Beyond Wonderland but should be excluded.

### Status

- Swift parser checks passed for the changed files.
- `git diff --check` passed.

## User Flows Covered By Source/Static QA

- Feed launch and local sample-data seeding.
- Festival browse and detail navigation.
- Discover local search, filter chips, remote festival lookup, remote import, and save-to-list path.
- Log Festival review flow, including remote festival search/import from the modal.
- My List ranked/attended/want/saved sections and rank move path.
- Review create/edit/delete persistence path.
- Like, comment, and share controls on reviews.
- Profile edit, profile settings, profile search, and user profile detail.
- Settings appearance, notification toggles, privacy picker, and sample-data reset.

## Unavailable Or Blocked Product Surfaces

- Onboarding, sign in, and sign out are not implemented.
- Custom list create/edit/delete/share is not implemented; the current app has generated list sections only.
- Map, ticket-link, real notification delivery, and backend-connected social functionality are not implemented.
- Manual simulator execution is blocked by CoreSimulator access from this session.
- Full unit/UI test execution is blocked by Xcode test-runner timeouts from this session.

## Latest Validation Commands

- `git diff --check`: passed.
- `xcrun swiftc -parse WristList/Views/UserProfileDetailView.swift`: passed.
- `xcrun swiftc -parse WristList/Models/ProfileModels.swift`: passed.
- `xcrun swiftc -parse WristList/Services/FestivalSearchService.swift`: passed.
- `xcrun swiftc -parse WristListTests/WristListTests.swift`: passed.
- External search source probe for `Beyond Wonderland`: Wikipedia returned the expected `Beyond Wonderland` festival page.
