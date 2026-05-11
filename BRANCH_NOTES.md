# Firefox VPN (IP Protection via Relay proxy)

The proposed implementation add a proof-of-concept VPN/IP Protection feature that routes browser traffic through Mozilla's Guardian proxy servers via WebKit's native `ProxyConfiguration` API. It does **not** use a `NEVPNManager` system VPN tunnel. It also does **not** proxy the whole device, traffic is proxied at the WebKit level only.

This document has two purposes:
1. Document the code changes in https://github.com/mozilla-mobile/firefox-ios/pull/33549 to make the proposed data flow clear
2. Investigate open questions that came out of this implementation

The take away is the biggest concern here is the way that we have to configure the proxy. It is configured at the webview configurations data store. Historically we create this one time and never recreate it. This has been a source of many cookie and browser history bugs. With the proxy configuration we will have to recreate the store, hopefully copy over all data and cookies and then reload the selected tab webview from scratch. All other webviews should be discarded. Selecting a tab will reload the webview with the new proxy configuration, and reloading all available webviews when the vpn is toggled won't be performant.

---

## New Files

### `VPNControllerProtocol.swift`
Defines the public surface for the VPN feature:
- `VPNControllerProtocol` — `isRunning`, `start(privateOnly:completion:)`, `stop()`
- `VPNError` — `unsupportedOS`, `notSignedIn`, `noServerFound`
- `StubVPNController` — no-op fallback for iOS < 17 (immediately returns `.failure(.unsupportedOS)`)

### `VPNController.swift` (iOS 17+, `@MainActor`)
Orchestrates startup and teardown:
1. Mints a short-lived FxA access token using the new `vpn` OAuth scope
2. Calls `VPNGuardian.getPass()` to obtain a proxy bearer token
3. Asks `VPNServerlist.selectServer()` for a relay endpoint
4. Builds a `ProxyConfiguration` with an HTTP/2 `RelayHop` (Proxy-Authorization header)
5. Applies it to WKWebView data stores via `DefaultWKEngineConfigurationProvider.applyProxyConfigurations`

### `VPNGuardian.swift`
HTTP client for the Mozilla Guardian API (`https://vpn.mozilla.org`):
- `GET /api/v1/fpn/token` → `ProxyPass` — a JWT bearer token plus quota information parsed from response headers (`X-Quota-Limit`, `X-Quota-Remaining`, `X-Quota-Reset`)
- `POST /api/v1/fpn/activate` → `Entitlement` — enrolls a user and returns their subscription/byte-quota info
- JWT claims (`nbf`/`exp`) are decoded in-house without a third-party library; `X-Quota-Reset` is an RFC3339 timestamp with fractional seconds requiring a custom `ISO8601DateFormatter`

### `VPNServerlist.swift`
Reads the `vpn-serverlist` Remote Settings collection (same collection used by Firefox Desktop at `toolkit/components/ipprotection/IPProtectionServerlist.sys.mjs`):
- Decodes Country → City → Server → Protocol records
- Prefers the `REC` (recommended) pseudo-country, then falls back to the first non-quarantined server overall
- Prefers the `masque` protocol's host/port when present; falls back to the server's top-level `hostname`/`port` (default 443)

---

## Modified Files

### `BrowserKit/.../WKEngineConfigurationProvider.swift`
- Added `ProxyScope` option set (`.normal`, `.private`, `.all`)
- Added `applyProxyConfigurations(_:scope:)` static method that writes `proxyConfigurations` onto the default and/or non-persistent `WKWebsiteDataStore`

### `AppDelegate.swift`
- Added a lazy `vpnController: VPNControllerProtocol` property; returns `VPNController()` on iOS 17+, `StubVPNController()` otherwise

### `MainMenuConfigurationUtility.swift`
- _These chanages are just for demo purposes_
- Adds a "VPN" toggle item to the main menu in every context (unconditionally appended)
- Calls `vpn.start(privateOnly: false)` or `vpn.stop()` on tap; shows "On"/"Off" as the info label

### `MozillaRustComponents/.../FxAccountOAuth.swift`
- Added `OAuthScope.vpn = "https://identity.mozilla.com/apps/vpn"`

### `RustFirefoxAccounts.swift`, `FxAWebViewModel.swift`, `FirefoxAccountSignInViewController.swift`
- Added `OAuthScope.vpn` to the scope lists used when creating the account manager and during all FxA sign-in flows

---

## Known TODOs (left in code comments)

| # | Location | Issue |
|---|----------|-------|
| 1 | `VPNController.start` | A 403 from `getPass()` means the user isn't enrolled — need to call `guardian.activate()` first |
| 2 | `VPNController.start` | WebKit may reuse existing connections established before the proxy was applied; iOS team input needed on how to flush the connection pool |
| 3 | `VPNController.start` | No token rotation yet — need a background watcher to refresh the proxy pass before it expires |
| 4 | `VPNController.toProxyConf` | `http3RelayEndpoint` causes QUIC errors; only HTTP/2 relay is wired up until Fastly is consulted |

---
## Follow up Investigations

### Findings on relay-hop failures

When the relay hop fails, WebKit surfaces it through the navigation delegate's `didFailProvisionalNavigation` callback with the error:

> **"Could not connect to the server."** — `NSURLErrorCannotConnectToHost` (code `-1004`)

This is a generic Foundation networking error, but it has been the consistent failure signature across the cases I tested:
- Faking an invalid proxy bearer token
- Configuring an `http3RelayEndpoint` (which trips the QUIC error path noted in TODO #4)

Other failure modes may surface differently — these are the only two cases observed so far, and WebKit doesn't appear to give us a more specific signal for proxy-layer failures.

We could leverage Native error pages here for this error type if a proxy configuration is set to provide additional error info. Something like "This could be an issue with the VPN, try disconnecting if the error persists"/

---

### Resetting connections on proxy change

`WKWebsiteDataStore.proxyConfigurations` is a property assignment — setting it does **not** invalidate the network process's connection pool. Connections established before the proxy was applied can be reused, bypassing the proxy entirely. WebKit doesn't expose any public API to flush the pool directly. Two options, in increasing cost / correctness:

1. **Reload tabs after proxy change.** Call `reloadFromOrigin()` on every webview after `applyProxyConfigurations`. Cheap; pooled keep-alives to already-visited hosts may still be reused, so this is best-effort. _Worth trying first to validate the rest of the pipeline._
2. **Rebuild WKWebViews against a new data store.** Each `WKWebsiteDataStore` has its own connection pool, so swapping stores guarantees a clean pool. Invasive: every live `WKWebView` must be recreated. _This is the right solution — option 1 is not enough for a privacy feature._

We technically can keep the status quo, but this this probably is not acceptable for uses:

1. **Stay on `.default()` forever.** Accept brief leakage around the proxy until WebKit's idle timeout drains the pool.

#### Rebuild websiteDataStore when VPN is turned on

`WKWebViewConfiguration.websiteDataStore` is effectively immutable once the configuration has been used. So a swap means: mint a fresh store, apply the proxy to it, point new configurations at it, and rebuild every existing webview against a new configuration. Currently we keep as many webviews as tabs you have opened alive. In general this is a memory concern but if you have to loop through and reload every alive webview it will be non perfomant. The proposal here is to:
1. Recreate the store
2. Configure proxy configuration on the new store
3. Copy over all cookies and data from the old store to the new store
4. Discard all webviews in memory
5. Discard and restore all tabs from memory
6. Recreate the selected tabs webview (basically "reselect" the selected tab)

- **Cookie / storage migration.** Each `WKWebsiteDataStore(forIdentifier:)` is fully isolated: its own cookie jar, its own `localStorage`, its own IndexedDB. A naive swap will appear to log the user out of every site. Cookies can be copied with the public API:
  ```swift
  let cookies = await oldStore.httpCookieStore.allCookies()
  for c in cookies { await newStore.httpCookieStore.setCookie(c) }
  ```
  `localStorage`, IndexedDB, and service-worker registrations have no public copy API. It is possible that there is no way to get around losing this data for VPN on sessions. Practical options: (a) accept the loss for the first cut, (b) keep one stable "VPN-on" store and one stable "VPN-off" store with persistent identifiers — that's a defensible privacy boundary (state set under VPN-on doesn't leak to VPN-off) and avoids the migration question entirely.
- **Old store lifetime.** Don't release the old store until rebuild is finished — outstanding requests hold a reference. After rebuild completes, call `WKWebsiteDataStore.removeDataStore(forIdentifier:)` to free the disk footprint of any throwaway store.
- **Identifier strategy.** Our current store is the default store. For VPN we will need to create a new store that is specified by a UUID so that we can clean it up later. We need to decide how we would like to identify this store and if we can keep the same store for different VPN sessions (I think we can't).

##### Open Questions
1. We need to confrim that we only have to do this store reset when the proxy is turned on/off. If we have to do this every time the authenticaiton token "rotates" (every 15 min), this will be a poor user experience.
2. We need to profile how long this reset process will take. iOS users are used to being able to turn device level vpns on and off almost instantaneously. This store reset could be slow. It is possible that tab restore could happen in the background but that is not the way it works currently. 
3. Confirm that we actaully need Tab Restore
