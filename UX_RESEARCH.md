# Wristlist UX Research

Last updated: September 9, 2026

## Sources Reviewed

- Apple Human Interface Guidelines: Tab bars  
  https://developer.apple.com/design/human-interface-guidelines/tab-bars
- Apple Human Interface Guidelines: Accessibility  
  https://developer.apple.com/design/human-interface-guidelines/accessibility
- Apple Human Interface Guidelines: Search fields  
  https://developer.apple.com/design/human-interface-guidelines/search-fields
- Apple WWDC24: Get started with Dynamic Type  
  https://developer.apple.com/videos/play/wwdc2024/10074/
- Apple Developer Documentation: SwiftData model lifecycle, `ModelContext`, `Query`, `ContentUnavailableView`, searchable navigation placement
- Beli product references: ranked lists, maps, want-to-try, friend activity, taste-based recommendations  
  https://play.google.com/store/apps/details?id=com.beliapp.myapp
- Letterboxd product references: diary-style logging, reviews, watchlist, profile favorites, social activity  
  https://letterboxd.com/about/faq/
- DICE product references: local event discovery, personalized events, following friends/artists/venues  
  https://apps.apple.com/us/app/dice-live-shows/id898358948

## Useful Patterns

- Keep the primary app structure native. A four-tab `TabView` maps cleanly to Feed, Discover, My List, and Profile, and avoids hidden navigation for the app's core jobs.
- Discovery should keep search visible and scoped. Search by festival, artist, city, venue, or genre should combine with quick filters rather than burying filtering in a separate advanced screen.
- Reviews need progressive disclosure. Feed cards should show enough information to decide whether to open the detail page, while festival details can carry lineup, category ratings, friends, and review history.
- List keeping is a core loop. Beli-style utility comes from ranked lists, saved/want-to-go states, friend taste context, and a profile that summarizes history. Wristlist should translate this into festival-specific language: wristbands, lineups, stages, cities, genres, and attended weekends.
- Logging should feel like a guided form, not a blank text box. Rating validation, category scores, favorite performances, visibility, and confirmation make the review feel intentional and reduce accidental low-quality data.
- Accessibility should use native controls where possible, clear labels, Dynamic Type-friendly text styles, scrollable layouts, and controls with at least 44-point hit targets.
- Dark mode can be the strongest brand expression, but light mode must be intentionally designed and not just inverted colors.

## Wristlist Design Direction

- Use a restrained festival identity: deep stage-background neutrals, coral as the main action color, violet/electric accents for festival artwork and ranking details.
- Avoid copying competitor layouts or assets. Borrow product principles only: ranked histories, diary/review behavior, saved queues, social proof, and discovery filters.
- Keep density useful. Cards are appropriate for repeated social posts and ranked rows, but feature screens should vary between lists, compact metrics, segmented controls, sheets, and detail sections.
- Prefer native system affordances: `NavigationStack`, `TabView`, `.searchable`, `Picker`, `Form`, `ShareLink`, `ContentUnavailableView`, alerts, confirmation dialogs, and sheets.
- Motion should communicate state changes such as saving, liking, filtering, and review-step transitions. Respect Reduce Motion where custom animations are used.

## September 9 Visual Recalibration

- Public Beli references show a cleaner utility pattern than Wristlist's first visual pass: mostly flat white or near-white surfaces, compact social feed cards, visible search, map/list utility, small score badges, and ranking/list controls that carry the hierarchy.
- Wristlist should borrow those product principles without copying Beli's exact restaurant layout, logo, assets, copy, or brand colors.
- Revised Wristlist direction: solid paper/ink surfaces, a restrained teal brand color, score green for ratings, coral reserved for emphasis/errors, smaller native type, denser repeated rows, and local abstract festival thumbnails instead of glow-heavy stage gradients.
- Festival specificity remains the differentiator: dates, city/venue, lineup, attendance, saved/want-to-go state, favorite performances, and category scores should stay prominent.
