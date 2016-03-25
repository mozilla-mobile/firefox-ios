/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import GCDWebServers
import Shared

class ErrorPageHelper {
    static let MozDomain = "mozilla"
    static let MozErrorDownloadsNotEnabled = 100

    // When an error page is intentionally loaded, its added to this set. If its in the set, we show
    // it as an error page. If its not, we assume someone is trying to reload this page somehow, and
    // we'll instead redirect back to the original URL.
    private static var redirecting = [NSURL]()

    class func cfErrorToName(err: CFNetworkErrors) -> String {
        switch err {
        case .CFHostErrorHostNotFound: return "CFHostErrorHostNotFound"
        case .CFHostErrorUnknown: return "CFHostErrorUnknown"
        case .CFSOCKSErrorUnknownClientVersion: return "CFSOCKSErrorUnknownClientVersion"
        case .CFSOCKSErrorUnsupportedServerVersion: return "CFSOCKSErrorUnsupportedServerVersion"
        case .CFSOCKS4ErrorRequestFailed: return "CFSOCKS4ErrorRequestFailed"
        case .CFSOCKS4ErrorIdentdFailed: return "CFSOCKS4ErrorIdentdFailed"
        case .CFSOCKS4ErrorIdConflict: return "CFSOCKS4ErrorIdConflict"
        case .CFSOCKS4ErrorUnknownStatusCode: return "CFSOCKS4ErrorUnknownStatusCode"
        case .CFSOCKS5ErrorBadState: return "CFSOCKS5ErrorBadState"
        case .CFSOCKS5ErrorBadResponseAddr: return "CFSOCKS5ErrorBadResponseAddr"
        case .CFSOCKS5ErrorBadCredentials: return "CFSOCKS5ErrorBadCredentials"
        case .CFSOCKS5ErrorUnsupportedNegotiationMethod: return "CFSOCKS5ErrorUnsupportedNegotiationMethod"
        case .CFSOCKS5ErrorNoAcceptableMethod: return "CFSOCKS5ErrorNoAcceptableMethod"
        case .CFFTPErrorUnexpectedStatusCode: return "CFFTPErrorUnexpectedStatusCode"
        case .CFErrorHTTPAuthenticationTypeUnsupported: return "CFErrorHTTPAuthenticationTypeUnsupported"
        case .CFErrorHTTPBadCredentials: return "CFErrorHTTPBadCredentials"
        case .CFErrorHTTPConnectionLost: return "CFErrorHTTPConnectionLost"
        case .CFErrorHTTPParseFailure: return "CFErrorHTTPParseFailure"
        case .CFErrorHTTPRedirectionLoopDetected: return "CFErrorHTTPRedirectionLoopDetected"
        case .CFErrorHTTPBadURL: return "CFErrorHTTPBadURL"
        case .CFErrorHTTPProxyConnectionFailure: return "CFErrorHTTPProxyConnectionFailure"
        case .CFErrorHTTPBadProxyCredentials: return "CFErrorHTTPBadProxyCredentials"
        case .CFErrorPACFileError: return "CFErrorPACFileError"
        case .CFErrorPACFileAuth: return "CFErrorPACFileAuth"
        case .CFErrorHTTPSProxyConnectionFailure: return "CFErrorHTTPSProxyConnectionFailure"
        case .CFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod: return "CFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod"

        case .CFURLErrorBackgroundSessionInUseByAnotherProcess: return "CFURLErrorBackgroundSessionInUseByAnotherProcess"
        case .CFURLErrorBackgroundSessionWasDisconnected: return "CFURLErrorBackgroundSessionWasDisconnected"
        case .CFURLErrorUnknown: return "CFURLErrorUnknown"
        case .CFURLErrorCancelled: return "CFURLErrorCancelled"
        case .CFURLErrorBadURL: return "CFURLErrorBadURL"
        case .CFURLErrorTimedOut: return "CFURLErrorTimedOut"
        case .CFURLErrorUnsupportedURL: return "CFURLErrorUnsupportedURL"
        case .CFURLErrorCannotFindHost: return "CFURLErrorCannotFindHost"
        case .CFURLErrorCannotConnectToHost: return "CFURLErrorCannotConnectToHost"
        case .CFURLErrorNetworkConnectionLost: return "CFURLErrorNetworkConnectionLost"
        case .CFURLErrorDNSLookupFailed: return "CFURLErrorDNSLookupFailed"
        case .CFURLErrorHTTPTooManyRedirects: return "CFURLErrorHTTPTooManyRedirects"
        case .CFURLErrorResourceUnavailable: return "CFURLErrorResourceUnavailable"
        case .CFURLErrorNotConnectedToInternet: return "CFURLErrorNotConnectedToInternet"
        case .CFURLErrorRedirectToNonExistentLocation: return "CFURLErrorRedirectToNonExistentLocation"
        case .CFURLErrorBadServerResponse: return "CFURLErrorBadServerResponse"
        case .CFURLErrorUserCancelledAuthentication: return "CFURLErrorUserCancelledAuthentication"
        case .CFURLErrorUserAuthenticationRequired: return "CFURLErrorUserAuthenticationRequired"
        case .CFURLErrorZeroByteResource: return "CFURLErrorZeroByteResource"
        case .CFURLErrorCannotDecodeRawData: return "CFURLErrorCannotDecodeRawData"
        case .CFURLErrorCannotDecodeContentData: return "CFURLErrorCannotDecodeContentData"
        case .CFURLErrorCannotParseResponse: return "CFURLErrorCannotParseResponse"
        case .CFURLErrorInternationalRoamingOff: return "CFURLErrorInternationalRoamingOff"
        case .CFURLErrorCallIsActive: return "CFURLErrorCallIsActive"
        case .CFURLErrorDataNotAllowed: return "CFURLErrorDataNotAllowed"
        case .CFURLErrorRequestBodyStreamExhausted: return "CFURLErrorRequestBodyStreamExhausted"
        case .CFURLErrorFileDoesNotExist: return "CFURLErrorFileDoesNotExist"
        case .CFURLErrorFileIsDirectory: return "CFURLErrorFileIsDirectory"
        case .CFURLErrorNoPermissionsToReadFile: return "CFURLErrorNoPermissionsToReadFile"
        case .CFURLErrorDataLengthExceedsMaximum: return "CFURLErrorDataLengthExceedsMaximum"
        case .CFURLErrorSecureConnectionFailed: return "CFURLErrorSecureConnectionFailed"
        case .CFURLErrorServerCertificateHasBadDate: return "CFURLErrorServerCertificateHasBadDate"
        case .CFURLErrorServerCertificateUntrusted: return "CFURLErrorServerCertificateUntrusted"
        case .CFURLErrorServerCertificateHasUnknownRoot: return "CFURLErrorServerCertificateHasUnknownRoot"
        case .CFURLErrorServerCertificateNotYetValid: return "CFURLErrorServerCertificateNotYetValid"
        case .CFURLErrorClientCertificateRejected: return "CFURLErrorClientCertificateRejected"
        case .CFURLErrorClientCertificateRequired: return "CFURLErrorClientCertificateRequired"
        case .CFURLErrorCannotLoadFromNetwork: return "CFURLErrorCannotLoadFromNetwork"
        case .CFURLErrorCannotCreateFile: return "CFURLErrorCannotCreateFile"
        case .CFURLErrorCannotOpenFile: return "CFURLErrorCannotOpenFile"
        case .CFURLErrorCannotCloseFile: return "CFURLErrorCannotCloseFile"
        case .CFURLErrorCannotWriteToFile: return "CFURLErrorCannotWriteToFile"
        case .CFURLErrorCannotRemoveFile: return "CFURLErrorCannotRemoveFile"
        case .CFURLErrorCannotMoveFile: return "CFURLErrorCannotMoveFile"
        case .CFURLErrorDownloadDecodingFailedMidStream: return "CFURLErrorDownloadDecodingFailedMidStream"
        case .CFURLErrorDownloadDecodingFailedToComplete: return "CFURLErrorDownloadDecodingFailedToComplete"

        case .CFHTTPCookieCannotParseCookieFile: return "CFHTTPCookieCannotParseCookieFile"
        case .CFNetServiceErrorUnknown: return "CFNetServiceErrorUnknown"
        case .CFNetServiceErrorCollision: return "CFNetServiceErrorCollision"
        case .CFNetServiceErrorNotFound: return "CFNetServiceErrorNotFound"
        case .CFNetServiceErrorInProgress: return "CFNetServiceErrorInProgress"
        case .CFNetServiceErrorBadArgument: return "CFNetServiceErrorBadArgument"
        case .CFNetServiceErrorCancel: return "CFNetServiceErrorCancel"
        case .CFNetServiceErrorInvalid: return "CFNetServiceErrorInvalid"
        case .CFNetServiceErrorTimeout: return "CFNetServiceErrorTimeout"
        case .CFNetServiceErrorDNSServiceFailure: return "CFNetServiceErrorDNSServiceFailure"
        default: return "Unknown"
        }
    }

    class func register(server: WebServer) {

        server.registerHandlerForMethod("GET", module: "errors", resource: "error.html", handler: { (request) -> GCDWebServerResponse! in
            guard let url = ErrorPageHelper.originalURLFromQuery(request.URL) else {
                return GCDWebServerResponse(statusCode: 404)
            }

            if let index = self.redirecting.indexOf(url) {
                self.redirecting.removeAtIndex(index)

                let errCode = Int((request.query["code"] as! String))
                let errDescription = request.query["description"] as! String
                var errDomain = request.query["domain"] as! String

                // If we don't have any other actions, we always add a try again button
                let tryAgain = NSLocalizedString("Try again", tableName: "ErrorPages", comment: "Shown in error pages on a button that will try to load the page again")
                var actions = "<button onclick='window.location.reload()'>\(tryAgain)</button>"

                if errDomain == kCFErrorDomainCFNetwork as String {
                    if let code = CFNetworkErrors(rawValue: Int32(errCode!)) {
                        errDomain = self.cfErrorToName(code)
                    }
                } else if errDomain == ErrorPageHelper.MozDomain {
                    if errCode == ErrorPageHelper.MozErrorDownloadsNotEnabled {
                        // Overwrite the normal try-again action.
                        let downloadInSafari = NSLocalizedString("Open in Safari", tableName: "ErrorPages", comment: "Shown in error pages for files that can't be shown and need to be downloaded.")
                        actions = "<button onclick='webkit.messageHandlers.errorPageHelperMessageManager.postMessage({type: \"openInSafari\"})'>\(downloadInSafari)</a>"
                    }
                    errDomain = ""
                }

                let asset = NSBundle.mainBundle().pathForResource("NetError", ofType: "html")
                let response = GCDWebServerDataResponse(HTMLTemplate: asset, variables: [
                    "error_code": "\(errCode ?? -1)",
                    "error_title": errDescription ?? "",
                    "long_description": nil ?? "",
                    "short_description": errDomain,
                    "actions": actions
                ])
                response.setValue("no cache", forAdditionalHeader: "Pragma")
                response.setValue("no-cache,must-revalidate", forAdditionalHeader: "Cache-Control")
                response.setValue(NSDate().description, forAdditionalHeader: "Expires")
                return response
            } else {
                return GCDWebServerDataResponse(redirect: url, permanent: false)
            }
        })

        server.registerHandlerForMethod("GET", module: "errors", resource: "NetError.css", handler: { (request) -> GCDWebServerResponse! in
            let path = NSBundle(forClass: self).pathForResource("NetError", ofType: "css")!
            return GCDWebServerDataResponse(data: NSData(contentsOfFile: path), contentType: "text/css")
        })
    }

    func showPage(error: NSError, forUrl url: NSURL, inWebView webView: WKWebView) {
        // Don't show error pages for error pages.
        if ErrorPageHelper.isErrorPageURL(url) {
            if let previousURL = ErrorPageHelper.originalURLFromQuery(url),
               let index = ErrorPageHelper.redirecting.indexOf(previousURL) {
                ErrorPageHelper.redirecting.removeAtIndex(index)
            }
            return
        }

        // Add this page to the redirecting list. This will cause the server to actually show the error page
        // (instead of redirecting to the original URL).
        ErrorPageHelper.redirecting.append(url)

        let components = NSURLComponents(string: WebServer.sharedInstance.base + "/errors/error.html")!
        components.queryItems = [
            NSURLQueryItem(name: "url", value: url.absoluteString),
            NSURLQueryItem(name: "code", value: String(error.code)),
            NSURLQueryItem(name: "domain", value: error.domain),
            NSURLQueryItem(name: "description", value: error.localizedDescription)
        ]

        webView.loadRequest(NSURLRequest(URL: components.URL!))
    }

    class func isErrorPageURL(url: NSURL) -> Bool {
        if let host = url.host, path = url.path {
            return url.scheme == "http" && host == "localhost" && path == "/errors/error.html"
        }
        return false
    }

    class func originalURLFromQuery(url: NSURL) -> NSURL? {
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        if let queryURL = components?.queryItems?.filter({ $0.name == "url" }).first?.value {
            return NSURL(string: queryURL)
        }

        return nil
    }
}

extension ErrorPageHelper: BrowserHelper {
    static func name() -> String {
        return "ErrorPageHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "errorPageHelperMessageManager"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let url = message.frameInfo.request.URL {
            if message.frameInfo.mainFrame && ErrorPageHelper.isErrorPageURL(url) {
                if let res = message.body as? [String: String],
                   let url = ErrorPageHelper.originalURLFromQuery(url) {
                    let type = res["type"]
                    if type == "openInSafari" {
                        UIApplication.sharedApplication().openURL(url)
                    }
                }
            }
        }
    }
}
