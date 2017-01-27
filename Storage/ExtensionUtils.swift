/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import MobileCoreServices

public struct ExtensionUtils {
    /// Look through the extensionContext for a url and title. Walks over all inputItems and then over all the attachments.
    /// Has a completionHandler because ultimately an XPC call to the sharing application is done.
    /// We can always extract a URL and sometimes a title. The favicon is currently just a placeholder, but
    /// future code can possibly interact with a web page to find a proper icon.
    public static func extractSharedItemFromExtensionContext(_ extensionContext: NSExtensionContext?, completionHandler: @escaping (ShareItem?, NSError?) -> Void) {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            completionHandler(nil, nil)
            return
        }

        for inputItem in inputItems {
            guard let attachments = inputItem.attachments as? [NSItemProvider] else { continue }

            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { obj, err in
                        guard err == nil else {
                            completionHandler(nil, err as NSError!)
                            return
                        }

                        guard let url = obj as? URL else {
                            completionHandler(nil, NSError(domain: "org.mozilla.fennec", code: 999, userInfo: ["Problem": "Non-URL result."]))
                            return
                        }

                        let title = inputItem.attributedContentText?.string
                        completionHandler(ShareItem(url: url.absoluteString, title: title, favicon: nil), nil)
                    }

                    return
                }
            }
        }

        completionHandler(nil, nil)
    }
}
