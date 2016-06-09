/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit
import Deferred

/// In-memory certificate store.
public class CertStore {
    private var keys = Set<String>()

    public init() {}

    public func addCertificate(cert: SecCertificateRef, forOrigin origin: String) {
        let data: NSData = SecCertificateCopyData(cert)
        let key = keyForData(data, origin: origin)
        keys.insert(key)
    }

    public func containsCertificate(cert: SecCertificateRef, forOrigin origin: String) -> Bool {
        let data: NSData = SecCertificateCopyData(cert)
        let key = keyForData(data, origin: origin)
        return keys.contains(key)
    }

    private func keyForData(data: NSData, origin: String) -> String {
        return "\(origin)/\(data.sha256.hexEncodedString)"
    }
}
