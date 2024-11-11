// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import X509

final class CertificatesModel {
    let topLevelDomain: String
    let title: String
    let URL: String
    var certificates = [Certificate]()
    var selectedCertificateIndex: Int = 0

    init(topLevelDomain: String,
         title: String,
         URL: String,
         certificates: [Certificate]) {
        self.topLevelDomain = topLevelDomain
        self.title = title
        self.URL = URL
        self.certificates = certificates
    }

    func getDNSNamesList(from input: String) -> [String] {
        let pattern = #"DNSName\("([^"]+)"\)"#
        var dnsNames: [String] = []
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
            for match in matches {
                if let range = Range(match.range(at: 1), in: input) {
                    let dnsNameString = String(input[range])
                    dnsNames.append(dnsNameString)
                }
            }
            return dnsNames
        } catch {
            return []
        }
    }

    func getDNSNames(for certificate: Certificate) -> CertificateItems {
        var dnsNames: CertificateItems = []
        if let certificateExtension =
            certificate.extensions.first(where: { $0.description.contains("SubjectAlternativeNames") }) {
            for dnsName in getDNSNamesList(from: certificateExtension.description) {
                dnsNames.append((.Menu.EnhancedTrackingProtection.certificateSubjectAltNamesDNSName, dnsName))
            }
        }
        return dnsNames
    }
}
