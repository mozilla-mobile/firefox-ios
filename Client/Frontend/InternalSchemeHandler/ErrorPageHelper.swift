/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers
import Shared
import Storage

fileprivate let MozDomain = "mozilla"
fileprivate let MozErrorDownloadsNotEnabled = 100
fileprivate let MessageOpenInSafari = "openInSafari"
fileprivate let MessageCertVisitOnce = "certVisitOnce"

// Regardless of cause, NSURLErrorServerCertificateUntrusted is currently returned in all cases.
// Check the other cases in case this gets fixed in the future.
fileprivate let CertErrors = [
    NSURLErrorServerCertificateUntrusted,
    NSURLErrorServerCertificateHasBadDate,
    NSURLErrorServerCertificateHasUnknownRoot,
    NSURLErrorServerCertificateNotYetValid
]

// Error codes copied from Gecko. The ints corresponding to these codes were determined
// by inspecting the NSError in each of these cases.
fileprivate let CertErrorCodes = [
    -9813: "SEC_ERROR_UNKNOWN_ISSUER",
    -9814: "SEC_ERROR_EXPIRED_CERTIFICATE",
    -9843: "SSL_ERROR_BAD_CERT_DOMAIN",
]

fileprivate func certFromErrorURL(_ url: URL) -> SecCertificate? {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    if let encodedCert = components?.queryItems?.filter({ $0.name == "badcert" }).first?.value,
        let certData = Data(base64Encoded: encodedCert, options: []) {
        return SecCertificateCreateWithData(nil, certData as CFData)
    }

    return nil
}

fileprivate func cfErrorToName(_ err: CFNetworkErrors) -> String {
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
    case .cfStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod: return "CFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod"

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

class ErrorPageHandler: InternalSchemeResponse {
    static let path = URL.errorPagePath

    func response(forRequest request: URLRequest) -> (URLResponse, Data)? {
        guard
            // request.isPrivileged, -> TODO: lock this down, session restore can redirect to an error page
            let originalUrl = request.url?.originalURLFromErrorPage else {
            return nil
        }

        guard let index = ErrorPageHelper.redirecting.index(of: originalUrl) else {
            return generateResponseThatRedirects(toUrl: originalUrl)
        }

        ErrorPageHelper.redirecting.remove(at: index)

        guard let url = request.url,
            let c = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let code = c.valueForQuery("code"),
            let errCode = Int(code),
            let errDescription = c.valueForQuery("description"),
            let errURLDomain = originalUrl.host,
            var errDomain = c.valueForQuery("domain") else {
                return nil
        }

        var asset = Bundle.main.path(forResource: "NetError", ofType: "html")
        var css = Bundle.main.path(forResource: "NetError", ofType: "css")
        var variables = [
            "error_code": "\(errCode)",
            "error_title": errDescription,
            "short_description": errDomain,
            ]

        let tryAgain = NSLocalizedString("Try again", tableName: "ErrorPages", comment: "Shown in error pages on a button that will try to load the page again")
        var actions = "<button onclick='webkit.messageHandlers.localRequestHelper.postMessage({ type: \"reload\" })'>\(tryAgain)</button>"

        if errDomain == kCFErrorDomainCFNetwork as String {
            if let code = CFNetworkErrors(rawValue: Int32(errCode)) {
                errDomain = cfErrorToName(code)
            }
        } else if errDomain == MozDomain {
            if errCode == MozErrorDownloadsNotEnabled {
                let downloadInSafari = NSLocalizedString("Open in Safari", tableName: "ErrorPages", comment: "Shown in error pages for files that can't be shown and need to be downloaded.")

                // Overwrite the normal try-again action.
                actions = "<button onclick='webkit.messageHandlers.errorPageHelperMessageManager.postMessage({type: \"\(MessageOpenInSafari)\"})'>\(downloadInSafari)</button>"
            }
            errDomain = ""
        } else if CertErrors.contains(errCode) {
            guard let url = request.url, let comp = URLComponents(url: url, resolvingAgainstBaseURL: false), let certError = comp.valueForQuery("certerror") else {
                assert(false)
                return nil
            }

            asset = Bundle.main.path(forResource: "CertError", ofType: "html")
            css = Bundle.main.path(forResource: "CertError", ofType: "css")
            actions = "<button onclick='history.back()'>\(Strings.ErrorPagesGoBackButton)</button>"
            variables["error_title"] = Strings.ErrorPagesCertWarningTitle
            variables["cert_error"] = certError
            variables["long_description"] = String(format: Strings.ErrorPagesCertWarningDescription, "<b>\(errURLDomain)</b>")
            variables["advanced_button"] = Strings.ErrorPagesAdvancedButton
            variables["warning_description"] = Strings.ErrorPagesCertWarningDescription
            variables["warning_advanced1"] = Strings.ErrorPagesAdvancedWarning1
            variables["warning_advanced2"] = Strings.ErrorPagesAdvancedWarning2
            variables["warning_actions"] =
            "<p><a href='javascript:webkit.messageHandlers.errorPageHelperMessageManager.postMessage({type: \"\(MessageCertVisitOnce)\"})'>\(Strings.ErrorPagesVisitOnceButton)</button></p>"
        }

        variables["actions"] = actions

        let response = InternalSchemeHandler.response(forUrl: url)
        guard let file = asset, var html = try? String(contentsOfFile: file) else {
            assert(false)
            return nil
        }

        variables.forEach { (arg, value) in
            html = html.replacingOccurrences(of: "%\(arg)%", with: value)
        }

        if let css = css, let cssString = try? String(contentsOfFile: css).replacingOccurrences(of: "\n", with: " ") {
            let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
            html = html.replacingOccurrences(of: "%insert_css%", with: jsString)
        }

        guard let data = html.data(using: .utf8) else { return nil }
        return (response, data)
    }
}

class ErrorPageHelper {

    // When an error page is intentionally loaded, its added to this set. If its in the set, we show
    // it as an error page. If its not, we assume someone is trying to reload this page somehow, and
    // we'll instead redirect back to the original URL.
    fileprivate static var redirecting = [URL]()

    fileprivate weak var certStore: CertStore?

    init(certStore: CertStore?) {
        self.certStore = certStore
    }

    func loadPage(_ error: NSError, forUrl url: URL, inWebView webView: WKWebView) {
        // Don't show error pages for error pages.
        if url.isInternalErrorPage {
            if let previousURL = url.originalURLFromErrorPage {
                // If the previous URL is a local file URL that we know exists,
                // just load it in the web view. This works around an issue
                // where we are unable to redirect to a `file://` URL during
                // session restore.
                if previousURL.isFileURL, FileManager.default.fileExists(atPath: previousURL.path) {
                    webView.loadFileURL(previousURL, allowingReadAccessTo: previousURL)
                    return
                }

                if let index = ErrorPageHelper.redirecting.index(of: previousURL) {
                    ErrorPageHelper.redirecting.remove(at: index)
                }
            }

            return
        }

        // Add this page to the redirecting list. This will cause the server to actually show the error page
        // (instead of redirecting to the original URL).
        ErrorPageHelper.redirecting.append(url)

        guard var components = URLComponents(string: "\(InternalScheme.url)/\(ErrorPageHandler.path)") else {
            assertionFailure()
            return
        }

        var queryItems = [
            URLQueryItem(name: URL.errorPageUrlParam, value: url.absoluteString),
            URLQueryItem(name: "code", value: String(error.code)),
            URLQueryItem(name: "domain", value: error.domain),
            URLQueryItem(name: "description", value: error.localizedDescription)
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
            webView.load(PrivilegedRequest(url: urlWithQuery) as URLRequest)
        }
    }
}

extension ErrorPageHelper: TabContentScript {
    static func name() -> String {
        return "ErrorPageHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "errorPageHelperMessageManager"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let errorURL = message.frameInfo.request.url, errorURL.isInternalErrorPage,
            let res = message.body as? [String: String],
            let originalURL = errorURL.originalURLFromErrorPage,
            let type = res["type"] {

            switch type {
            case MessageOpenInSafari:
                UIApplication.shared.open(originalURL, options: [:])
            case MessageCertVisitOnce:
                if let cert = certFromErrorURL(errorURL),
                    let host = originalURL.host {
                    let origin = "\(host):\(originalURL.port ?? 443)"
                    certStore?.addCertificate(cert, forOrigin: origin)
                    _ = message.webView?.reload()
                }
            default:
                assertionFailure("Unknown error message")
            }
        }
    }
}



