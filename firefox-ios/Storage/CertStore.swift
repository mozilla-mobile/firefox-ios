// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit

/// In-memory certificate store.
open class CertStore {
    fileprivate var keys = Set<String>()
    fileprivate var origins = Set<String>()
    fileprivate var certificateChains = [String: [SecCertificate]]()

    public init() {}

    open func addCertificate(_ cert: SecCertificate, forOrigin origin: String) {
        let data: Data = SecCertificateCopyData(cert) as Data
        let key = keyForData(data, origin: origin)
        keys.insert(key)
        origins.insert(origin)
    }

    open func containsCertificate(_ cert: SecCertificate, forOrigin origin: String) -> Bool {
        let data: Data = SecCertificateCopyData(cert) as Data
        let key = keyForData(data, origin: origin)
        return keys.contains(key)
    }

    open func hasCertificate(forOrigin origin: String) -> Bool {
        return origins.contains(origin)
    }

    open func setCertificateChain(_ certChain: [SecCertificate], forOrigin origin: String) {
        certificateChains[origin] = certChain
    }

    open func certificateChain(forOrigin origin: String) -> [SecCertificate]? {
        return certificateChains[origin]
    }

    public static func origin(for url: URL) -> String? {
        guard let host = url.host else { return nil }
        let port = url.port ?? 443
        return "\(host):\(port)"
    }

    fileprivate func keyForData(_ data: Data, origin: String) -> String {
        return "\(origin)/\(data.sha256.hexEncodedString)"
    }
}
