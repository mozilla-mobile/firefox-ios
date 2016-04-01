/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

private let ReadabilityServiceSharedInstance = ReadabilityService()

private let ReadabilityTaskDefaultTimeout = 15
private let ReadabilityServiceDefaultConcurrency = 1

enum ReadabilityOperationResult {
    case Success(ReadabilityResult)
    case Error(NSError)
    case Timeout
}

class ReadabilityOperation: NSOperation, WKNavigationDelegate, ReadabilityTabHelperDelegate {
    var url: NSURL
    var semaphore: dispatch_semaphore_t
    var result: ReadabilityOperationResult?
    var tab: Tab!
    var readerModeCache: ReaderModeCache

    init(url: NSURL, readerModeCache: ReaderModeCache) {
        self.url = url
        self.semaphore = dispatch_semaphore_create(0)
        self.readerModeCache = readerModeCache
    }

    override func main() {
        if self.cancelled {
            return
        }

        // Setup a browser, attach a Readability helper. Kick all this off on the main thread since UIKit
        // and WebKit are not safe from other threads.

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
            self.tab.loadRequest(NSURLRequest(URL: self.url))
        })

        if dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, Int64(Double(ReadabilityTaskDefaultTimeout) * Double(NSEC_PER_SEC)))) != 0 {
            result = ReadabilityOperationResult.Timeout
        }

        // Maybe this is where we should store stuff in the cache / run a callback?

        if let result = self.result {
            switch result {
            case .Timeout:
                // Don't do anything on timeout
                break
            case .Success(let readabilityResult):
                do {
                    try readerModeCache.put(url, readabilityResult)
                } catch let error as NSError {
                    print("Failed to store readability results in the cache: \(error.localizedDescription)")
                    // TODO Fail
                }
            case .Error(_):
                // TODO Not entitely sure what to do on error. Needs UX discussion and followup bug.
                break
            }
        }
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        result = ReadabilityOperationResult.Error(error)
        dispatch_semaphore_signal(semaphore)
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        result = ReadabilityOperationResult.Error(error)
        dispatch_semaphore_signal(semaphore)
    }

    func readabilityTabHelper(readabilityTabHelper: ReadabilityTabHelper, didFinishWithReadabilityResult readabilityResult: ReadabilityResult) {
        result = ReadabilityOperationResult.Success(readabilityResult)
        dispatch_semaphore_signal(semaphore)
    }
}

class ReadabilityService {
    class var sharedInstance: ReadabilityService {
        return ReadabilityServiceSharedInstance
    }

    var queue: NSOperationQueue

    init() {
        queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = ReadabilityServiceDefaultConcurrency
    }

    func process(url: NSURL, cache: ReaderModeCache) {
        queue.addOperation(ReadabilityOperation(url: url, readerModeCache: cache))
    }
}