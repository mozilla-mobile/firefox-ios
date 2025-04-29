// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import GCDWebServers

protocol WKReaderModeHandlersProtocol {
    func register(_ webServer: WKEngineWebServerProtocol,
                  readerModeConfiguration: ReaderModeConfiguration)
}

public struct ReaderModeConfiguration {
    var loadingText: String
    var loadingFailedText: String
    var loadOriginalText: String
    var readerModeErrorText: String
    var cachedReaderModeStyle: [String: Any]?

    public init(
        loadingText: String,
        loadingFailedText: String,
        loadOriginalText: String,
        readerModeErrorText: String,
        cachedReaderModeStyle: [String: Any]? = nil
    ) {
        self.loadingText = loadingText
        self.loadingFailedText = loadingFailedText
        self.loadOriginalText = loadOriginalText
        self.readerModeErrorText = readerModeErrorText
        self.cachedReaderModeStyle = cachedReaderModeStyle
    }
}

// TODO: FXIOS-11373 - finish handling reader mode in WebEngine - this class is to be tested
class WKReaderModeHandlers: WKReaderModeHandlersProtocol, Notifiable {
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var readerModeCache: ReaderModeCache = DiskReaderModeCache()
    private let mainQueue: DispatchQueueInterface

    init(mainQueue: DispatchQueueInterface = DispatchQueue.main) {
        self.mainQueue = mainQueue

        setupNotifications(forObserver: self, observing: [.ReaderModeSessionChanged])
    }

    func register(_ webServer: WKEngineWebServerProtocol, readerModeConfiguration: ReaderModeConfiguration) {
        mainQueue.ensureMainThread { [weak self] in
            self?.register(webServer: webServer, readerModeConfiguration: readerModeConfiguration)
        }
    }

    private func register(webServer: WKEngineWebServerProtocol, readerModeConfiguration: ReaderModeConfiguration) {
        // Register our fonts and css, which we want to expose to web content that we present in the WebView
        webServer.registerMainBundleResourcesOfType("otf", module: "reader-mode/fonts")
        webServer.registerMainBundleResource("Reader.css", module: "reader-mode/styles")

        // Initialize ReaderModeStyle here to ensure it is initialized on the main thread.
        let readerModeStyle = ReaderModeStyle.defaultStyle()

        // Register a handler that simply lets us know if a document is in the cache or not. This is called from the
        // reader view interstitial page to find out when it can stop showing the 'Loading...' page and instead load
        // the readerized content.
        webServer.registerHandlerForMethod(
            "GET",
            module: "reader-mode",
            resource: "page-exists"
        ) { (request: GCDWebServerRequest?) -> GCDWebServerResponse? in
            self.handleOnPageExist(request: request)
        }

        // Register the handler that accepts /reader-mode/page?url=http://www.example.com requests.
        webServer.registerHandlerForMethod(
            "GET",
            module: "reader-mode",
            resource: "page"
        ) { (request: GCDWebServerRequest?) -> GCDWebServerResponse? in
            self.handleReaderModePage(request: request,
                                      readerModeConfiguration: readerModeConfiguration,
                                      readerModeStyle: readerModeStyle)
        }
    }

    private func handleOnPageExist(request: GCDWebServerRequest?) -> GCDWebServerResponse? {
        guard let stringURL = request?.query?["url"],
              let url = URL(string: stringURL) else {
            return GCDWebServerResponse(statusCode: 500)
        }

        let status = readerModeCache.contains(url) ? 200 : 404
        return GCDWebServerResponse(statusCode: status)
    }

    private func handleReaderModePage(request: GCDWebServerRequest?,
                                      readerModeConfiguration: ReaderModeConfiguration,
                                      readerModeStyle: ReaderModeStyle) -> GCDWebServerResponse? {
        guard let url = request?.query?["url"] else {
            let errorString: String = readerModeConfiguration.readerModeErrorText
            return GCDWebServerDataResponse(html: errorString)
        }

        guard let url = URL(string: url), url.isWebPage() else {
            let errorString: String = readerModeConfiguration.readerModeErrorText
            return GCDWebServerDataResponse(html: errorString)
        }

        do {
            let readabilityResult = try readerModeCache.get(url)
            guard let response = generateHtmlFor(
                readabilityResult: readabilityResult,
                style: readerModeStyle,
                readerModeConfiguration: readerModeConfiguration)
            else { return nil }

            return response
        } catch {
            // This page has not been converted to reader mode yet. This happens when you for example add an
            // item via the app extension and the application has not yet had a change to readerize that
            // page in the background.
            //
            // What we do is simply queue the page in the ReadabilityService and then show our loading
            // screen, which will periodically call page-exists to see if the readerized content has
            // become available.
            return handleReaderModeError(url: url, readerModeConfiguration: readerModeConfiguration)
        }
    }

    private func handleReaderModeError(url: URL,
                                       readerModeConfiguration: ReaderModeConfiguration) -> GCDWebServerResponse? {
        WKReadabilityService().process(url, cache: readerModeCache)

        guard let readerViewLoadingPath = Bundle.main.path(forResource: "ReaderViewLoading",
                                                           ofType: "html")
        else {
            let errorString: String = readerModeConfiguration.readerModeErrorText
            return GCDWebServerDataResponse(html: errorString)
        }

        do {
            let readerViewLoading = try NSMutableString(
                contentsOfFile: readerViewLoadingPath,
                encoding: String.Encoding.utf8.rawValue
            )
            replaceOccurrencesIn(readerViewLoading: readerViewLoading,
                                 url: url,
                                 readerModeConfiguration: readerModeConfiguration)
            return GCDWebServerDataResponse(html: readerViewLoading as String)
        } catch _ {
            let errorString: String = readerModeConfiguration.readerModeErrorText
            return GCDWebServerDataResponse(html: errorString)
        }
    }

    private func generateHtmlFor(readabilityResult: ReadabilityResult,
                                 style: ReaderModeStyle,
                                 readerModeConfiguration: ReaderModeConfiguration) -> GCDWebServerDataResponse? {
        var readerModeStyle = style
        // We have this page in our cache, so we can display it. Just grab the correct style from the
        // profile and then generate HTML from the Readability results.
        if let cachedReaderModeStyle = readerModeConfiguration.cachedReaderModeStyle,
           let style = ReaderModeStyle(windowUUID: nil, dict: cachedReaderModeStyle) {
            readerModeStyle = style
        } else {
            readerModeStyle.theme = ReaderModeTheme.preferredTheme(window: nil)
        }

        guard let html = ReaderModeUtils.generateReaderContent(readabilityResult, initialStyle: readerModeStyle),
              let response = GCDWebServerDataResponse(html: html) else { return nil }
        // Apply a Content Security Policy that disallows everything except:
        // - images from anywhere
        // - styles including inline styles from our internal server
        // - scripts including inline scripts from our internal server
        // - fonts our internal server
        let csp = """
            default-src 'none';
            img-src *;
            style-src 'unsafe-inline' http://localhost:*;
            font-src http://localhost:*;
            script-src 'unsafe-inline' http://localhost:*;
        """
        response.setValue(csp, forAdditionalHeader: "Content-Security-Policy")
        return response
    }

    private func replaceOccurrencesIn(readerViewLoading: NSMutableString,
                                      url: URL,
                                      readerModeConfiguration: ReaderModeConfiguration) {
        readerViewLoading.replaceOccurrences(
            of: "%ORIGINAL-URL%",
            with: url.absoluteString,
            options: .literal,
            range: NSRange(location: 0, length: readerViewLoading.length))
        readerViewLoading.replaceOccurrences(
            of: "%LOADING-TEXT%",
            with: readerModeConfiguration.loadingText,
            options: .literal,
            range: NSRange(location: 0, length: readerViewLoading.length))
        readerViewLoading.replaceOccurrences(
            of: "%LOADING-FAILED-TEXT%",
            with: readerModeConfiguration.loadingFailedText,
            options: .literal,
            range: NSRange(location: 0, length: readerViewLoading.length))
        readerViewLoading.replaceOccurrences(
            of: "%LOAD-ORIGINAL-TEXT%",
            with: readerModeConfiguration.loadOriginalText,
            options: .literal,
            range: NSRange(location: 0, length: readerViewLoading.length))
    }

    // MARK: Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .ReaderModeSessionChanged:
            guard let isPrivate = notification.userInfo?[EngineConstants.isPrivateKey] as? Bool else { return }
            readerModeCache = isPrivate ? MemoryReaderModeCache.shared : DiskReaderModeCache.shared
        default:
            break
        }
    }
}
