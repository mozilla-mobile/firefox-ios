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

    lazy var nimbus: NimbusInterface = {
        let useStagingServer = UserDefaults.standard.bool(forKey: NimbusUseStagingServerDefault)
        let usePreviewCollection = UserDefaults.standard.bool(forKey: NimbusUsePreviewCollectionDefault)
        let isFirstRun = !UserDefaults.standard.bool(forKey: OnboardingConstants.onboardingDidAppear)

        let customTargetingAttibutes = [
            "is_first_run": isFirstRun,
            "isFirstRun": "\(isFirstRun)"
        ]

        guard let nimbusAppSettings = NimbusAppSettings.createFromInfoDictionary(customTargetingAttribtues: customTargetingAttibutes) else {
            fatalError("Failed to load Nimbus settings from Info.plist")
        }

        guard let databasePath = Nimbus.defaultDatabasePath() else {
            fatalError("Failed to determine Nimbus database path")
        }

        let builder = NimbusBuilder(dbPath: databasePath)

        let urlString = NimbusServerSettings.getNimbusEndpoint(useStagingServer: useStagingServer)?.absoluteString
        builder.with(url: urlString)

        let bundles = [
            Bundle.main,
            Bundle.main.fallbackTranslationBundle()
        ].compactMap { $0 }

        builder.with(bundles: bundles)
            .using(previewCollection: usePreviewCollection)
            .with(initialExperiments: Bundle.main.url(forResource: "initial_experiments", withExtension: "json"))
            .isFirstRun(isFirstRun)
            .onCreate { nimbus in
                AppNimbus.shared.initialize { nimbus }
            }
            .onApply { _ in
                AppNimbus.shared.invalidateCachedValues()
            }

        return builder.build(appInfo: nimbusAppSettings)
    }()

    func initializeRustComponents() throws {
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
    }

    func initialize() throws {
        try initializeRustComponents()

        nimbus.fetchExperiments()
    }
}

// Helper functions for the internal settings

extension NimbusWrapper {
    func getAvailableExperiments() -> [AvailableExperiment] {
        return self.nimbus.getAvailableExperiments()
    }

    func getEnrolledBranchSlug(forExperiment experiment: AvailableExperiment) -> String? {
        return self.nimbus.getExperimentBranch(experimentId: experiment.slug)
    }

    func optIn(toExperiment experiment: AvailableExperiment, withBranch branch: ExperimentBranch) {
        self.nimbus.optIn(experiment.slug, branch: branch.slug)
    }

    func optOut(ofExperiment experiment: AvailableExperiment) {
        self.nimbus.optOut(experiment.slug)
    }
}
