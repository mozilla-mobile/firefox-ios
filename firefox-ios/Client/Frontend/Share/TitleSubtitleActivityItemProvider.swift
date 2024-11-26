// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UniformTypeIdentifiers

class TitleSubtitleActivityItemProvider: UIActivityItemProvider, @unchecked Sendable {
    private let message: String
    private let subtitle: String

    init(_ shareMessage: ShareMessage) {
        // If no subtitle is set, repeat the title for the subtitle for apps that use it (e.g. Mail)
        self.message = shareMessage.message
        self.subtitle = shareMessage.subtitle ?? shareMessage.message

        super.init(placeholderItem: message)
    }

    override var item: Any {
        return message
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return UTType.text.identifier
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return subtitle
    }
}
