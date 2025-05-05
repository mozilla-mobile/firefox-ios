// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

public enum ReadabilityOperationResult {
    case success(ReadabilityResult)
    case error(NSError)
    case timeout
}

protocol ReaderModeNavigationDelegate: AnyObject {
    func didFailWithError(error: Error)
    func didFinish()
}

// TODO: FXIOS-11373 - finish handling reader mode in WebEngine - this class is to be tested
class WKReadabilityOperation: Operation,
                              @unchecked Sendable,
                              ReaderModeNavigationDelegate,
                              WKReaderModeDelegate {
    var url: URL
    var semaphore: DispatchSemaphore
    var result: ReadabilityOperationResult?
    var session: WKEngineSession?
    var readerModeCache: ReaderModeCache
    private let mainQueue: DispatchQueueInterface
    private var logger: Logger

    init(
        url: URL,
        readerModeCache: ReaderModeCache,
        mainQueue: DispatchQueueInterface = DispatchQueue.main,
        logger: Logger = DefaultLogger.shared
    ) {
        self.url = url
        self.semaphore = DispatchSemaphore(value: 0)
        self.readerModeCache = readerModeCache
        self.mainQueue = mainQueue
        self.logger = logger
    }

    override func main() {
        if self.isCancelled {
            return
        }

        // Setup a new session and kick all this off on the main thread since UIKit
        // and WebKit are not safe from other threads.
        Task { @MainActor in
            let configProvider = DefaultWKEngineConfigurationProvider()
            let parameters = WKWebViewParameters()
            let dependencies = EngineSessionDependencies(webviewParameters: parameters)
            let session = WKEngineSession.sessionFactory(userScriptManager: DefaultUserScriptManager(),
                                                         dependencies: dependencies,
                                                         configurationProvider: configProvider,
                                                         readerModeDelegate: self)
            session?.navigationHandler.readerModeNavigationDelegate = self
            self.session = session

            // Load the page in the session. This either fails with a navigation error, or we
            // get a readability callback. Or it takes too long, in which case the semaphore
            // times out. The script on the page will retry every 500ms for 10 seconds.
            let context = BrowsingContext(type: .internalNavigation, url: self.url)
            guard let browserURL = BrowserURL(browsingContext: context) else { return }
            session?.load(browserURL: browserURL)
        }

        let timeout = DispatchTime.now() + .seconds(10)
        if semaphore.wait(timeout: timeout) == .timedOut {
            result = ReadabilityOperationResult.timeout
        }

        processResult()
    }

    private func processResult() {
        guard let result = self.result else { return }

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

    // MARK: - ReaderModeNavigationDelegate

    func didFailWithError(error: Error) {
        result = ReadabilityOperationResult.error(error as NSError)
        semaphore.signal()
    }

    func didFinish() {
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
