// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import GCDWebServers
import Shared
import Storage

class NativeErrorPageHelper {
    // Regardless of cause, NSURLErrorServerCertificateUntrusted is currently returned in all cases.
    // Check the other cases in case this gets fixed in the future.
    private let CertErrors = [
        NSURLErrorServerCertificateUntrusted,
        NSURLErrorServerCertificateHasBadDate,
        NSURLErrorServerCertificateHasUnknownRoot,
        NSURLErrorServerCertificateNotYetValid
    ]

    // Error codes copied from Gecko. The ints corresponding to these codes were determined
    // by inspecting the NSError in each of these cases.
    private let CertErrorCodes = [
        -9813: "SEC_ERROR_UNKNOWN_ISSUER",
        -9814: "SEC_ERROR_EXPIRED_CERTIFICATE",
        -9843: "SSL_ERROR_BAD_CERT_DOMAIN",
    ]

    var certStore: CertStore?
    var logger: Logger
    var error: NSError
    var url: URL
    var webViewUrl: URL?

    // Independent query items as Strings
    var urlItem: String {
        return url.absoluteString
    }

    var errorCodeItem: String {
        return String(error.code)
    }

    var errorDomainItem: String {
        return error.domain
    }

    var errorDescriptionItem: String {
        return error.localizedDescription
    }

    var timestampItem: String {
        let timestamp = "\(Int(Date().timeIntervalSince1970 * 1000))"
        return timestamp
    }

    var certErrorItem: String? {
        guard CertErrors.contains(error.code),
              let certChain = error.userInfo["NSErrorPeerCertificateChainKey"] as? [SecCertificate],
              let cert = certChain.first else {
            return nil
        }
        let encodedCert = (SecCertificateCopyData(cert) as Data).base64EncodedString()
        return encodedCert
    }

    var certErrorCodeItem: String? {
        guard let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
              let certErrorCode = underlyingError.userInfo["_kCFStreamErrorCodeKey"] as? Int else {
            return nil
        }
        let certError = CertErrorCodes[certErrorCode] ?? ""
        return certError
    }

    init(certStore: CertStore?,
         logger: Logger = DefaultLogger.shared,
         error: NSError,
         url: URL,
         webViewUrl: URL?) {
        self.certStore = certStore
        self.logger = logger
        self.error = error
        self.url = url
        self.webViewUrl = webViewUrl
    }

    // Function to check if the error page is already being shown
    func isErrorPageAlreadyShown() -> Bool {
        guard let webViewUrl = webViewUrl,
              let internalUrl = InternalURL(webViewUrl),
              internalUrl.originalURLFromErrorPage == url else {
            return false
        }
        return true
    }

    // Function to construct the error page URL (without query items)
    func constructErrorPageUrl() -> URL? {
        guard let components = URLComponents(string: "\(InternalURL.baseUrl)/\(ErrorPageHandler.path)") else { return nil }

        // The URL is returned based on the provided components; query items are not appended.
        return components.url
    }
}
