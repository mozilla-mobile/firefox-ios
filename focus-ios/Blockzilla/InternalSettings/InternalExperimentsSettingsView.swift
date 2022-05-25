/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import FocusAppServices

struct InternalExperimentsSettingsView {
    let availableExperiments: [AvailableExperiment]
    @ObservedObject var internalSettings = InternalSettings()
}

extension InternalExperimentsSettingsView: View {
    var body: some View {
        Form {
            SwiftUI.Section(header: Text(verbatim: "Settings")) {
                Toggle(isOn: $internalSettings.useStagingServer) {
                    VStack(alignment: .leading) {
                        Text(verbatim: "Use Staging Server")
                        Text(verbatim: "Requires app restart").font(.caption)
                    }
                }
                Toggle(isOn: $internalSettings.usePreviewCollection) {
                    VStack(alignment: .leading) {
                        Text(verbatim: "Use Preview Collection")
                        Text(verbatim: "Requires app restart").font(.caption)
                    }
                }
            }
            SwiftUI.Section(header: Text(verbatim: "Available Experiments")) {
                if availableExperiments.isEmpty {
                    Text(verbatim: "No Experiments Found")
                } else {
                    ForEach(availableExperiments, id: \.slug) { experiment in
                        NavigationLink(destination: InternalExperimentDetailView(experiment: experiment)) {
                            VStack(alignment: .leading) {
                                Text(verbatim: experiment.userFacingName)
                                Text(verbatim: experiment.slug).font(.caption)
                            }
                        }
                    }
                }
            }
        }.navigationBarTitle(Text(verbatim: "Experiments Settings"))
    }
}

struct InternalExperimentsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        InternalExperimentsSettingsView(availableExperiments: [
            AvailableExperiment(slug: "something-experiment", userFacingName: "Some Experiment", userFacingDescription: "Some Experiment to Experiment", branches: [.init(slug: "control", ratio: 50)], referenceBranch: nil),
            AvailableExperiment(slug: "another-experiment", userFacingName: "Another Experiment", userFacingDescription: "Another Experiment to Try", branches: [.init(slug: "control", ratio: 50)], referenceBranch: nil)
        ])
    }
}
