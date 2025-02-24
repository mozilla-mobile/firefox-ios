// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import GCDWebServers
import Common

protocol WKWebServerUtil {
    func setUpWebServer()
    func stopWebServer()
}

class DefaultWKWebServerUtil: WKWebServerUtil {
    // TODO: FXIOS-11373 Handle Reader mode in WebEngine
    //    private var readerModeHander: ReaderModeHandlersProtocol
    private var webServer: WKEngineWebServerProtocol

    init(webServer: WKEngineWebServerProtocol = WKEngineWebServer.shared) {
        // TODO: FXIOS-11373 Handle Reader mode in WebEngine
        //        readerModeHander: ReaderModeHandlersProtocol = ReaderModeHandlers()
        self.webServer = webServer
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
            // TODO: Laurie - add logger call here in catch
        }
    }

    func stopWebServer() {
        webServer.stop()
    }
}
