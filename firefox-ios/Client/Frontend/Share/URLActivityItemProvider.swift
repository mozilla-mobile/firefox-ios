// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UniformTypeIdentifiers

class URLActivityItemProvider: UIActivityItemProvider, @unchecked Sendable {
    private let url: URL

    // We don't want to add this URL to Safari's Reading List
    static let excludedActivities = [
        UIActivity.ActivityType.addToReadingList,
    ]

    init(url: URL) {
        self.url = url

        super.init(placeholderItem: url)
    }

    override var placeholderItem: Any? {
        return url
    }

    override var item: Any {
        if let activityType = activityType, URLActivityItemProvider.excludedActivities.contains(activityType) {
            return NSNull()
        }

        return url
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return url.isFileURL ? UTType.fileURL.identifier : UTType.url.identifier
    }
}
