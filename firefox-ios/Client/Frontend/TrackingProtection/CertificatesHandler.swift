// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security
import CryptoKit
import X509
import SwiftASN1
import Common

class CertificatesHandler {
    private let serverTrust: SecTrust

    /// Initializes a new `CertificatesHandler` with the given server trust.
    /// - Parameters:
    ///   - serverTrust: The server trust containing the certificate chain.
    init(serverTrust: SecTrust) {
        self.serverTrust = serverTrust
    }

    /// Extracts and handles the certificate chain.
    /// - Parameters:
    ///   - completion: A completion block that provides the extracted certificates.
    func handleCertificates() -> [Certificate] {
        var certificates = [Certificate]()
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return certificates
        }
        for certificate in certificateChain {
            let certificateData = SecCertificateCopyData(certificate) as Data
            do {
                let certificate = try Certificate(derEncoded: Array(certificateData))
                certificates.append(certificate)
            } catch {
                DefaultLogger.shared.log("\(error)",
                                         level: .warning,
                                         category: .homepage)
            }
        }
        return certificates
    }
}

// Define a function to get the certificates for a given URL
func getCertificates(for url: URL, completion: @escaping ([Certificate]?) -> Void) {
    // Create a URL session with a custom delegate
    let session = URLSession(configuration: .default,
                             delegate: CertificateDelegate(completion: completion),
                             delegateQueue: nil)

    // Start a data task to trigger the certificate retrieval
    let task = session.dataTask(with: url) { _, _, error in
        if let error = error {
            DefaultLogger.shared.log("\(error)",
                                     level: .warning,
                                     category: .homepage)
            completion(nil)
        }
    }

    task.resume()
}

// Custom delegate to handle the authentication challenge
class CertificateDelegate: NSObject, URLSessionDelegate {
    private let completion: ([Certificate]?) -> Void

    init(completion: @escaping ([Certificate]?) -> Void) {
        self.completion = completion
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (
        URLSession.AuthChallengeDisposition,
        URLCredential?
    ) {
        if let serverTrust = challenge.protectionSpace.serverTrust {
            let certificatesHandler = CertificatesHandler(serverTrust: serverTrust)
            self.completion(certificatesHandler.handleCertificates())
            return (.useCredential, URLCredential(trust: serverTrust))
        } else {
            self.completion(nil)
            return (.cancelAuthenticationChallenge, nil)
        }
    }
}
