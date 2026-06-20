# User Identity in FeaturesKit

## Identity Fields

| Field | Source | Sent As | Always Present | Unique |
|-------|--------|---------|----------------|--------|
| deviceId | Generated UUID, persisted in UserDefaults | `X-Device-ID` header | Yes | Per device |
| userId | App parameter | `X-User-ID` header | No (optional) | App-defined |
| displayName | App parameter or IdentitySheet | POST body `display_name` | No | No constraint |
| email | App parameter or IdentitySheet | POST body `email` | No | No constraint |

## Storage

**DeviceID** (`com.featureskit.device-id` in UserDefaults)
- UUID generated on first access, cached in memory, persists across launches
- Sent on every API request via `X-Device-ID` header
- Acts as the baseline device-level identifier

**IdentityStore** (`com.featureskit.user-identity` in UserDefaults)
- Stores `UserIdentity { displayName: String, email: String? }` as JSON
- Only written when a user submits the IdentitySheet (self-serve mode)
- Not written in app-managed mode (app re-provides displayName each init)

## Identity Resolution (three-tier fallback)

On `FeaturesKit.init`, the mode is implicit -- there is no `appManagedIdentity` parameter. It is determined by whether `displayName` is passed:

```swift
// App-managed: pass displayName -> appManagedIdentity = true
FeaturesKit("key", userId: "u-123", displayName: "Jane", email: "jane@co.com")

// Self-serve: omit displayName -> appManagedIdentity = false
FeaturesKit("key")
```

1. **App-managed**: `displayName` parameter provided -> use it directly, skip sheet, set `appManagedIdentity = true`
2. **Stored**: `IdentityStore.load()` returns saved identity -> use it, skip sheet
3. **Sheet**: no identity available -> present IdentitySheet modal, user enters displayName (required) + email (optional)

## How Identity Flows to API

**Headers** (every request):
- `X-API-Key` (always)
- `X-Device-ID` (always)
- `X-User-ID` (only if app provided userId)

**POST body** (createRequest, addComment only):
- `display_name` (if available)
- `email` (if available)

Votes only use headers for identity (no body fields).

## Display Fallback

When showing who submitted a request or comment:

1. `displayName` if present and non-empty -> shown in full
2. `deviceId` truncated to 8 chars + "..." -> fallback for anonymous

## Same Username Problem

There is no server-side uniqueness constraint on `displayName`. Two users could submit the same display name.

**Interim mitigation (self-serve mode only):** When a user submits the IdentitySheet, the last 5 characters of their `deviceId` are appended as a suffix: `John` becomes `John_a4f2b`. This makes display names visually distinct per device without requiring server-side uniqueness checks.

App-managed identity is not modified -- the app controls uniqueness in that mode.

The actual identity differentiation happens at the device/user level:
- `deviceId` is unique per device (UUID)
- `userId` is unique per user if the app provides it
- `displayName` is cosmetic attribution with a device-derived suffix for self-serve users

## Dashboard-Created Requests

When requests are created from the admin dashboard, no `displayName` is set on the record. The client receives `displayName: null` and falls back to showing a truncated deviceId (e.g., "dashboar..."). This is a server-side gap -- the dashboard should populate `display_name` with "Dashboard" or the admin's name.
