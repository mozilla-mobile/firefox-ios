/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Combine
import SwiftUI
import FocusAppServices

private let notEnrolledBranchSlug = "not-enrolled"

struct InternalExperimentDetailView {
    let experiment: AvailableExperiment
    @State private var selectedBranchSlug: String
    let pickerBranches: [String]

    init(experiment: AvailableExperiment) {
        self.experiment = experiment
        self.selectedBranchSlug = NimbusWrapper.shared.getEnrolledBranchSlug(forExperiment: experiment) ?? notEnrolledBranchSlug
        self.pickerBranches = [notEnrolledBranchSlug] + experiment.branches.map { $0.slug }
    }
}

extension InternalExperimentDetailView: View {
    var body: some View {
        Form {
            SwiftUI.Section {
                Text(verbatim: experiment.userFacingDescription)
            }
            SwiftUI.Section(header: Text(verbatim: "Available Branches")) {
                ForEach(experiment.branches, id: \.slug) { branch in
                    HStack {
                        Text(verbatim: branch.slug)
                        Spacer()
                        Text(verbatim: "\(branch.ratio)")
                    }
                }
            }
            SwiftUI.Section {
                Picker(selection: $selectedBranchSlug, label: Text(verbatim: "Active Branch")) {
                    ForEach(pickerBranches, id: \.self) { branch in
                        if branch == notEnrolledBranchSlug {
                            Text(verbatim: "Not Enrolled")
                        } else {
                            Text(verbatim: branch)
                        }
                    }
                }.onReceive(Just(selectedBranchSlug)) { newValue in
                    if newValue != notEnrolledBranchSlug {
                        if NimbusWrapper.shared.getEnrolledBranchSlug(forExperiment: experiment) != newValue {
                            if let branch = experiment.branches.first(where: { $0.slug == newValue }) {
                                NimbusWrapper.shared.optIn(toExperiment: experiment, withBranch: branch)
                            }
                        }
                    } else {
                        if NimbusWrapper.shared.getEnrolledBranchSlug(forExperiment: experiment) != nil {
                            NimbusWrapper.shared.optOut(ofExperiment: experiment)
                        }
                    }
                }
            }
        }.navigationBarTitle(Text(verbatim: experiment.userFacingName))
    }
}

struct InternalExperimentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let experiment = AvailableExperiment(
            slug: "some-slug",
            userFacingName: "Some Experiment",
            userFacingDescription: "Some Experiment Description This is some longer text that is user facing.",
            branches: [ExperimentBranch(slug: "control", ratio: 50), ExperimentBranch(slug: "test", ratio: 50)],
            referenceBranch: "control"
        )
        InternalExperimentDetailView(experiment: experiment)
    }
}
