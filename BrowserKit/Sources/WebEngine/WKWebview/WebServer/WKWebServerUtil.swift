// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol WKWebServerUtil {
    func setUpWebServer(readerModeConfiguration: ReaderModeConfiguration)
    func stopWebServer()
}

class DefaultWKWebServerUtil: WKWebServerUtil {
    private var readerModeHander: WKReaderModeHandlersProtocol
    private var webServer: WKEngineWebServerProtocol
    private let logger: Logger

    init(webServer: WKEngineWebServerProtocol = WKEngineWebServer.shared,
         readerModeHander: WKReaderModeHandlersProtocol = WKReaderModeHandlers(),
         logger: Logger = DefaultLogger.shared) {
        self.webServer = webServer
        self.readerModeHander = readerModeHander
        self.logger = logger
    }

    func setUpWebServer(readerModeConfiguration: ReaderModeConfiguration) {
        guard !webServer.isRunning else { return }

        readerModeHander.register(webServer, readerModeConfiguration: readerModeConfiguration)

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
