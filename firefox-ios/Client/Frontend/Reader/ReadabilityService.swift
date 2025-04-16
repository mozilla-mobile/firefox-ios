// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common
import WebKit
import WebEngine

class ReadabilityOperation: Operation, @unchecked Sendable {
    let profile: Profile

    var url: URL
    var semaphore: DispatchSemaphore
    var result: ReadabilityOperationResult?
    var tab: Tab?
    var readerModeCache: ReaderModeCache
    private var logger: Logger

    init(
        url: URL,
        readerModeCache: ReaderModeCache,
        profile: Profile,
        logger: Logger = DefaultLogger.shared
    ) {
        self.url = url
        self.semaphore = DispatchSemaphore(value: 0)
        self.readerModeCache = readerModeCache
        self.profile = profile
        self.logger = logger
    }

    override func main() {
        if self.isCancelled {
            return
        }

        // Setup a tab, attach a Readability helper. Kick all this off on the main thread since UIKit
        // and WebKit are not safe from other threads.

        DispatchQueue.main.async(execute: { () in
            let configuration = WKWebViewConfiguration()
            let windowManager: WindowManager = AppContainer.shared.resolve()
            let defaultUUID = windowManager.windows.first?.key ?? .unavailable
            let tab = Tab(profile: self.profile, windowUUID: defaultUUID)
            self.tab = tab
            tab.createWebview(configuration: configuration)
            tab.navigationDelegate = self

            let readerMode = ReaderMode(tab: tab)
            readerMode.delegate = self
            tab.addContentScript(readerMode, name: ReaderMode.name())

            // Load the page in the webview. This either fails with a navigation error, or we
            // get a readability callback. Or it takes too long, in which case the semaphore
            // times out. The script on the page will retry every 500ms for 10 seconds.
            tab.loadRequest(URLRequest(url: self.url))
        })
        let timeout = DispatchTime.now() + .seconds(10)
        if semaphore.wait(timeout: timeout) == .timedOut {
            result = ReadabilityOperationResult.timeout
        }

        // Maybe this is where we should store stuff in the cache / run a callback?

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
}

extension ReadabilityOperation: WKNavigationDelegate {
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
        webView.evaluateJavascriptInDefaultContentWorld("\(ReaderModeInfo.namespace.rawValue).checkReadability()")
    }
}

extension ReadabilityOperation: ReaderModeDelegate {
    func readerMode(
        _ readerMode: ReaderMode,
        didChangeReaderModeState state: ReaderModeState,
        forTab tab: Tab
    ) {
    }

    func readerMode(
        _ readerMode: ReaderMode,
        didDisplayReaderizedContentForTab tab: Tab
    ) {
    }

    func readerMode(
        _ readerMode: ReaderMode,
        didParseReadabilityResult readabilityResult: ReadabilityResult,
        forTab tab: Tab
    ) {
        logger.log("Did parse ReadabilityResult",
                   level: .debug,
                   category: .library)
        guard tab == self.tab else { return }

        result = ReadabilityOperationResult.success(readabilityResult)
        semaphore.signal()
    }
}

class ReadabilityService {
    private let ReadabilityServiceDefaultConcurrency = 1

    var queue: OperationQueue

    init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = ReadabilityServiceDefaultConcurrency
    }

    func process(_ url: URL, cache: ReaderModeCache, with profile: Profile) {
        let readabilityOperation = ReadabilityOperation(url: url,
                                                        readerModeCache: cache,
                                                        profile: profile)

        queue.addOperation(readabilityOperation)
    }
}
