// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

public class WKEngine: Engine {
    private let sourceTimerFactory: DispatchSourceTimerFactory
    private var shutdownWebServerTimer: DispatchSourceInterface?
    private let userScriptManager: WKUserScriptManager
    private let webServerUtil: WKWebServerUtil
    private let engineDependencies: EngineDependencies

    public static func factory(engineDependencies: EngineDependencies) -> WKEngine {
        return WKEngine(engineDependencies: engineDependencies)
    }

    init(userScriptManager: WKUserScriptManager = DefaultUserScriptManager(),
         webServerUtil: WKWebServerUtil = DefaultWKWebServerUtil(),
         sourceTimerFactory: DispatchSourceTimerFactory = DefaultDispatchSourceTimerFactory(),
         engineDependencies: EngineDependencies) {
        self.userScriptManager = userScriptManager
        self.webServerUtil = webServerUtil
        self.sourceTimerFactory = sourceTimerFactory
        self.engineDependencies = engineDependencies

        InternalUtil().setUpInternalHandlers()
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
        shutdownWebServerTimer?.cancel()
        shutdownWebServerTimer = nil

        webServerUtil.setUpWebServer(readerModeConfiguration: engineDependencies.readerModeConfiguration)
    }

    public func idleEngine() {
        let timer = sourceTimerFactory.createDispatchSource()
        // 2 seconds is ample for a localhost request to be completed by GCDWebServer.
        // <500ms is expected on newer devices.
        timer.schedule(deadline: .now() + 2.0, repeating: .never)
        timer.setEventHandler {
            self.webServerUtil.stopWebServer()
            self.shutdownWebServerTimer = nil
        }
        timer.resume()
        shutdownWebServerTimer = timer
    }
}
