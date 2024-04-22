// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security
import CryptoKit
import X509
import SwiftASN1

class CertificatesHandler {
    private let serverTrust: SecTrust
    var certificates = [Certificate]()

    /// Initializes a new `CertificatesHandler` with the given server trust.
    /// - Parameters:
    ///   - serverTrust: The server trust containing the certificate chain.
    init(serverTrust: SecTrust) {
        self.serverTrust = serverTrust
    }

    /// Extracts and handles the certificate chain.
    func handleCertificates() {
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return
        }
        for (_, certificate) in certificateChain.enumerated() {
            let certificateData = SecCertificateCopyData(certificate) as Data
            do {
                let certificate = try Certificate(derEncoded: Array(certificateData))
                certificates.append(certificate)
            } catch {
            }
        }
    }
}
