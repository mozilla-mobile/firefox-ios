// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import struct MozillaAppServices.EnrolledExperiment
@testable import Client

final class ExperimentsTests: XCTestCase {
    func testFeatureBranches_noActiveExperiments_isEmpty() {
        XCTAssertEqual(Experiments.featureBranches(from: []), [:])
    }

    func testFeatureBranches_mapsEachFeatureToItsBranch() {
        let experiments = [
            makeEnrollment(slug: "homepage-test", featureIds: ["homepage"], branch: "control"),
            makeEnrollment(slug: "tab-tray-test", featureIds: ["tab-tray"], branch: "treatment-a")
        ]

        XCTAssertEqual(Experiments.featureBranches(from: experiments),
                       ["homepage": "control", "tab-tray": "treatment-a"])
    }

    func testFeatureBranches_multiFeatureExperiment_mapsEveryFeature() {
        let experiments = [
            makeEnrollment(slug: "onboarding-test", featureIds: ["onboarding", "homepage"], branch: "treatment-a")
        ]

        XCTAssertEqual(Experiments.featureBranches(from: experiments),
                       ["onboarding": "treatment-a", "homepage": "treatment-a"])
    }

    func testFeatureBranches_rolloutOnly_isIncluded() {
        let experiments = [
            makeEnrollment(slug: "homepage-rollout", featureIds: ["homepage"], branch: "rollout", isRollout: true)
        ]

        XCTAssertEqual(Experiments.featureBranches(from: experiments), ["homepage": "rollout"])
    }

    func testFeatureBranches_experimentAndRolloutOnSameFeature_experimentWins() {
        let experiment = makeEnrollment(slug: "homepage-test", featureIds: ["homepage"], branch: "treatment-a")
        let rollout = makeEnrollment(slug: "homepage-rollout", featureIds: ["homepage"], branch: "rollout", isRollout: true)

        XCTAssertEqual(Experiments.featureBranches(from: [experiment, rollout]), ["homepage": "treatment-a"])
        XCTAssertEqual(Experiments.featureBranches(from: [rollout, experiment]), ["homepage": "treatment-a"])
    }

    private func makeEnrollment(slug: String,
                                featureIds: [String],
                                branch: String,
                                isRollout: Bool = false) -> EnrolledExperiment {
        return EnrolledExperiment(
            featureIds: featureIds,
            slug: slug,
            userFacingName: slug,
            userFacingDescription: slug,
            branchSlug: branch,
            isRollout: isRollout
        )
    }
}
