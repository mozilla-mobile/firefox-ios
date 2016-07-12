/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

private let ReadabilityServiceSharedInstance = ReadabilityService()

private let ReadabilityTaskDefaultTimeout = 15
private let ReadabilityServiceDefaultConcurrency = 1

enum ReadabilityOperationResult {
    case success(ReadabilityResult)
    case error(NSError)
    case timeout
}

class ReadabilityOperation: Operation, WKNavigationDelegate, ReadabilityTabHelperDelegate {
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
            self.tab = Tab(configuration: configuration)
            self.tab.createWebview()
            self.tab.navigationDelegate = self

            if let readabilityTabHelper = ReadabilityTabHelper(tab: self.tab) {
                readabilityTabHelper.delegate = self
                self.tab.addHelper(readabilityTabHelper, name: ReadabilityTabHelper.name())
            }

            // Load the page in the webview. This either fails with a navigation error, or we get a readability
            // callback. Or it takes too long, in which case the semaphore times out.
            self.tab.load(URLRequest(url: self.url))
        })

        if semaphore.wait(timeout: DispatchTime.now() + Double(Int64(Double(ReadabilityTaskDefaultTimeout) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) != 0 {
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

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: NSError) {
        result = ReadabilityOperationResult.error(error)
        semaphore.signal()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        result = ReadabilityOperationResult.error(error)
        semaphore.signal()
    }

    func readabilityTabHelper(_ readabilityTabHelper: ReadabilityTabHelper, didFinishWithReadabilityResult readabilityResult: ReadabilityResult) {
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
