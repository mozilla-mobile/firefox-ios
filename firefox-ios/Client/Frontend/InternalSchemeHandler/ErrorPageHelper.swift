// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import GCDWebServers
import Shared
import Storage

private let MozDomain = "mozilla"
private let MozErrorDownloadsNotEnabled = 100
private let MessageOpenInSafari = "openInSafari"
private let MessageCertVisitOnce = "certVisitOnce"

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

private func certFromErrorURL(_ url: URL) -> SecCertificate? {
    func getCert(_ url: URL) -> SecCertificate? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let encodedCert = components?.queryItems?.first(where: { $0.name == "badcert" })?.value,
            let certData = Data(base64Encoded: encodedCert, options: []) {
            return SecCertificateCreateWithData(nil, certData as CFData)
        }

        return nil
    }

    let result = getCert(url)
    if result != nil {
        return result
    }

    // Fallback case when the error url is nested, this happens when restoring an error url,
    // it will be inside a 'sessionrestore' url.
    // TODO: Investigate if we can restore directly as an error url and avoid the 'sessionrestore?url=' wrapping.
    if let internalUrl = InternalURL(url), let url = internalUrl.extractedUrlParam {
        return getCert(url)
    }
    return nil
}

private func cfErrorToName(_ err: CFNetworkErrors) -> String {
    switch err {
    case .cfHostErrorHostNotFound: return "CFHostErrorHostNotFound"
    case .cfHostErrorUnknown: return "CFHostErrorUnknown"
    case .cfsocksErrorUnknownClientVersion: return "CFSOCKSErrorUnknownClientVersion"
    case .cfsocksErrorUnsupportedServerVersion: return "CFSOCKSErrorUnsupportedServerVersion"
    case .cfsocks4ErrorRequestFailed: return "CFSOCKS4ErrorRequestFailed"
    case .cfsocks4ErrorIdentdFailed: return "CFSOCKS4ErrorIdentdFailed"
    case .cfsocks4ErrorIdConflict: return "CFSOCKS4ErrorIdConflict"
    case .cfsocks4ErrorUnknownStatusCode: return "CFSOCKS4ErrorUnknownStatusCode"
    case .cfsocks5ErrorBadState: return "CFSOCKS5ErrorBadState"
    case .cfsocks5ErrorBadResponseAddr: return "CFSOCKS5ErrorBadResponseAddr"
    case .cfsocks5ErrorBadCredentials: return "CFSOCKS5ErrorBadCredentials"
    case .cfsocks5ErrorUnsupportedNegotiationMethod: return "CFSOCKS5ErrorUnsupportedNegotiationMethod"
    case .cfsocks5ErrorNoAcceptableMethod: return "CFSOCKS5ErrorNoAcceptableMethod"
    case .cfftpErrorUnexpectedStatusCode: return "CFFTPErrorUnexpectedStatusCode"
    case .cfErrorHTTPAuthenticationTypeUnsupported: return "CFErrorHTTPAuthenticationTypeUnsupported"
    case .cfErrorHTTPBadCredentials: return "CFErrorHTTPBadCredentials"
    case .cfErrorHTTPConnectionLost: return "CFErrorHTTPConnectionLost"
    case .cfErrorHTTPParseFailure: return "CFErrorHTTPParseFailure"
    case .cfErrorHTTPRedirectionLoopDetected: return "CFErrorHTTPRedirectionLoopDetected"
    case .cfErrorHTTPBadURL: return "CFErrorHTTPBadURL"
    case .cfErrorHTTPProxyConnectionFailure: return "CFErrorHTTPProxyConnectionFailure"
    case .cfErrorHTTPBadProxyCredentials: return "CFErrorHTTPBadProxyCredentials"
    case .cfErrorPACFileError: return "CFErrorPACFileError"
    case .cfErrorPACFileAuth: return "CFErrorPACFileAuth"
    case .cfErrorHTTPSProxyConnectionFailure: return "CFErrorHTTPSProxyConnectionFailure"
    // swiftlint:disable line_length
    case .cfStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod: return "CFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod"
    // swiftlint:enable line_length

    case .cfurlErrorBackgroundSessionInUseByAnotherProcess: return "CFURLErrorBackgroundSessionInUseByAnotherProcess"
    case .cfurlErrorBackgroundSessionWasDisconnected: return "CFURLErrorBackgroundSessionWasDisconnected"
    case .cfurlErrorUnknown: return "CFURLErrorUnknown"
    case .cfurlErrorCancelled: return "CFURLErrorCancelled"
    case .cfurlErrorBadURL: return "CFURLErrorBadURL"
    case .cfurlErrorTimedOut: return "CFURLErrorTimedOut"
    case .cfurlErrorUnsupportedURL: return "CFURLErrorUnsupportedURL"
    case .cfurlErrorCannotFindHost: return "CFURLErrorCannotFindHost"
    case .cfurlErrorCannotConnectToHost: return "CFURLErrorCannotConnectToHost"
    case .cfurlErrorNetworkConnectionLost: return "CFURLErrorNetworkConnectionLost"
    case .cfurlErrorDNSLookupFailed: return "CFURLErrorDNSLookupFailed"
    case .cfurlErrorHTTPTooManyRedirects: return "CFURLErrorHTTPTooManyRedirects"
    case .cfurlErrorResourceUnavailable: return "CFURLErrorResourceUnavailable"
    case .cfurlErrorNotConnectedToInternet: return "CFURLErrorNotConnectedToInternet"
    case .cfurlErrorRedirectToNonExistentLocation: return "CFURLErrorRedirectToNonExistentLocation"
    case .cfurlErrorBadServerResponse: return "CFURLErrorBadServerResponse"
    case .cfurlErrorUserCancelledAuthentication: return "CFURLErrorUserCancelledAuthentication"
    case .cfurlErrorUserAuthenticationRequired: return "CFURLErrorUserAuthenticationRequired"
    case .cfurlErrorZeroByteResource: return "CFURLErrorZeroByteResource"
    case .cfurlErrorCannotDecodeRawData: return "CFURLErrorCannotDecodeRawData"
    case .cfurlErrorCannotDecodeContentData: return "CFURLErrorCannotDecodeContentData"
    case .cfurlErrorCannotParseResponse: return "CFURLErrorCannotParseResponse"
    case .cfurlErrorInternationalRoamingOff: return "CFURLErrorInternationalRoamingOff"
    case .cfurlErrorCallIsActive: return "CFURLErrorCallIsActive"
    case .cfurlErrorDataNotAllowed: return "CFURLErrorDataNotAllowed"
    case .cfurlErrorRequestBodyStreamExhausted: return "CFURLErrorRequestBodyStreamExhausted"
    case .cfurlErrorFileDoesNotExist: return "CFURLErrorFileDoesNotExist"
    case .cfurlErrorFileIsDirectory: return "CFURLErrorFileIsDirectory"
    case .cfurlErrorNoPermissionsToReadFile: return "CFURLErrorNoPermissionsToReadFile"
    case .cfurlErrorDataLengthExceedsMaximum: return "CFURLErrorDataLengthExceedsMaximum"
    case .cfurlErrorSecureConnectionFailed: return "CFURLErrorSecureConnectionFailed"
    case .cfurlErrorServerCertificateHasBadDate: return "CFURLErrorServerCertificateHasBadDate"
    case .cfurlErrorServerCertificateUntrusted: return "CFURLErrorServerCertificateUntrusted"
    case .cfurlErrorServerCertificateHasUnknownRoot: return "CFURLErrorServerCertificateHasUnknownRoot"
    case .cfurlErrorServerCertificateNotYetValid: return "CFURLErrorServerCertificateNotYetValid"
    case .cfurlErrorClientCertificateRejected: return "CFURLErrorClientCertificateRejected"
    case .cfurlErrorClientCertificateRequired: return "CFURLErrorClientCertificateRequired"
    case .cfurlErrorCannotLoadFromNetwork: return "CFURLErrorCannotLoadFromNetwork"
    case .cfurlErrorCannotCreateFile: return "CFURLErrorCannotCreateFile"
    case .cfurlErrorCannotOpenFile: return "CFURLErrorCannotOpenFile"
    case .cfurlErrorCannotCloseFile: return "CFURLErrorCannotCloseFile"
    case .cfurlErrorCannotWriteToFile: return "CFURLErrorCannotWriteToFile"
    case .cfurlErrorCannotRemoveFile: return "CFURLErrorCannotRemoveFile"
    case .cfurlErrorCannotMoveFile: return "CFURLErrorCannotMoveFile"
    case .cfurlErrorDownloadDecodingFailedMidStream: return "CFURLErrorDownloadDecodingFailedMidStream"
    case .cfurlErrorDownloadDecodingFailedToComplete: return "CFURLErrorDownloadDecodingFailedToComplete"

    case .cfhttpCookieCannotParseCookieFile: return "CFHTTPCookieCannotParseCookieFile"
    case .cfNetServiceErrorUnknown: return "CFNetServiceErrorUnknown"
    case .cfNetServiceErrorCollision: return "CFNetServiceErrorCollision"
    case .cfNetServiceErrorNotFound: return "CFNetServiceErrorNotFound"
    case .cfNetServiceErrorInProgress: return "CFNetServiceErrorInProgress"
    case .cfNetServiceErrorBadArgument: return "CFNetServiceErrorBadArgument"
    case .cfNetServiceErrorCancel: return "CFNetServiceErrorCancel"
    case .cfNetServiceErrorInvalid: return "CFNetServiceErrorInvalid"
    case .cfNetServiceErrorTimeout: return "CFNetServiceErrorTimeout"
    case .cfNetServiceErrorDNSServiceFailure: return "CFNetServiceErrorDNSServiceFailure"
    default: return "Unknown"
    }
}

class ErrorPageHandler: InternalSchemeResponse, FeatureFlaggable {
    static let path = InternalURL.Path.errorpage.rawValue
    // When nativeErrorPage feature flag is true, only create
    // html page with gray background similar to homepage or privatehomepage.
    // TODO: responseForErrorWebPage() will be removed in future with rest of the old error page code.
    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        if featureFlags.isFeatureEnabled(.nativeErrorPage, checking: .buildOnly) {
            responseForNativeErrorPage(request: request)
        } else {
            responseForErrorWebPage(request: request)
        }
    }

    func responseForNativeErrorPage(request: URLRequest) -> (URLResponse, Data)? {
        guard let url = request.url else { return nil }
        let response = InternalSchemeHandler.response(forUrl: url)
        // Blank page with a color matching the background of the panels which
        // is displayed for a split-second until the panel shows.
        let html = """
            <!DOCTYPE html>
            <html>
              <body></body>
            </html>
        """
        guard let data = html.data(using: .utf8) else { return nil }
        return (response, data)
    }

    func responseForErrorWebPage(request: URLRequest) -> (URLResponse, Data)? {
        guard let requestUrl = request.url,
              let originalUrl = InternalURL(requestUrl)?.originalURLFromErrorPage
        else { return nil }

        guard let url = request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let code = components.valueForQuery("code"),
            let errCode = Int(code),
            let errDescription = components.valueForQuery("description"),
            let errURLDomain = originalUrl.host,
            var errDomain = components.valueForQuery("domain") else {
                return nil
        }

        var asset = Bundle.main.path(forResource: "NetError", ofType: "html")
        var variables = [
            "error_code": "\(errCode)",
            "error_title": errDescription,
            "short_description": errDomain,
            ]

        let tryAgain: String = .ErrorPageTryAgain
        // swiftlint:disable line_length
        var actions = "<script>function reloader() { location.replace((new URL(location.href)).searchParams.get(\"url\")); }" +
                    "</script><button onclick='reloader()'>\(tryAgain)</button>"
        // swiftlint:enable line_length

        if errDomain == kCFErrorDomainCFNetwork as String {
            if let code = CFNetworkErrors(rawValue: Int32(errCode)) {
                errDomain = cfErrorToName(code)
            }
        } else if errDomain == MozDomain {
            if errCode == MozErrorDownloadsNotEnabled {
                let downloadInSafari: String = .ErrorPageOpenInSafari

                // Overwrite the normal try-again action.
                actions = "<button onclick='webkit.messageHandlers.errorPageHelperMessageManager.postMessage({type: \"\(MessageOpenInSafari)\"})'>\(downloadInSafari)</button>"
            }
            errDomain = ""
        } else if CertErrors.contains(errCode) {
            guard let url = request.url,
                  let comp = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let certError = comp.valueForQuery("certerror")
            else {
                assertionFailure("Error unwrapping the cert error")
                return nil
            }

            asset = Bundle.main.path(forResource: "CertError", ofType: "html")
            actions = "<button onclick='history.back()'>\(String.ErrorPagesGoBackButton)</button>"
            variables["error_title"] = .ErrorPagesCertWarningTitle
            variables["cert_error"] = certError
            variables["long_description"] = String(format: .ErrorPagesCertWarningDescription, "<b>\(errURLDomain)</b>")
            variables["advanced_button"] = .ErrorPagesAdvancedButton
            variables["warning_description"] = .ErrorPagesCertWarningDescription
            variables["warning_advanced1"] = .ErrorPagesAdvancedWarning1
            variables["warning_advanced2"] = .ErrorPagesAdvancedWarning2
            variables["warning_actions"] =
                "<p><a id='\(UserScriptManager.appIdToken)__firefox__visitOnce' href='#'>\(String.ErrorPagesVisitOnceButton)</button></p>"
        }

        variables["actions"] = actions

        let response = InternalSchemeHandler.response(forUrl: originalUrl)
        guard let file = asset, var html = try? String(contentsOfFile: file) else {
            assertionFailure("Error unwrapping html from file contents")
            return nil
        }

        variables.forEach { (arg, value) in
            html = html.replacingOccurrences(of: "%\(arg)%", with: value)
        }

        guard let data = html.data(using: .utf8) else { return nil }
        return (response, data)
    }
}

class ErrorPageHelper {
    fileprivate weak var certStore: CertStore?
    private var logger: Logger

    init(certStore: CertStore?,
         logger: Logger = DefaultLogger.shared) {
        self.certStore = certStore
        self.logger = logger
    }

    func loadPage(_ error: NSError, forUrl url: URL, inWebView webView: WKWebView) {
        guard var components = URLComponents(string: "\(InternalURL.baseUrl)/\(ErrorPageHandler.path)" ) else { return }

        // Page has failed to load again, just return and keep showing the existing error page.
        if let webViewUrl = webView.url,
           let internalUrl = InternalURL(webViewUrl),
           internalUrl.originalURLFromErrorPage == url {
            return
        }

        var queryItems = [
            URLQueryItem(name: InternalURL.Param.url.rawValue, value: url.absoluteString),
            URLQueryItem(name: "code", value: String(error.code)),
            URLQueryItem(name: "domain", value: error.domain),
            URLQueryItem(name: "description", value: error.localizedDescription),
            // 'timestamp' is used for the js reload logic
            URLQueryItem(name: "timestamp", value: "\(Int(Date().timeIntervalSince1970 * 1000))")
        ]

        // If this is an invalid certificate, show a certificate error allowing the
        // user to go back or continue. The certificate itself is encoded and added as
        // a query parameter to the error page URL; we then read the certificate from
        // the URL if the user wants to continue.
        if CertErrors.contains(error.code),
            let certChain = error.userInfo["NSErrorPeerCertificateChainKey"] as? [SecCertificate],
            let cert = certChain.first,
            let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
            let certErrorCode = underlyingError.userInfo["_kCFStreamErrorCodeKey"] as? Int {
            let encodedCert = (SecCertificateCopyData(cert) as Data).base64EncodedString
            queryItems.append(URLQueryItem(name: "badcert", value: encodedCert))

            let certError = CertErrorCodes[certErrorCode] ?? ""
            queryItems.append(URLQueryItem(name: "certerror", value: String(certError)))
        }

        components.queryItems = queryItems
        if let urlWithQuery = components.url {
            logger.log("An error page will show.",
                       level: .info,
                       category: .webview,
                       extra: ["Error code": "\(error.code)"])

            TelemetryWrapper.shared.recordEvent(
                category: .information,
                method: .error,
                object: .webview,
                value: .webviewShowErrorPage,
                extras: [TelemetryWrapper.EventExtraKey.errorCode.rawValue: "\(error.code)"]
            )

            // A new page needs to be added to the history stack (i.e. the simple case
            // of trying to navigate to an url for the first time and it fails, without
            // pushing a page on the history stack, the webview will just show the
            // current page).
            webView.load(PrivilegedRequest(url: urlWithQuery) as URLRequest)
        }
    }
}

extension ErrorPageHelper: TabContentScript {
    static func name() -> String {
        return "ErrorPageHelper"
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["errorPageHelperMessageManager"]
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let errorURL = message.frameInfo.request.url,
            let internalUrl = InternalURL(errorURL),
            internalUrl.isErrorPage,
            let originalURL = internalUrl.originalURLFromErrorPage,
            let res = message.body as? [String: String],
            let type = res["type"] else { return }

        switch type {
        case MessageOpenInSafari:
            UIApplication.shared.open(originalURL, options: [:])
        case MessageCertVisitOnce:
            if let cert = certFromErrorURL(errorURL),
                let host = originalURL.host {
                let origin = "\(host):\(originalURL.port ?? 443)"
                certStore?.addCertificate(cert, forOrigin: origin)
                message.webView?.replaceLocation(with: originalURL)
                // webview.reload will not change the error URL back to the original URL
            }
        default:
            assertionFailure("Unknown error message")
        }
    }
}

private extension URLComponents {
    // Return the first query parameter that matches
    func valueForQuery(_ param: String) -> String? {
        return self.queryItems?.first { $0.name == param }?.value
    }
}
