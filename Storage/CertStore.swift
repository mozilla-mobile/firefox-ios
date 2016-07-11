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

    public func addCertificate(_ cert: SecCertificate, forOrigin origin: String) {
        let data: Data = SecCertificateCopyData(cert) as Data
        let key = key(forData: data, origin: origin)
        keys.insert(key)
    }

    public func containsCertificate(_ cert: SecCertificate, forOrigin origin: String) -> Bool {
        let data: Data = SecCertificateCopyData(cert) as Data
        let key = key(forData: data, origin: origin)
        return keys.contains(key)
    }

    private func key(forData data: Data, origin: String) -> String {
        return "\(origin)/\(data.sha256.hexEncodedString)"
    }
}
