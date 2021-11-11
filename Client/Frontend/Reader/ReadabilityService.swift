// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import WebKit

private let log = Logger.browserLogger
private let ReadabilityServiceSharedInstance = ReadabilityService()

private let ReadabilityTaskDefaultTimeout = 15
private let ReadabilityServiceDefaultConcurrency = 1

enum ReadabilityOperationResult {
    case success(ReadabilityResult)
    case error(NSError)
    case timeout
}

class ReadabilityOperation: Operation {
    var url: URL
    var semaphore: DispatchSemaphore
    var result: ReadabilityOperationResult?
    var tab: Tab!
    var readerModeCache: ReaderModeCache

    init(url: URL, readerModeCache: ReaderModeCache) {
        self.url = url
        self.semaphore = DispatchSemaphore(value: 0)
        self.readerModeCache = readerModeCache
    }

    override func main() {
        if self.isCancelled {
            return
        }

        // Setup a tab, attach a Readability helper. Kick all this off on the main thread since UIKit
        // and WebKit are not safe from other threads.

        DispatchQueue.main.async(execute: { () -> Void in
            let configuration = WKWebViewConfiguration()
            self.tab = Tab(bvc: BrowserViewController.foregroundBVC(), configuration: configuration)
            self.tab.createWebview()
            self.tab.navigationDelegate = self

            let readerMode = ReaderMode(tab: self.tab)
            readerMode.delegate = self
            self.tab.addContentScript(readerMode, name: ReaderMode.name())

            // Load the page in the webview. This either fails with a navigation error, or we
            // get a readability callback. Or it takes too long, in which case the semaphore
            // times out. The script on the page will retry every 500ms for 10 seconds.
            self.tab.loadRequest(URLRequest(url: self.url))
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
                    log.info("ReadabilityService: Readability result available!")
                    try readerModeCache.put(url, readabilityResult)
                } catch let error as NSError {
                    print("Failed to store readability results in the cache: \(error.localizedDescription)")
                    // TODO Fail
                }
            case .error(_):
                // TODO Not entitely sure what to do on error. Needs UX discussion and followup bug.
                break
            }
        }
    }
}

extension ReadabilityOperation: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        result = ReadabilityOperationResult.error(error as NSError)
        semaphore.signal()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        result = ReadabilityOperationResult.error(error as NSError)
        semaphore.signal()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavascriptInDefaultContentWorld("\(ReaderModeNamespace).checkReadability()")
    }
}

extension ReadabilityOperation: ReaderModeDelegate {
    func readerMode(_ readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forTab tab: Tab) {
    }

    func readerMode(_ readerMode: ReaderMode, didDisplayReaderizedContentForTab tab: Tab) {
    }

    func readerMode(_ readerMode: ReaderMode, didParseReadabilityResult readabilityResult: ReadabilityResult, forTab tab: Tab) {
        log.info("ReadbilityService: Readability result available!")
        guard tab == self.tab else {
            return
        }

        result = ReadabilityOperationResult.success(readabilityResult)
        semaphore.signal()
    }
}

class ReadabilityService {
    class var sharedInstance: ReadabilityService {
        return ReadabilityServiceSharedInstance
    }

    var queue: OperationQueue

    init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = ReadabilityServiceDefaultConcurrency
    }

    func process(_ url: URL, cache: ReaderModeCache) {
        queue.addOperation(ReadabilityOperation(url: url, readerModeCache: cache))
    }
}
