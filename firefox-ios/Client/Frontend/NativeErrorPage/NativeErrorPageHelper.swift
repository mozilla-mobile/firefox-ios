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

let CertErrors: [Int] = [
    NSURLErrorServerCertificateUntrusted,
    NSURLErrorServerCertificateHasBadDate,
    NSURLErrorServerCertificateHasUnknownRoot,
    NSURLErrorServerCertificateNotYetValid
]

class NativeErrorPageHelper {
    private enum Constants {
        static let certErrorQueryParam = "certerror"
        static let badCertQueryParam = "badcert"
        static let codeQueryParam = "code"
        static let cfStreamErrorCodeKey = "_kCFStreamErrorCodeKey"
        static let peerCertificateChainKey = "NSErrorPeerCertificateChainKey"
        static let defaultBadCertDomainError = "SSL_ERROR_BAD_CERT_DOMAIN"
        static let sslErrorBadCertDomainCode = -9843
        static let wrongHostMarker = "wrong.host"
        static let badSSLHostMarker = "badssl"
        static let domainDescriptionMarker = "domain"
        static let hostnameDescriptionMarker = "hostname"
    }

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

    // MARK: - Static Helpers

    /// Returns whether the given NSURLError code represents a certificate error.
    static func isCertificateErrorCode(_ code: Int) -> Bool {
        return CertErrors.contains(code)
    }

    /// Extracts the CFStream certificate error code embedded in the underlying NSError, if present.
    private static func certStreamErrorCode(from error: NSError) -> Int? {
        guard
            let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
            let certErrorCode = underlyingError.userInfo[Constants.cfStreamErrorCodeKey] as? Int
        else { return nil }
        return certErrorCode
    }

    /// Returns true when the error is a certificate error caused by a
    /// hostname mismatch (SSL_ERROR_BAD_CERT_DOMAIN / -9843). Other certificate
    /// failures return false so they fall back to the legacy HTML error page
    static func isBadCertDomainError(_ error: NSError) -> Bool {
        guard isCertificateErrorCode(error.code) else { return false }
        return certStreamErrorCode(from: error) == Constants.sslErrorBadCertDomainCode
    }

    /// Centralized predicate for whether we should show the native UI for a wrong-host certificate error.
    static func shouldShowNativeBadCertDomainErrorPage(
        for error: NSError,
        isOtherErrorPagesEnabled: Bool
    ) -> Bool {
        return isOtherErrorPagesEnabled && isBadCertDomainError(error)
    }

    /// Determines the native error page type for a given error, respecting feature flags
    /// Returns nil if no native error page should be shown for this error
    static func networkErrorType(
        for error: NSError,
        isNICEnabled: Bool,
        isBadCertEnabled: Bool
    ) -> NetworkErrorType? {
        let noInternetCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
        if isNICEnabled && error.code == noInternetCode {
            return .noInternetConnection
        }
        if shouldShowNativeBadCertDomainErrorPage(for: error, isOtherErrorPagesEnabled: isBadCertEnabled) {
            return .badCertDomain
        }
        return nil
    }

    /// Builds the full set of URL query items for an error page, including
    /// certificate-specific items when the error is a certificate error.
    static func buildErrorPageQueryItems(for error: NSError, url: URL) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: InternalURL.Param.url.rawValue, value: url.absoluteString),
            URLQueryItem(name: Constants.codeQueryParam, value: String(error.code))
        ]

        if isCertificateErrorCode(error.code) {
            queryItems.append(contentsOf: buildCertificateQueryItems(for: error))
        }

        return queryItems
    }

    /// Checks whether a given error page URL encodes a bad-cert-domain error.
    /// Other certificate errors return false and use the legacy HTML error page.
    static func isBadCertDomainErrorURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let codeString = components.queryItems?.first(where: {
                  $0.name == Constants.codeQueryParam
              })?.value,
              let errCode = Int(codeString),
              isCertificateErrorCode(errCode)
        else { return false }

        let certError = components.queryItems?.first(where: {
            $0.name == Constants.certErrorQueryParam
        })?.value
        return certError == Constants.defaultBadCertDomainError
    }

    /// Logs diagnostic details for a certificate error to aid debugging.
    static func logCertificateErrorDetails(
        error: NSError,
        url: URL,
        errorPageURL: URL,
        logger: Logger
    ) {
        let hasUnderlyingError = error.userInfo[NSUnderlyingErrorKey] != nil
        let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError
        let hasCertErrorCode = underlying?.userInfo[Constants.cfStreamErrorCodeKey] != nil
        logger.log(
            "NativeErrorPage: Dispatching certificate error",
            level: .debug,
            category: .webview,
            extra: [
                "errorCode": "\(error.code)",
                "hasUnderlyingError": "\(hasUnderlyingError)",
                "hasCertErrorCode": "\(hasCertErrorCode)",
                "url": url.absoluteString,
                "errorPageURL": errorPageURL.absoluteString
            ]
        )
    }

    // MARK: - Instance Methods

    func parseErrorDetails() -> ErrorPageModel {
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
            case NSURLErrorServerCertificateUntrusted,
                 NSURLErrorServerCertificateHasBadDate,
                 NSURLErrorServerCertificateHasUnknownRoot,
                 NSURLErrorServerCertificateNotYetValid:
                Self.buildCertificateErrorModel(for: error, url: url)
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
            let certChain = error.userInfo[Constants.peerCertificateChainKey] as? [SecCertificate],
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

    // MARK: - Private

    /// Builds certificate-specific query items (cert error name and encoded certificate)
    /// from the given NSError for inclusion in an error page URL.
    private static func buildCertificateQueryItems(for error: NSError) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()

        if let certErrorCode = certStreamErrorCode(from: error),
           let certErrorString = CertErrorCodes[certErrorCode] {
            queryItems.append(URLQueryItem(
                name: Constants.certErrorQueryParam,
                value: certErrorString
            ))
        }

        if let certChain = error.userInfo[Constants.peerCertificateChainKey] as? [SecCertificate],
           let cert = certChain.first {
            let encodedCert = (SecCertificateCopyData(cert) as Data).base64EncodedString
            queryItems.append(URLQueryItem(
                name: Constants.badCertQueryParam,
                value: encodedCert
            ))
        }

        return queryItems
    }

    /// Builds an ErrorPageModel for certificate errors, using the advanced section
    /// for SSL_ERROR_BAD_CERT_DOMAIN and a generic model otherwise.
    private static func buildCertificateErrorModel(
        for error: NSError,
        url: URL
    ) -> ErrorPageModel {
        guard error.domain == NSURLErrorDomain else {
            return ErrorPageModel(
                errorTitle: .NativeErrorPage.GenericError.TitleLabel,
                errorDescription: .NativeErrorPage.GenericError.Description,
                foxImageName: ImageIdentifiers.NativeErrorPage.securityError,
                url: url,
                advancedSection: nil,
                showGoBackButton: false
            )
        }

        // TODO: FXIOS-14569 — Investigate using SecTrustEvaluateWithError to evaluate TLS trust
        // errors instead of private APIs.
        if certStreamErrorCode(from: error) == Constants.sslErrorBadCertDomainCode {
            let appName = AppName.shortName.description
            let securityInfo = String.NativeErrorPage.BadCertDomain.AdvancedSecurityInfo
            let certificateInfo = String(
                format: String.NativeErrorPage.BadCertDomain.AdvancedInfo,
                appName,
                url.absoluteString
            )
            let advancedInfo = "\(securityInfo)\n\n\(certificateInfo)"
            let warningText = """
            \(String.NativeErrorPage.BadCertDomain.AdvancedWarning1)
            \(String.NativeErrorPage.BadCertDomain.AdvancedWarning2)
            """

            let advancedSection = ErrorPageModel.AdvancedSectionConfig(
                buttonText: String.NativeErrorPage.BadCertDomain.AdvancedButton,
                infoText: advancedInfo,
                warningText: warningText,
                certificateErrorCode: CertErrorCodes[Constants.sslErrorBadCertDomainCode]!,
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
}
