# FeaturesKit UI Test Plan

Test using a demo iOS app that imports FeaturesKit as a Swift Package dependency. Point at a running Features backend (local or deployed).

## Setup

1. Create a new Xcode iOS App project
2. Add FeaturesKit as a package dependency (GitHub URL or local path)
3. Create an app in the Features dashboard, copy the API key
4. Add `FeaturesKit("your_api_key", baseURL: "http://localhost:3000")` to a view
5. Run on simulator (iPhone 17 Pro recommended)

## Request List

- [ ] List loads and displays requests from the backend
- [ ] Pull-to-refresh fetches fresh data
- [ ] Empty state shows "No requests yet" when no requests exist
- [ ] Segmented control filters: All shows everything, Planned shows planned/in_progress/under_review, Shipped shows shipped
- [ ] Empty state per segment: "Nothing planned yet", "Nothing shipped yet"
- [ ] Sort menu changes order: Most Voted, Newest, Oldest
- [ ] Sort persists across pull-to-refresh
- [ ] Tapping a row navigates to request detail
- [ ] Navigation title shows "Feature Requests"

## Request Row

- [ ] Title displays bold, single line, truncated if long
- [ ] Description displays gray, max 2 lines, truncated
- [ ] Rows without description show title and bottom row only (no blank gap)
- [ ] Upvote button on left: chevron up + count in rounded rect
- [ ] Upvote button tappable without triggering row navigation
- [ ] Voted state: filled accent background, white text
- [ ] Not voted state: light tint background, accent border
- [ ] Status badge shows colored capsule (Planned=blue, In Progress=purple, Shipped=green, Under Review=orange, Declined=red)
- [ ] New status shows no badge
- [ ] Comment count with bubble icon (hidden when 0)

## Voting

- [ ] Tap upvote: count increments immediately (optimistic)
- [ ] Tap upvote on already-voted: count decrements immediately (unvote)
- [ ] Vote state persists after pull-to-refresh (server confirms)
- [ ] Vote from one device, check from another: count is correct
- [ ] Rapid tap (vote/unvote/vote): UI settles to correct final state
- [ ] Vote while offline: UI updates, action queued
- [ ] Queued vote replays on next successful load

## Request Detail

- [ ] Full title and description displayed (scrollable)
- [ ] Large vote button with count, matches voted state
- [ ] Status badge matches list row
- [ ] Comment thread shows in chronological order
- [ ] Developer comments: tinted background, "Developer" label
- [ ] User comments: truncated device ID as author
- [ ] Comment dates displayed
- [ ] "No comments yet" when empty
- [ ] Back navigation returns to list

## Commenting

- [ ] Text field at bottom with "Add a comment..." placeholder
- [ ] Send button disabled when text is empty/whitespace
- [ ] Sending shows progress indicator on button
- [ ] Comment appears in thread after send (page reloads)
- [ ] Scrolls to bottom after posting
- [ ] Comment text clears after successful send
- [ ] Failed send keeps text in field for retry
- [ ] Keyboard avoidance: field stays visible above keyboard

## Submit Request

- [ ] "+" toolbar button opens sheet
- [ ] Title field required, Submit disabled when empty
- [ ] Title character counter: 0/200, turns red past 200
- [ ] Description field optional, counter: 0/2000, turns red past 2000
- [ ] Submit disabled when over character limits
- [ ] Cancel dismisses sheet
- [ ] Submit shows loading state
- [ ] Successful submit dismisses sheet, new request appears in list
- [ ] Failed submit shows inline error, text preserved
- [ ] Sheet not dismissible by drag while submitting
- [ ] Submit while offline: queued, sheet dismisses

## Offline Behavior

- [ ] Network unavailable on launch: cached data loads, offline banner visible
- [ ] Offline banner: wifi.slash icon + "Showing cached data"
- [ ] No cache and no network: error state with "Try Again" button
- [ ] "Try Again" retries the load
- [ ] Vote while offline: optimistic UI + queued
- [ ] Submit while offline: queued silently
- [ ] Reconnect + pull-to-refresh: queued actions replay, fresh data loads
- [ ] Failed replay (still offline): actions remain queued for next attempt

## Integration Points

- [ ] `FeaturesKit("key")` renders without crashing
- [ ] `FeaturesKit("key", showSubmitButton: false)` hides the "+" button
- [ ] `FeaturesKit("key", userId: "user123")` sends X-User-ID header
- [ ] Works inside NavigationLink (pushed onto existing stack)
- [ ] Works inside .sheet
- [ ] Works inside TabView
- [ ] Dark mode: all colors adapt correctly
- [ ] Dynamic type: layout handles accessibility text sizes

## Edge Cases

- [ ] Invalid API key: error state, not a crash
- [ ] Request with very long title (200 chars): truncates in row, full in detail
- [ ] Request with no description: row layout looks clean
- [ ] Zero votes: shows "0" in upvote button
- [ ] Zero comments: comment count hidden in row, "No comments yet" in detail
- [ ] Hundreds of requests: list scrolls smoothly
- [ ] Device ID stable across app launches (UserDefaults persistence)
