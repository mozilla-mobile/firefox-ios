/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
#if canImport(MozillaRustComponents)
    import MozillaRustComponents
#endif

/// The public interface to viaduct.
///
/// This is a singleton, and should be used via the
/// `shared` static member.
public class Viaduct {
    /// The singleton instance of Viaduct
    /// FIXME: FXIOS-13501 Unprotected shared mutable state is an error in Swift 6
    public nonisolated(unsafe) static let shared = Viaduct()

    private init() {}

    public func initialize() {
        // Note: This function doesn't need to synchronize since the Rust functions are thread-safe.

        // This value comes from a very old workaround for FxA/Push.  We should probably get rid of
        // this at some point and move to the value from `UserAgent.swift`.  However, make sure to
        // first investigate that this old comment no longer applies:
        //
        // > The FxA servers rely on the UA agent to filter
        // > some push messages directed to iOS devices.
        // > This is obviously a terrible hack and we should
        // > probably do https://github.com/mozilla/application-services/issues/1326
        // > instead, but this will unblock us for now.
        setGlobalDefaultUserAgent(userAgent: "Firefox-iOS-FxA/24")
        do {
            try viaductInitBackendHyper()
        } catch {
            // The last line will throw if we try to initialize more than once.
            // Just ignore the error in this case.
        }
    }
}
