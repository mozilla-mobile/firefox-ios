// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit

/// In-memory certificate store.
open class CertStore {
    fileprivate var keys = Set<String>()

    public init() {}

    open func addCertificate(_ cert: SecCertificate, forOrigin origin: String) {
        let data: Data = SecCertificateCopyData(cert) as Data
        let key = keyForData(data, origin: origin)
        keys.insert(key)
    }

    open func containsCertificate(_ cert: SecCertificate, forOrigin origin: String) -> Bool {
        let data: Data = SecCertificateCopyData(cert) as Data
        let key = keyForData(data, origin: origin)
        return keys.contains(key)
    }

    open func removeAll() {
        keys.removeAll()
    }

    open func removeCertificates(forDomains domains: Set<String>) {
        domains.forEach { removeCertificates(forDomain: $0) }
    }

    open func removeCertificates(forDomain domain: String) {
        let domain = domain.lowercased()
        keys = keys.filter { key in
            guard let origin = key.split(separator: "/").first else { return true }
            let host = origin.split(separator: ":").first.map(String.init) ?? ""
            return !Self.host(host, matches: domain)
        }
    }

    fileprivate static func host(_ host: String, matches domain: String) -> Bool {
        let host = host.lowercased()
        return host == domain || host.hasSuffix(".\(domain)")
    }

    fileprivate func keyForData(_ data: Data, origin: String) -> String {
        return "\(origin)/\(data.sha256.hexEncodedString)"
    }
}
