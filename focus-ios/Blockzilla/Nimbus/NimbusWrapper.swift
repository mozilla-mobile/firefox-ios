/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import os.log

import Foundation
import FocusAppServices

let NimbusUseStagingServerDefault = "NimbusUseStagingServer"
let NimbusUsePreviewCollectionDefault = "NimbusUsePreviewCollection"

class NimbusWrapper {
    static let shared = NimbusWrapper()

    private init() {
    }

    var nimbus: NimbusApi?

    func initialize(enabled: Bool, isFirstRun: Bool = false) throws {
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

        let useStagingServer = UserDefaults.standard.bool(forKey: NimbusUseStagingServerDefault)
        let usePreviewCollection = UserDefaults.standard.bool(forKey: NimbusUsePreviewCollectionDefault)

        guard let nimbusAppSettings = NimbusAppSettings.createFromInfoDictionary() else {
            throw "Failed to load Nimbus settings from Info.plist"
        }

        let nimbusServerSettings = NimbusServerSettings.createFromInfoDictionary(useStagingServer: useStagingServer, usePreviewCollection: usePreviewCollection)

        guard let databasePath = Nimbus.defaultDatabasePath() else {
            throw "Failed to determine Nimbus database path"
        }

        self.nimbus = try Nimbus.create(nimbusServerSettings, appSettings: nimbusAppSettings, dbPath: databasePath, enabled: enabled)

        guard let nimbus = self.nimbus else {
            return
        }
        if isFirstRun || nimbusServerSettings == nil {
            if let fileURL = Bundle.main.url(forResource: "initial_experiments", withExtension: "json") {
                nimbus.setExperimentsLocally(fileURL)
            }
        }
        nimbus.applyPendingExperiments()
        nimbus.fetchExperiments()
    }
}

// Helper functions for the internal settings

extension NimbusWrapper {
    func getAvailableExperiments() -> [AvailableExperiment] {
        return self.nimbus?.getAvailableExperiments() ?? []
    }

    func getEnrolledBranchSlug(forExperiment experiment: AvailableExperiment) -> String? {
        return self.nimbus?.getExperimentBranch(experimentId: experiment.slug)
    }

    func optIn(toExperiment experiment: AvailableExperiment, withBranch branch: ExperimentBranch) {
        self.nimbus?.optIn(experiment.slug, branch: branch.slug)
    }

    func optOut(ofExperiment experiment: AvailableExperiment) {
        self.nimbus?.optOut(experiment.slug)
    }
}
