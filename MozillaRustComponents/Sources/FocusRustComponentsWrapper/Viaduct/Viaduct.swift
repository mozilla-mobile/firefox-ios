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
    public static let shared = Viaduct()

    private init() {}

    public func initialize() {
        // This method is a no-op that exists for historical reasons. Focus
        // contains Nimbus code, which depends on viaduct but Nimbus is never
        // actually used.
    }
}
