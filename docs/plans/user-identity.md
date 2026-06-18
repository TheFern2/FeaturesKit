# User Identity

Allow FeaturesKit users to identify themselves with a display name and optional email, replacing raw device IDs in comments. Apps with auth can also pass a userId.

## Current State

- Comments table has `device_id` (required) and `user_id` (optional), no display name or email
- `CommentRow` shows truncated `deviceId` for non-developer comments
- `FeaturesClient` sends `X-Device-ID` and optionally `X-User-ID` headers
- `FeaturesKit` view accepts `userId: String?` but no display name or email
- Identity is anonymous by default; no prompt to identify yourself

## Two Identity Modes

1. **Anonymous/self-serve**: No userId provided by the host app. First time the board opens, show a sheet asking for display name (required) and email (optional). Persist to UserDefaults.
2. **App-managed**: Host app passes userId and optionally displayName/email via the `FeaturesKit` initializer. No prompt sheet shown.

## Changes

### Phase 1: Lib-side (FeaturesKit)

**1. Local identity storage**

Create `UserIdentity` model and `IdentityStore` (UserDefaults-backed, same pattern as `DeviceID`).

```
struct UserIdentity: Codable {
    let displayName: String
    let email: String?
}

enum IdentityStore {
    private static let key = "com.featureskit.user-identity"

    static func load() -> UserIdentity?
    static func save(_ identity: UserIdentity)
    static func clear()
}
```

**2. Identity prompt sheet**

Create `IdentitySheet` view:
- Text field for display name (required)
- Text field for email (optional)
- "Continue" button, disabled until display name is non-empty
- Shown once via `.sheet` when `IdentityStore.load() == nil` and no app-managed identity was provided

**3. Update FeaturesKit public API**

Add optional identity parameters to the initializer:

```swift
public init(
    _ apiKey: String,
    baseURL: String = "https://your-domain.com",
    userId: String? = nil,
    displayName: String? = nil,
    email: String? = nil,
    showSubmitButton: Bool = true
)
```

When `displayName` is provided, skip the identity sheet entirely (app-managed mode).

When neither `displayName` nor a stored identity exists, show the sheet before proceeding.

**4. Wire identity through to the client**

- `FeaturesClient` gets `displayName` and `email` properties
- `makeRequest` sends `X-Display-Name` and `X-Email` headers on relevant requests (comments, request creation)
- `addComment` includes `display_name` and `email` in the POST body

**5. Update Comment model and CommentRow**

- Add `displayName: String?` and `email: String?` to `Comment`
- `CommentRow` shows `displayName` when present, falls back to truncated deviceId

### Phase 2: Server-side (features SaaS)

**1. DB migration**

Add columns to `comments` table:
```sql
ALTER TABLE comments ADD COLUMN display_name TEXT;
ALTER TABLE comments ADD COLUMN email TEXT;
```

Same for `requests` table (the submitter identity):
```sql
ALTER TABLE requests ADD COLUMN display_name TEXT;
ALTER TABLE requests ADD COLUMN email TEXT;
```

**2. Update comment creation endpoint**

`POST /api/v1/requests/[id]/comments` accepts `display_name` and `email` in the body, stores them alongside the comment.

**3. Update request creation endpoint**

`POST /api/v1/requests` accepts `display_name` and `email` in the body.

**4. Response payloads**

Include `display_name` and `email` in comment and request JSON responses so the lib can display them.

## File Inventory

Lib files to change:
- `Sources/FeaturesKit/FeaturesKit.swift` -- add init params, sheet presentation
- `Sources/FeaturesKit/Client/FeaturesClient.swift` -- add identity headers/body fields
- `Sources/FeaturesKit/Client/Models.swift` -- add displayName/email to Comment
- `Sources/FeaturesKit/Views/CommentRow.swift` -- display name instead of deviceId
- New: `Sources/FeaturesKit/Client/IdentityStore.swift`
- New: `Sources/FeaturesKit/Views/IdentitySheet.swift`

Server files to change:
- New migration SQL
- `src/app/api/v1/requests/[id]/comments/route.ts` -- accept/store display_name, email
- `src/app/api/v1/requests/route.ts` -- accept/store display_name, email
