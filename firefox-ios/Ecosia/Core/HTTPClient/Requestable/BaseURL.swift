// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Selects the host a `Requestable` resolves against, and controls which Ecosia-internal
/// headers `BaseRequest.makeURLRequest()` attaches automatically. Mirrors the Android
/// `BaseUrl` sealed class in `NetworkRequest.kt`.
public enum BaseURL: Sendable {
    /// `https://api.<domain>` — `X-Ecosia-App` and Cloudflare Access headers are attached.
    case api
    /// `https://www.<domain>` — same automatic headers as `.api`.
    case web
    /// Caller-supplied URL (e.g. a CDN, or a server-issued presigned upload URL). No
    /// Ecosia-internal headers are attached, since the host isn't guaranteed to be ours.
    ///
    /// This is NOT a host override: `BaseRequest.makeURLRequest()` uses this URL exactly as
    /// given, including its own path and query, ignoring `path`/`queryParameters` entirely.
    /// That matters for e.g. a presigned upload URL, whose path and signed query string must
    /// survive untouched.
    case custom(URL)
}
