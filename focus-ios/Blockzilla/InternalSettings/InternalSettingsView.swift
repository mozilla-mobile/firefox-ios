/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct InternalSettingsView: View {

    var body: some View {
        Form {
            SwiftUI.Section {
                NavigationLink(destination: InternalOnboardingSettingsView()) {
                    Text(verbatim: "Onboarding")
                }
            }
            SwiftUI.Section {
                NavigationLink(destination: InternalExperimentsSettingsView(availableExperiments: NimbusWrapper.shared.getAvailableExperiments())) {
                    Text(verbatim: "Experiments")
                }
            }
            SwiftUI.Section {
                NavigationLink(destination: InternalTelemetrySettingsView()) {
                    Text(verbatim: "Telemetry")
                }
            }
            SwiftUI.Section {
                NavigationLink(destination: InternalCrashReportingSettingsView()) {
                    Text(verbatim: "Crash Reporting")
                }
            }
            SwiftUI.Section {
                Text(verbatim: "The settings in this section are used by Focus developers and testers.")
                    .font(.caption)
            }
        }.navigationBarTitle(Text(verbatim: "Internal Settings"))
    }
}

struct InternalSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        InternalSettingsView()
    }
}
