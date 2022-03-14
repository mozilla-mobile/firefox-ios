/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct InternalOnboardingSettingsView {
    @ObservedObject var internalSettings = InternalSettings()
}

extension InternalOnboardingSettingsView: View {
    var body: some View {
        Form {
            Toggle(isOn: $internalSettings.ignoreOnboardingExperiment) {
                Text(verbatim: "Ignore Onboarding Experiment")
            }
            Toggle(isOn: $internalSettings.alwaysShowOnboarding) {
                Text(verbatim: "Always Show Onboarding + Tips")
            }
            Toggle(isOn: $internalSettings.showOldOnboarding) {
                Text(verbatim: "Show Old Onboarding")
            }
        }.navigationBarTitle(Text(verbatim: "Onboarding Settings"))
    }
}

struct InternalOnboardingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        InternalOnboardingSettingsView()
    }
}
