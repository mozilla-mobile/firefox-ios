// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

public enum ReadabilityOperationResult {
    case success(ReadabilityResult)
    case error(NSError)
    case timeout
}

class WKReadabilityOperation: Operation,
                              @unchecked Sendable,
                              WKNavigationDelegate,
                              WKReaderModeDelegate {
    var url: URL
    var semaphore: DispatchSemaphore
    var result: ReadabilityOperationResult?
    var session: WKEngineSession?
    var readerModeCache: ReaderModeCache
    private var logger: Logger

    init(
        url: URL,
        readerModeCache: ReaderModeCache,
        logger: Logger = DefaultLogger.shared
    ) {
        self.url = url
        self.semaphore = DispatchSemaphore(value: 0)
        self.readerModeCache = readerModeCache
        self.logger = logger
    }

    override func main() {
        if self.isCancelled {
            return
        }

        // Setup a tab, attach a Readability helper. Kick all this off on the main thread since UIKit
        // and WebKit are not safe from other threads.
        DispatchQueue.main.async(execute: { () in
            // TODO: FXIOS-11373 - This code needs to be adapted to the WebEngine. Will figure this out in the next PR
//            let windowManager: WindowManager = AppContainer.shared.resolve()
//            let defaultUUID = windowManager.windows.first?.key ?? .unavailable
//            let session = WKEngineSession(userScriptManager: )
//            self.tab = tab
//            tab.navigationDelegate = self
//
//            let readerMode = ReaderMode(tab: tab)
//            readerMode.delegate = self
//            tab.addContentScript(readerMode, name: ReaderMode.name())

            // Load the page in the webview. This either fails with a navigation error, or we
            // get a readability callback. Or it takes too long, in which case the semaphore
            // times out. The script on the page will retry every 500ms for 10 seconds.
//            tab.loadRequest(URLRequest(url: self.url))
        })
        let timeout = DispatchTime.now() + .seconds(10)
        if semaphore.wait(timeout: timeout) == .timedOut {
            result = ReadabilityOperationResult.timeout
        }

        if let result = self.result {
            switch result {
            case .timeout:
                // Don't do anything on timeout
                break
            case .success(let readabilityResult):
                do {
                    try readerModeCache.put(url, readabilityResult)
                    logger.log("Readability result available",
                               level: .info,
                               category: .library)
                } catch let error as NSError {
                    logger.log("Failed to store readability results in the cache: \(error.localizedDescription)",
                               level: .warning,
                               category: .library)
                }
            case .error:
                logger.log("Result was of type error",
                           level: .warning,
                           category: .library)
                break
            }
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation?,
        withError error: Error
    ) {
        result = ReadabilityOperationResult.error(error as NSError)
        semaphore.signal()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        result = ReadabilityOperationResult.error(error as NSError)
        semaphore.signal()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        guard let session else { return }
        session.webView.evaluateJavascriptInDefaultContentWorld(
            "\(ReaderModeInfo.namespace.rawValue).checkReadability()"
        )
    }

    // MARK: - WKReaderModeDelegate

    func readerMode(
        _ readerMode: ReaderModeStyleSetter,
        didChangeReaderModeState state: ReaderModeState,
        forSession session: EngineSession
    ) {}

    func readerMode(
        _ readerMode: ReaderModeStyleSetter,
        didDisplayReaderizedContentForSession session: EngineSession
    ) {}

    func readerMode(
        _ readerMode: ReaderModeStyleSetter,
        didParseReadabilityResult readabilityResult: ReadabilityResult,
        forSession session: EngineSession
    ) {
        logger.log("Did parse ReadabilityResult",
                   level: .debug,
                   category: .library)
        guard session == self.session else { return }

        result = ReadabilityOperationResult.success(readabilityResult)
        semaphore.signal()
    }
}
