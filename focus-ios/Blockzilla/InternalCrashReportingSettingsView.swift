/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import Sentry

struct InternalCrashReportingSettingsView: View {
    var body: some View {
        Form {
            SwiftUI.Section(header: Text("Crash Triggers")) {
                Button("SentrySDK.crash()") {
                    SentrySDK.crash()
                }
                Button("SentrySDK.capture(message:)") {
                    SentrySDK.capture(message: "Test")
                }
                Button("SentrySDK.capture(exception:)") {
                    SentrySDK.capture(exception: NSException(name: .genericException, reason: "Test Exception", userInfo: ["UserInfo": "Something"]))
                }
                Button("SentrySDK.capture(error:)") {
                    SentrySDK.capture(error: NSError(domain: "TestDomain", code: 42, userInfo: ["UserInfo": "Something"]))
                }
            }
        }.navigationBarTitle("Crash Reporting Settings")
    }
}

struct InternalCrashReportingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        InternalCrashReportingSettingsView()
    }
}
