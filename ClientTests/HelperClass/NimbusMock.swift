// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client
import MozillaAppServices

class NimbusMock: NimbusApi {

    init() {}
    func initialize() {}

    func recordExposureEvent(featureId: String) {}

    func getVariables(featureId: String, sendExposureEvent: Bool) -> Variables {
        fatalError("Not implemented in mock yet")
    }

    func fetchExperiments() {}

    func applyPendingExperiments() {}

    func setExperimentsLocally(_ experimentsJson: String) {}

    func setExperimentsLocally(_ fileURL: URL) {}

    func optOut(_ experimentId: String) {}

    func optIn(_ experimentId: String, branch: String) {}

    func resetTelemetryIdentifiers() {}

    var globalUserParticipation: Bool = true

    func getActiveExperiments() -> [EnrolledExperiment] {
        fatalError("Not implemented in mock yet")
    }

    func getExperimentBranches(_ experimentId: String) -> [Branch]? {
        fatalError("Not implemented in mock yet")
    }

    func getAvailableExperiments() -> [AvailableExperiment] {
        fatalError("Not implemented in mock yet")
    }

    func getExperimentBranch(experimentId: String) -> String? {
        fatalError("Not implemented in mock yet")
    }

    func createMessageHelper() throws -> GleanPlumbMessageHelper {
        fatalError("Not implemented in mock yet")
    }

    func createMessageHelper(additionalContext: [String : Any]) throws -> GleanPlumbMessageHelper {
        fatalError("Not implemented in mock yet")
    }

    func createMessageHelper<T>(additionalContext: T) throws -> GleanPlumbMessageHelper where T : Encodable {
        fatalError("Not implemented in mock yet")
    }
}
