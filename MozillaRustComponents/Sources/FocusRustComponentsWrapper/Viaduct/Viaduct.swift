/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
#if canImport(MozillaRustComponents)
    import MozillaRustComponents
#endif

/// The public interface to viaduct.
/// Right now it doesn't do any "true" viaduct things,
/// it simply activated the reqwest backend.
///
/// This is a singleton, and should be used via the
/// `shared` static member.
public class Viaduct {
    /// The singleton instance of Viaduct
    public static let shared = Viaduct()

    private init() {}

    public func useReqwestBackend() {
        // Note: Doesn't need to synchronize since
        // use_reqwest_backend is backend by a CallOnce.
        viaduct_use_reqwest_backend()
    }
}
