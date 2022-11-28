// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class CopyLinkActivity: UIActivity {
    var appActivityType: CustomActivityAction
    var url: URL

    override var activityTitle: String? {
        return appActivityType.title
    }

    override var activityImage: UIImage? {
        return appActivityType.image
    }

    override var activityType: UIActivity.ActivityType {
        return appActivityType.actionType
    }

    override class var activityCategory: UIActivity.Category {
        return .action
    }

    init(activityType: CustomActivityAction, url: URL) {
        appActivityType = activityType
        self.url = url
        super.init()
    }

    // Send to device is only available for URL that are files
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return !url.isFile
    }

    override func prepare(withActivityItems activityItems: [Any]) {
//        self.activityItems = activityItems
    }

    override func perform() {
        UIPasteboard.general.string = url.absoluteString
        activityDidFinish(true)
    }
}
