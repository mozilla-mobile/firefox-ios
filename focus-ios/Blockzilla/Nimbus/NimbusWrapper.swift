/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import os.log

import Foundation
import FocusAppServices

let NimbusUseStagingServerDefault = "NimbusUseStagingServer"
let NimbusUsePreviewCollectionDefault = "NimbusUsePreviewCollection"

final class NimbusWrapper {
    static let shared = NimbusWrapper()

    private init() {
    }

    lazy var nimbus: NimbusInterface = {
        let useStagingServer = UserDefaults.standard.bool(forKey: NimbusUseStagingServerDefault)
        let usePreviewCollection = UserDefaults.standard.bool(forKey: NimbusUsePreviewCollectionDefault)
        let isFirstRun = !UserDefaults.standard.bool(forKey: OnboardingConstants.onboardingDidAppear)

        let customTargetingAttibutes: [String: Any] = [
            "is_first_run": isFirstRun,
            "isFirstRun": "\(isFirstRun)"
        ]

        guard let nimbusAppSettings = NimbusAppSettings.createFromInfoDictionary(customTargetingAttribtues: customTargetingAttibutes) else {
            fatalError("Failed to load Nimbus settings from Info.plist")
        }

        guard let databasePath = Nimbus.defaultDatabasePath() else {
            fatalError("Failed to determine Nimbus database path")
        }

        let urlString = NimbusServerSettings.getNimbusEndpoint(useStagingServer: useStagingServer)?.absoluteString

        let bundles = [
            Bundle.main,
            Bundle.main.fallbackTranslationBundle(language: "en-US")
        ].compactMap { $0 }

        return NimbusBuilder(dbPath: databasePath)
            .with(url: urlString)
            .with(bundles: bundles)
            .with(featureManifest: AppNimbus.shared)
            .with(commandLineArgs: CommandLine.arguments)
            .using(previewCollection: usePreviewCollection)
            .with(initialExperiments: Bundle.main.url(forResource: "initial_experiments", withExtension: "json"))
            .isFirstRun(isFirstRun)
            .build(appInfo: nimbusAppSettings)
    }()

    func initializeRustComponents() {
        Viaduct.shared.useReqwestBackend()
    }

    func initialize() {
        initializeRustComponents()

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
