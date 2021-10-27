/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import os.log

import RustLog
import Viaduct
import Nimbus

/// An application specific enum of app features that we are configuring with experiments.
/// This is expected to grow and shrink across releases of the app.
enum FeatureId: String {
    case nimbusValidation = "nimbus-validation"
}

class NimbusWrapper {
    static let shared = NimbusWrapper()
    
    private init() {
    }
    
    var nimbus: NimbusApi?
    
    func initialize(enabled: Bool) throws {
        let rustLogCallback: LogCallback = { level, tag, message in
            let log = OSLog(subsystem: "org.mozilla.nimbus", category: tag ?? "default")
            switch level {
                case .trace:
                    os_log("%{private}@", log: log, type: .error, message) // Only logs when attached to debugger
                case .debug:
                    os_log("%@", log: log, type: .debug, message)
                case .info:
                    os_log("%@", log: log, type: .info, message)
                case .warn:
                    os_log("%@", log: log, type: .fault, message)
                case .error:
                    os_log("%@", log: log, type: .error, message)
            }
            return true
        }
        
        if !RustLog.shared.tryEnable(rustLogCallback) {
            throw "Failed to initialize Rustlog"
        }

        Viaduct.shared.useReqwestBackend()

        guard let nimbusServerSettings = NimbusServerSettings.createFromInfoDictionary(), let nimbusAppSettings = NimbusAppSettings.createFromInfoDictionary() else {
            throw "Failed to load Nimbus settings from Info.plist"
        }

        guard let databasePath = Nimbus.defaultDatabasePath() else {
            throw "Failed to determine Nimbus database path"
        }

        self.nimbus = try Nimbus.create(nimbusServerSettings, appSettings: nimbusAppSettings, dbPath: databasePath, enabled: enabled)
        self.nimbus?.initialize()
        self.nimbus?.applyPendingExperiments()
        self.nimbus?.fetchExperiments()
    }
}
