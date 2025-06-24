// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AppIntents
import Common

@available(iOS 17.0, *)
struct DownloadLiveActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop Downloads"

    @Parameter(title: "WindowUUID")
    var windowUUID: String

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: Notification.Name.StopDownloads,
                                        object: self,
                                        userInfo: ["windowUUID": windowUUID])

        return .result()
    }
}
