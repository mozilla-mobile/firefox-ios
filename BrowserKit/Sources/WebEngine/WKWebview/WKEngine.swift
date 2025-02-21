// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public class WKEngine: Engine {
    private var shutdownWebServer: DispatchSourceTimer?
    private let userScriptManager: WKUserScriptManager
    private let webServerUtil: WKWebServerUtil

    public static func factory() -> WKEngine {
        return WKEngine()
    }

    init(userScriptManager: WKUserScriptManager = DefaultUserScriptManager()) {
        self.userScriptManager = userScriptManager

        InternalUtil().setUpInternalHandlers()
        webServerUtil = WKWebServerUtil()
    }

    public func createView() -> EngineView {
        return WKEngineView(frame: .zero)
    }

    public func createSession(dependencies: EngineSessionDependencies) throws -> EngineSession {
        let configProvider = DefaultWKEngineConfigurationProvider(parameters: dependencies.webviewParameters)
        guard let session = WKEngineSession(userScriptManager: userScriptManager,
                                            telemetryProxy: dependencies.telemetryProxy,
                                            configurationProvider: configProvider) else {
            throw EngineError.sessionNotCreated
        }

        return session
    }

    public func warmEngine() {
        shutdownWebServer?.cancel()
        shutdownWebServer = nil

        webServerUtil.setUpWebServer()
    }

    public func idleEngine() {
        let singleShotTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        // 2 seconds is ample for a localhost request to be completed by GCDWebServer.
        // <500ms is expected on newer devices.
        singleShotTimer.schedule(deadline: .now() + 2.0, repeating: .never)
        singleShotTimer.setEventHandler {
            self.webServerUtil.stopWebServer()
            self.shutdownWebServer = nil
        }
        singleShotTimer.resume()
        shutdownWebServer = singleShotTimer
    }
}
