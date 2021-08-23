/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

private let log = Logger.browserLogger

import Foundation

extension AppDelegate {
    func initializeExperiments() {
        Experiments.customTargetingAttributes =  ["isFirstRun": "\(Experiments.isFirstRun)"]
        let initialExperiments = Bundle.main.url(forResource: "initial_experiments", withExtension: "json")
        let serverURL = Experiments.remoteSettingsURL
        let savedOptions = Experiments.getLocalExperimentData()
        let options: Experiments.InitializationOptions
        switch (savedOptions, initialExperiments, serverURL) {
        // QA testing case: experiments come from the Experiments setting screen.
        case (let payload, _, _) where payload != nil:
            log.info("Nimbus: Loading from experiments provided by settings screen")
            options = Experiments.InitializationOptions.testing(localPayload: payload!)
        // Local development case: load from the bundled initial_experiments.json
        case (_, let file, let url) where file != nil && url == nil:
            log.info("Nimbus: Loading from experiments from bundle, with no URL")
            options = Experiments.InitializationOptions.dev(fileUrl: file!)
        case (_, _, let url) where url != nil:
            log.info("Nimbus: server exists")
            options = Experiments.InitializationOptions.normal
        default:
            log.info("Nimbus: server does not exist")
            options = Experiments.InitializationOptions.normal
        }
        if Experiments.isFirstRun {
            Experiments.initializeFirstRun(options)
        } else {
            Experiments.intialize(options)
        }
    }
}
