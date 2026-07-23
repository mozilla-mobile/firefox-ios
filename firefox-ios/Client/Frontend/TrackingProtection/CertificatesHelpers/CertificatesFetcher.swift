// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Security
import CryptoKit
import X509
import SwiftASN1
import Common

/// Decodes DER-encoded bytes into a parsed `Certificate`. Injectable so tests can drive the
/// error branch of `CertificatesHandler.handleCertificates()` without needing a malformed
/// `SecCertificate` (which the Security framework won't produce).
protocol CertificateDecoding {
    func decodeCertificate(from derBytes: Data) throws -> Certificate
}

struct DefaultCertificateDecoder: CertificateDecoding {
    func decodeCertificate(from derBytes: Data) throws -> Certificate {
        try Certificate(derEncoded: Array(derBytes))
    }
}

/// Fetches the certificate chain served by a URL by driving a `URLSession` and capturing the
/// server trust from the authentication challenge.
final class CertificatesFetcher {
    private let configuration: URLSessionConfiguration
    private let logger: Logger

    /// - Parameters:
    ///   - configuration: `URLSessionConfiguration` used to build the session. Tests can supply a
    ///     configuration wired to a `URLProtocol` stub to avoid real network calls.
    ///   - logger: Logger used to record data-task failures. Defaults to `DefaultLogger.shared`.
    init(configuration: URLSessionConfiguration = .ephemeral,
         logger: Logger = DefaultLogger.shared) {
        self.configuration = configuration
        self.logger = logger
    }

    /// Fetches the certificates for the given URL.
    /// - Parameters:
    ///   - url: URL to fetch the server trust from.
    ///   - completion: Called with the parsed certificate chain, or `nil` on error.
    func getCertificates(for url: URL,
                         completion: @escaping @Sendable ([Certificate]?) -> Void) {
        let logger = self.logger
        let session = URLSession(configuration: configuration,
                                 delegate: CertificateDelegate(completion: completion),
                                 delegateQueue: nil)

        // Start a data task to trigger the certificate retrieval
        let task = session.dataTask(with: url) { _, _, error in
            if let error = error {
                logger.log("\(error)",
                           level: .warning,
                           category: .certificate)
                completion(nil)
            }
        }

        task.resume()
    }
}

final class CertificatesHandler {
    private let serverTrust: SecTrust
    private let decoder: CertificateDecoding
    private let logger: Logger

    /// Initializes a new `CertificatesHandler` with the given server trust.
    /// - Parameters:
    ///   - serverTrust: The server trust containing the certificate chain.
    ///   - decoder: DER decoder used to parse each `SecCertificate`. Defaults to the production decoder.
    ///   - logger: Logger used to record decode failures. Defaults to `DefaultLogger.shared`.
    init(serverTrust: SecTrust,
         decoder: CertificateDecoding = DefaultCertificateDecoder(),
         logger: Logger = DefaultLogger.shared) {
        self.serverTrust = serverTrust
        self.decoder = decoder
        self.logger = logger
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
                let certificate = try decoder.decodeCertificate(from: certificateData)
                certificates.append(certificate)
            } catch {
                logger.log("\(error)",
                           level: .warning,
                           category: .certificate)
            }
        }
        return certificates
    }
}

// Custom delegate to handle the authentication challenge
final class CertificateDelegate: NSObject, URLSessionDelegate {
    private let completion: @Sendable ([Certificate]?) -> Void

    init(completion: @escaping @Sendable ([Certificate]?) -> Void) {
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
