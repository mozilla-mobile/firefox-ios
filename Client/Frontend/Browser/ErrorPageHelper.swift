/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers
import Shared
import Storage

class ErrorPageHelper {
    static let MozDomain = "mozilla"
    static let MozErrorDownloadsNotEnabled = 100

    private static let MessageOpenInSafari = "openInSafari"
    private static let MessageCertVisitOnce = "certVisitOnce"

    // When an error page is intentionally loaded, its added to this set. If its in the set, we show
    // it as an error page. If its not, we assume someone is trying to reload this page somehow, and
    // we'll instead redirect back to the original URL.
    private static var redirecting = [URL]()

    private static weak var certStore: CertStore?

    // Regardless of cause, NSURLErrorServerCertificateUntrusted is currently returned in all cases.
    // Check the other cases in case this gets fixed in the future.
    private static let CertErrors = [
        NSURLErrorServerCertificateUntrusted,
        NSURLErrorServerCertificateHasBadDate,
        NSURLErrorServerCertificateHasUnknownRoot,
        NSURLErrorServerCertificateNotYetValid
    ]

    // Error codes copied from Gecko. The ints corresponding to these codes were determined
    // by inspecting the NSError in each of these cases.
    private static let CertErrorCodes = [
        -9813: "SEC_ERROR_UNKNOWN_ISSUER",
        -9814: "SEC_ERROR_EXPIRED_CERTIFICATE",
        -9843: "SSL_ERROR_BAD_CERT_DOMAIN",
    ]

    class func cfErrorToName(_ err: CFNetworkErrors) -> String {
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

    class func register(_ server: WebServer, certStore: CertStore?) {
        self.certStore = certStore

        server.registerHandler(forMethod: "GET", module: "errors", resource: "error.html", handler: { (request) -> GCDWebServerResponse! in
            guard let url = ErrorPageHelper.originalURLFromQuery(request.url) else {
                return GCDWebServerResponse(statusCode: 404)
            }

            guard let index = self.redirecting.index(of: url) else {
                return GCDWebServerDataResponse(redirect: url, permanent: false)
            }

            self.redirecting.remove(at: index)

            guard let code = request.query["code"] as? String,
                  let errCode = Int(code),
                  let errDescription = request.query["description"] as? String,
                  let errURLString = request.query["url"] as? String,
                  let errURLDomain = URL(string: errURLString)?.host,
                  var errDomain = request.query["domain"] as? String else {
                return GCDWebServerResponse(statusCode: 404)
            }

            var asset = Bundle.main.pathForResource("NetError", ofType: "html")
            var variables = [
                "error_code": "\(errCode ?? -1)",
                "error_title": errDescription ?? "",
                "short_description": errDomain,
            ]

            let tryAgain = NSLocalizedString("Try again", tableName: "ErrorPages", comment: "Shown in error pages on a button that will try to load the page again")
            var actions = "<button onclick='webkit.messageHandlers.localRequestHelper.postMessage({ type: \"reload\" })'>\(tryAgain)</button>"

            if errDomain == kCFErrorDomainCFNetwork as String {
                if let code = CFNetworkErrors(rawValue: Int32(errCode)) {
                    errDomain = self.cfErrorToName(code)
                }
            } else if errDomain == ErrorPageHelper.MozDomain {
                if errCode == ErrorPageHelper.MozErrorDownloadsNotEnabled {
                    let downloadInSafari = NSLocalizedString("Open in Safari", tableName: "ErrorPages", comment: "Shown in error pages for files that can't be shown and need to be downloaded.")

                    // Overwrite the normal try-again action.
                    actions = "<button onclick='webkit.messageHandlers.errorPageHelperMessageManager.postMessage({type: \"\(MessageOpenInSafari)\"})'>\(downloadInSafari)</button>"
                }
                errDomain = ""
            } else if CertErrors.contains(errCode) {
                guard let certError = request.query["certerror"] as? String else {
                    return GCDWebServerResponse(statusCode: 404)
                }

                asset = Bundle.main.pathForResource("CertError", ofType: "html")
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

            let response = GCDWebServerDataResponse(htmlTemplate: asset, variables: variables)
            response.setValue("no cache", forAdditionalHeader: "Pragma")
            response.setValue("no-cache,must-revalidate", forAdditionalHeader: "Cache-Control")
            response.setValue(Date().description, forAdditionalHeader: "Expires")
            return response
        })

        server.registerHandler(forMethod: "GET", module: "errors", resource: "NetError.css", handler: { (request) -> GCDWebServerResponse! in
            let path = Bundle(for: self).pathForResource("NetError", ofType: "css")!
            return GCDWebServerDataResponse(data: try? Data(contentsOf: URL(fileURLWithPath: path)), contentType: "text/css")
        })

        server.registerHandler(forMethod: "GET", module: "errors", resource: "CertError.css", handler: { (request) -> GCDWebServerResponse! in
            let path = Bundle(for: self).pathForResource("CertError", ofType: "css")!
            return GCDWebServerDataResponse(data: try? Data(contentsOf: URL(fileURLWithPath: path)), contentType: "text/css")
        })
    }

    func showPage(_ error: NSError, forUrl url: URL, inWebView webView: WKWebView) {
        // Don't show error pages for error pages.
        if ErrorPageHelper.isErrorPageURL(url) {
            if let previousURL = ErrorPageHelper.originalURLFromQuery(url),
               let index = ErrorPageHelper.redirecting.index(of: previousURL) {
                ErrorPageHelper.redirecting.remove(at: index)
            }
            return
        }

        // Add this page to the redirecting list. This will cause the server to actually show the error page
        // (instead of redirecting to the original URL).
        ErrorPageHelper.redirecting.append(url)

        var components = URLComponents(string: WebServer.sharedInstance.base + "/errors/error.html")!
        var queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "code", value: String(error.code)),
            URLQueryItem(name: "domain", value: error.domain),
            URLQueryItem(name: "description", value: error.localizedDescription)
        ]

        // If this is an invalid certificate, show a certificate error allowing the
        // user to go back or continue. The certificate itself is encoded and added as
        // a query parameter to the error page URL; we then read the certificate from
        // the URL if the user wants to continue.
        if ErrorPageHelper.CertErrors.contains(error.code),
           let certChain = error.userInfo["NSErrorPeerCertificateChainKey"] as? [SecCertificate],
           let cert = certChain.first,
           let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
           let certErrorCode = underlyingError.userInfo["_kCFStreamErrorCodeKey"] as? Int {
            let encodedCert = (SecCertificateCopyData(cert) as Data).base64EncodedString
            queryItems.append(URLQueryItem(name: "badcert", value: encodedCert))

            let certError = ErrorPageHelper.CertErrorCodes[certErrorCode] ?? ""
            queryItems.append(URLQueryItem(name: "certerror", value: String(certError)))
        }

        components.queryItems = queryItems
        webView.load(PrivilegedRequest(coder: components.url!))
    }

    class func isErrorPageURL(_ url: URL) -> Bool {
        if let host = url.host, path = url.path {
            return url.scheme == "http" && host == "localhost" && path == "/errors/error.html"
        }
        return false
    }

    class func originalURLFromQuery(_ url: URL) -> URL? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queryURL = components?.queryItems?.find({ $0.name == "url" })?.value {
            return URL(string: queryURL)
        }

        return nil
    }
}

extension ErrorPageHelper: TabHelper {
    static func name() -> String {
        return "ErrorPageHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "errorPageHelperMessageManager"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let errorURL = message.frameInfo.request.url where ErrorPageHelper.isErrorPageURL(errorURL),
           let res = message.body as? [String: String],
           let originalURL = ErrorPageHelper.originalURLFromQuery(errorURL),
           let type = res["type"] {

            switch type {
            case ErrorPageHelper.MessageOpenInSafari:
                UIApplication.shared().openURL(originalURL)
            case ErrorPageHelper.MessageCertVisitOnce:
                if let cert = certFromErrorURL(errorURL),
                   let host = originalURL.host {
                    let origin = "\(host):\((originalURL as NSURL).port ?? 443)"
                    ErrorPageHelper.certStore?.addCertificate(cert, forOrigin: origin)
                    message.webView?.reload()
                }
            default:
                assertionFailure("Unknown error message")
            }
        }
    }

    private func certFromErrorURL(_ url: URL) -> SecCertificate? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let encodedCert = components?.queryItems?.filter({ $0.name == "badcert" }).first?.value,
               certData = Data(base64Encoded: encodedCert, options: []) {
            return SecCertificateCreateWithData(nil, certData)
        }

        return nil
    }
}
