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

    public func initialize(userAgent: String) {
        setGlobalDefaultUserAgent(userAgent: userAgent)
        do {
            try viaductInitBackendHyper()
        } catch {
            // The last line will throw if we try to initialize more than once.
            // Just ignore the error in this case.
        }
    }
}
