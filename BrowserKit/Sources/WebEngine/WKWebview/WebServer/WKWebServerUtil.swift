// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol WKWebServerUtil {
    func setUpWebServer(readerModeConfiguration: ReaderModeConfiguration)
    func stopWebServer()
}

class DefaultWKWebServerUtil: WKWebServerUtil {
    private var readerModeHandler: WKReaderModeHandlersProtocol
    private var webServer: WKEngineWebServerProtocol
    private let logger: Logger

    init(webServer: WKEngineWebServerProtocol,
         readerModeHandler: WKReaderModeHandlersProtocol = WKReaderModeHandlers(),
         logger: Logger = DefaultLogger.shared) {
        self.webServer = webServer
        self.readerModeHandler = readerModeHandler
        self.logger = logger
    }

    // TODO: With Swift 6 we can use default params in the init
    @MainActor
    static func factory() -> DefaultWKWebServerUtil {
        let webServer = WKEngineWebServer.shared
        return DefaultWKWebServerUtil(webServer: webServer)
    }

    func setUpWebServer(readerModeConfiguration: ReaderModeConfiguration) {
        guard !webServer.isRunning else { return }

        readerModeHandler.register(webServer, readerModeConfiguration: readerModeConfiguration)

        if AppConstants.isRunningTest {
            webServer.addTestHandler()
        }

        do {
            try webServer.start()
        } catch {
            logger.log("Web server start failed.", level: .warning, category: .webview)
        }
    }

    func stopWebServer() {
        webServer.stop()
    }
}
