// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

public class WKEngine: Engine {
    private let sourceTimerFactory: DispatchSourceTimerFactory
    private var shutdownWebServerTimer: DispatchSourceInterface?
    private let userScriptManager: WKUserScriptManager
    private let webServerUtil: WKWebServerUtil
    private let engineDependencies: EngineDependencies
    private let configProvider: WKEngineConfigurationProvider

    // TODO: With Swift 6 we can use default params in the init
    @MainActor
    public static func factory(engineDependencies: EngineDependencies) -> WKEngine {
        let configProvider = DefaultWKEngineConfigurationProvider()
        let userScriptManager = DefaultUserScriptManager()
        let webServerUtil = DefaultWKWebServerUtil.factory()
        return WKEngine(
            userScriptManager: userScriptManager,
            webServerUtil: webServerUtil,
            sourceTimerFactory: DefaultDispatchSourceTimerFactory(),
            configProvider: configProvider,
            engineDependencies: engineDependencies
        )
    }

    @MainActor
    init(userScriptManager: WKUserScriptManager,
         webServerUtil: WKWebServerUtil,
         sourceTimerFactory: DispatchSourceTimerFactory,
         configProvider: WKEngineConfigurationProvider,
         engineDependencies: EngineDependencies) {
        self.userScriptManager = userScriptManager
        self.webServerUtil = webServerUtil
        self.sourceTimerFactory = sourceTimerFactory
        self.configProvider = configProvider
        self.engineDependencies = engineDependencies

        InternalUtil().setUpInternalHandlers()
    }

    public func createView() -> EngineView {
        return WKEngineView(frame: .zero)
    }

    @MainActor
    public func createSession(dependencies: EngineSessionDependencies) throws -> EngineSession {
        guard let session = WKEngineSession.sessionFactory(userScriptManager: userScriptManager,
                                                           dependencies: dependencies,
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

    // MARK: - Clearing data

    public func clearCaches() {
        DiskReaderModeCache.shared.clear()
        MemoryReaderModeCache.shared.clear()

        let dataTypes = Set([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: .distantPast, completionHandler: {})
    }

    public func clearCookies() {
        let dataTypes = Set(
            [
                WKWebsiteDataTypeCookies,
                WKWebsiteDataTypeLocalStorage,
                WKWebsiteDataTypeSessionStorage,
                WKWebsiteDataTypeWebSQLDatabases,
                WKWebsiteDataTypeIndexedDBDatabases
            ]
        )
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: .distantPast, completionHandler: {})
    }

    public func clearOfflineWebsiteData() {
        let dataTypes = Set([WKWebsiteDataTypeOfflineWebApplicationCache])
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: .distantPast, completionHandler: {})
    }

    public func clearTrackingProtection() {
        // TODO: FXIOS-8088 - Handle content blocking in WebEngine
//        let result = Success()
//        ContentBlocker.shared.clearSafelist {
//            result.fill(Maybe(success: ()))
//        }
    }
}
