// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum CustomActivityAction {
    case sendToDevice
    case copyLink

    var title: String {
        switch self {
        case .sendToDevice:
            return .ShareSheet.SendToDeviceButtonTitle
        case .copyLink:
            return .ShareSheet.CopyButtonTitle
        }
    }

    var image: UIImage? {
        switch self {
        case .sendToDevice:
            return UIImage(named: ImageIdentifiers.sendToDevice)
        case .copyLink:
            return UIImage(named: ImageIdentifiers.copyLink)
        }
    }

    var actionType: UIActivity.ActivityType {
        var activityType: String
        switch self {
        case .sendToDevice:
            activityType = ".sendToDevice"
        case .copyLink:
            activityType = ".copyLink"
        }
        let bundle = Bundle.main.bundleIdentifier
        return UIActivity.ActivityType(rawValue: "\(bundle!)\(activityType)")
    }
}

