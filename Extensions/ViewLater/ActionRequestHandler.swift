/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import MobileCoreServices

import Shared
import Storage

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequestWithExtensionContext(context: NSExtensionContext) {
        ExtensionUtils.extractSharedItem(fromExtensionContext: context, completionHandler: {
            (item, error) -> Void in
            if let item = item where error == nil && item.isShareable {
                let profile = BrowserProfile(localName: "profile", app: nil)
                profile.queue.addToQueue(item)
            }

            context.completeRequestReturningItems([], completionHandler: nil)
        })
    }
}
