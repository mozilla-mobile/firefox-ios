// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import Security

// Error codes copied from Gecko. The ints corresponding to these codes were determined
// by inspecting the NSError in each of these cases.
// This replaces the legacy CertErrorCodes in ErrorPageHelper.swift.
let CertErrorCodes: [Int: String] = [
    -9813: "SEC_ERROR_UNKNOWN_ISSUER",
    -9814: "SEC_ERROR_EXPIRED_CERTIFICATE",
    -9843: "SSL_ERROR_BAD_CERT_DOMAIN",
]

class NativeErrorPageHelper {
    /// Holds the parsed certificate details extracted from an NSError.
    struct CertDetails {
        let failingURL: URL
        let host: String
        let certChain: [SecCertificate]
        let cert: SecCertificate
    }

    enum NetworkErrorType {
        case noInternetConnection
        case badCertDomain
    }

    var error: NSError

    var errorDescriptionItem: String {
        return error.localizedDescription
    }

    init(error: NSError) {
        self.error = error
    }

    func parseErrorDetails() -> ErrorPageModel {
        // Helper function to handle certificate errors
        func handleCertificateError(url: URL) -> ErrorPageModel {
            // Check error domain for safety
            guard error.domain == NSURLErrorDomain else {
                // Not a URL error domain - show generic error
                return ErrorPageModel(
                    errorTitle: .NativeErrorPage.GenericError.TitleLabel,
                    errorDescription: .NativeErrorPage.GenericError.Description,
                    foxImageName: ImageIdentifiers.NativeErrorPage.securityError,
                    url: url,
                    advancedSection: nil,
                    showGoBackButton: false
                )
            }

            // TODO: FXIOS-14569
            // Check if this is the specific SSL_ERROR_BAD_CERT_DOMAIN error (-9843)
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
               let certErrorCode = underlyingError.userInfo["_kCFStreamErrorCodeKey"] as? Int,
               certErrorCode == -9843 {
                // SSL_ERROR_BAD_CERT_DOMAIN - create model with advanced section
                let appName = AppName.shortName.description
                let securityInfo = String.NativeErrorPage.BadCertDomain.AdvancedSecurityInfo
                let certificateInfo = String(format: String.NativeErrorPage.BadCertDomain.AdvancedInfo,
                                             appName,
                                             url.absoluteString)
                let advancedInfo = "\(securityInfo)\n\(certificateInfo)"
                let warningText = "\(String.NativeErrorPage.BadCertDomain.AdvancedWarning1)\n\(String.NativeErrorPage.BadCertDomain.AdvancedWarning2)"

                let advancedSection = ErrorPageModel.AdvancedSectionConfig(
                    buttonText: String.NativeErrorPage.BadCertDomain.AdvancedButton,
                    infoText: advancedInfo,
                    warningText: warningText,
                    certificateErrorCode: CertErrorCodes[-9843]!,
                    showProceedButton: true
                )

                return ErrorPageModel(
                    errorTitle: String.NativeErrorPage.BadCertDomain.TitleLabel,
                    errorDescription: String.NativeErrorPage.BadCertDomain.Description,
                    foxImageName: ImageIdentifiers.NativeErrorPage.securityError,
                    url: url,
                    advancedSection: advancedSection,
                    showGoBackButton: true
                )
            } else {
                // Other certificate errors - show generic error
                return ErrorPageModel(
                    errorTitle: .NativeErrorPage.GenericError.TitleLabel,
                    errorDescription: .NativeErrorPage.GenericError.Description,
                    foxImageName: ImageIdentifiers.NativeErrorPage.securityError,
                    url: url,
                    advancedSection: nil,
                    showGoBackButton: false
                )
            }
        }

        let model: ErrorPageModel = if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            switch error.code {
            case Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue):
                ErrorPageModel(
                    errorTitle: .NativeErrorPage.NoInternetConnection.TitleLabel,
                    errorDescription: .NativeErrorPage.NoInternetConnection.Description,
                    foxImageName: ImageIdentifiers.NativeErrorPage.noInternetConnection,
                    url: nil,
                    advancedSection: nil,
                    showGoBackButton: false
                )
            // Certificate Errors - new cases added
            case NSURLErrorServerCertificateUntrusted,
                 NSURLErrorServerCertificateHasBadDate,
                 NSURLErrorServerCertificateHasUnknownRoot,
                 NSURLErrorServerCertificateNotYetValid:
                handleCertificateError(url: url)
            default:
                ErrorPageModel(
                    errorTitle: .NativeErrorPage.GenericError.TitleLabel,
                    errorDescription: .NativeErrorPage.GenericError.Description,
                    foxImageName: ImageIdentifiers.NativeErrorPage.securityError,
                    url: url,
                    advancedSection: nil,
                    showGoBackButton: false
                )
            }
        } else {
            ErrorPageModel(
                errorTitle: .NativeErrorPage.NoInternetConnection.TitleLabel,
                errorDescription: .NativeErrorPage.NoInternetConnection.Description,
                foxImageName: ImageIdentifiers.NativeErrorPage.noInternetConnection,
                url: nil,
                advancedSection: nil,
                showGoBackButton: false
            )
        }
        return model
    }

    /// Parses certificate details from the stored error.
    /// Returns nil if any required data (failing URL, host, cert chain) is missing.
    func getCertDetails() -> CertDetails? {
        guard
            let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL,
            let certChain = error.userInfo["NSErrorPeerCertificateChainKey"] as? [SecCertificate],
            let cert = certChain.first,
            let host = failingURL.host
        else { return nil }

        return CertDetails(
            failingURL: failingURL,
            host: host,
            certChain: certChain,
            cert: cert
        )
    }
}
