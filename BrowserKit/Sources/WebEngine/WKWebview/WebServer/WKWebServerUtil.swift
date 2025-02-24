// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import GCDWebServers

protocol WKWebServerUtil {
    func setUpWebServer()
    func stopWebServer()
}

class DefaultWKWebServerUtil: WKWebServerUtil {
    // TODO: FXIOS-11373 Handle Reader mode in WebEngine
    //    private var readerModeHander: ReaderModeHandlersProtocol
    private var webServer: WKEngineWebServerProtocol
    private var logger: Logger

    init(webServer: WKEngineWebServerProtocol = WKEngineWebServer.shared,
         logger: Logger = DefaultLogger.shared) {
        // TODO: FXIOS-11373 Handle Reader mode in WebEngine
        //        readerModeHander: ReaderModeHandlersProtocol = ReaderModeHandlers()
        self.webServer = webServer
        self.logger = logger
    }

    func setUpWebServer() {
        guard !webServer.isRunning else { return }

        // TODO: FXIOS-11373 Handle Reader mode in WebEngine
        //        readerModeHander.register(webServer, profile: profile)

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
