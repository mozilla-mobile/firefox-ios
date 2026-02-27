// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import Security
import X509

/// Certificate-specific extraction helpers for the native error page.
/// Parses certificate data from internal error page URLs (e.g. `badcert` query param).
/// Kept as a dedicated struct: certificate logic is separate from general error-page handling.
struct CertificateHelper {
    private static let badCertQueryParam = "badcert"
    private static let certErrorQueryParam = "certerror"

    /// Name of the certificate error used for domain mismatch (bad cert domain) error pages.
    static let badCertDomainErrorName = "SSL_ERROR_BAD_CERT_DOMAIN"

    /// Extracts the raw certificate data (DER) from an internal error page URL.
    static func certificateDataFromErrorURL(_ url: URL) -> Data? {
        func extract(from url: URL) -> Data? {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let encodedCert = components?.queryItems?.first(where: {
                $0.name == badCertQueryParam
            })?.value,
                  let certData = Data(base64Encoded: encodedCert, options: []) else {
                return nil
            }
            return certData
        }

        // First try the URL directly.
        if let data = extract(from: url) {
            return data
        }

        // Fallback for nested error URLs (e.g. inside a `sessionrestore` URL).
        if let internalUrl = InternalURL(url),
           let extracted = internalUrl.extractedUrlParam {
            return extract(from: extracted)
        }

        return nil
    }

    /// Returns the server certificate as `SecCertificate` for use with `CertStore`.
    static func secCertificateFromErrorURL(_ url: URL) -> SecCertificate? {
        guard let data = certificateDataFromErrorURL(url) else {
            return nil
        }
        return SecCertificateCreateWithData(nil, data as CFData)
    }

    /// Returns a parsed X509 certificate list for use with `CertificatesModel`.
    static func certificatesFromErrorURL(
        _ url: URL,
        logger: Logger = DefaultLogger.shared
    ) -> [Certificate] {
        guard let data = certificateDataFromErrorURL(url) else {
            return []
        }

        do {
            let certificate = try Certificate(derEncoded: Array(data))
            return [certificate]
        } catch {
            logger.log(
                "CertificateHelper: Failed to parse certificate from error URL",
                level: .warning,
                category: .certificate
            )
            return []
        }
    }

    /// Returns whether the URL is a native error page for the bad-cert-domain (domain mismatch) case.
    /// Used to decide when to show the certificate exception / "visit once" flow.
    static func isBadCertDomainErrorPage(url: URL) -> Bool {
        let urlToCheck: URL? = {
            if InternalURL(url)?.isErrorPage == true {
                return url
            }
            if let internalUrl = InternalURL(url), let extracted = internalUrl.extractedUrlParam {
                return InternalURL(extracted)?.isErrorPage == true ? extracted : nil
            }
            return nil
        }()
        guard let target = urlToCheck,
              let components = URLComponents(url: target, resolvingAgainstBaseURL: false),
              let certError = components.queryItems?.first(where: { $0.name == certErrorQueryParam })?.value else {
            return false
        }
        return certError == badCertDomainErrorName
    }
}
