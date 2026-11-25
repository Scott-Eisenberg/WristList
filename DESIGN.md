# Wristlist Visual Direction

## Product Voice

Wristlist should feel like a mobile culture product: part festival magazine, part personal ranking shelf, part social notebook. The UI should lead with taste, opinion, and discovery instead of dashboard metrics.

## What Changes

- Fewer enclosed cards. Use open layouts, dividers, typography, and poster-like visuals for hierarchy.
- Festival identity moves forward. Abstract artwork becomes a reusable editorial poster system, not a decorative thumbnail.
- Ratings become a recognizable product mark: large monospaced numbers with small editorial labels and a hard accent rule.
- Profile centers on ranked festivals and taste history, not generic stat tiles.
- Forms use roomy product-native fields and visible primary actions instead of default grouped table styling.

## Design System

### Typography

- Page titles: large, bold, editorial, 34-40pt on mobile.
- Festival names: headline-like, heavy, 22-32pt depending on context.
- Section headings: compact uppercase kicker plus confident title when needed.
- Metadata: short, high-contrast, often uppercase; avoid long gray metadata strings.
- Body: readable 15-17pt with generous line spacing.

### Color

- Neutral base: warm paper in light mode, deep ink in dark mode.
- Brand: a confident red-orange used for actions and active states.
- Festival palettes: clay, violet, cyan, green, and ochre used as identity colors, not decoration everywhere.
- Dividers use low-contrast ink/white opacity. Borders are rare.

### Shape

- Use small radii only where touch affordance or artwork clipping needs it.
- Avoid nested cards and default pill-heavy layouts.
- Prefer hard-edged poster blocks, hairline dividers, and spacious rows.

### Components

- Festival poster: abstract block composition based on the festival palette with date/location overlays.
- Festival card: poster first, then name/date/location/rating with asymmetric layout.
- Ranked row: rank number as collectible index, festival name as headline, rating as proof of taste.
- Review post: author plus festival identity, prominent score, excerpt, favorite performances, and simple reaction controls.
- Profile header: expressive identity block with restrained stats and ranked festivals as the centerpiece.
- Buttons: one primary brand action per screen; secondary actions are text or outlined controls.

## Mobile Behavior

- Screens should scroll like editorial feeds, not admin pages.
- Horizontal browsing is used for discovery shelves.
- Touch targets stay at least 44pt.
- Empty/loading/error states are quiet and informative without becoming large boxed panels.

## Current Generic Sources To Remove

- Repeated rounded rectangle cards around every row.
- Capsule chips for routine metadata.
- Symmetric two-column stat dashboards.
- Small icon+label controls competing equally with primary content.
- Default `Form` styling on edit/profile settings screens.
