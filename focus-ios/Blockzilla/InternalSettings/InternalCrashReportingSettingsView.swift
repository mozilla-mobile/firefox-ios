/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import Sentry

struct InternalCrashReportingSettingsView: View {
    var body: some View {
        Form {
            SwiftUI.Section(header: Text(verbatim: "Crash Triggers")) {
                Button(action: { SentrySDK.crash() }) {
                    Text(verbatim: "SentrySDK.crash()")
                }
                Button(action: { SentrySDK.capture(message: "Test") }) {
                    Text(verbatim: "SentrySDK.capture(message:)")
                }
                Button(action: { SentrySDK.capture(exception: NSException(name: .genericException, reason: "Test Exception", userInfo: ["UserInfo": "Something"])) }) {
                    Text(verbatim: "SentrySDK.capture(exception:)")
                }
                Button(action: { SentrySDK.capture(error: NSError(domain: "TestDomain", code: 42, userInfo: ["UserInfo": "Something"])) }) {
                    Text(verbatim: "SentrySDK.capture(error:)")
                }
            }
        }.navigationBarTitle(Text(verbatim: "Crash Reporting Settings"))
    }
}

struct InternalCrashReportingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        InternalCrashReportingSettingsView()
    }
}
