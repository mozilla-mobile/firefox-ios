/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import MobileCoreServices

public struct ExtensionUtils {
    /// Look through the extensionContext for a url and title. Walks over all inputItems and then over all the attachments.
    /// Has a completionHandler because ultimately an XPC call to the sharing application is done.
    /// We can always extract a URL and sometimes a title. The favicon is currently just a placeholder, but future code can possibly interact with a web page to find a proper icon.
    public static func extractSharedItemFromExtensionContext(extensionContext: NSExtensionContext?, completionHandler: (ShareItem?, NSError!) -> Void) {
        if extensionContext != nil {
            if let inputItems: [NSExtensionItem] = extensionContext!.inputItems as? [NSExtensionItem] {
                for inputItem in inputItems {
                    if let attachments = inputItem.attachments as? [NSItemProvider] {
                        for attachment in attachments {
                            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                                attachment.loadItemForTypeIdentifier(kUTTypeURL as String, options: nil, completionHandler: { (obj, err) -> Void in
                                    if err != nil {
                                        completionHandler(nil, err)
                                    } else {
                                        let title = inputItem.attributedContentText?.string as String?
                                        if let url = obj as? NSURL {
                                            completionHandler(ShareItem(url: url.absoluteString, title: title, favicon: nil), nil)
                                        } else {
                                            completionHandler(nil, NSError(domain: "org.mozilla.fennec", code: 999, userInfo: ["Problem": "Non-URL result."]))
                                        }
                                    }
                                })
                                return
                            }
                        }
                    }
                }
            }
        }
        completionHandler(nil, nil)
    }
}
