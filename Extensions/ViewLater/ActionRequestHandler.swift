/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import MobileCoreServices

import Shared
import Storage

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        ExtensionUtils.extractSharedItemFromExtensionContext(context, completionHandler: {
            (item, error) -> Void in
            if let item = item, error == nil && item.isShareable {
                let profile = BrowserProfile(localName: "profile", app: nil)
                profile.queue.addToQueue(item).uponQueue(dispatch_get_main_queue()) { _ in
                    profile.shutdown()
                    context.completeRequestReturningItems([], completionHandler: nil)
                }
            }
        })
    }
}
