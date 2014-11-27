// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import MobileCoreServices

struct ExtensionUtils {
    /// Small structure to encapsulate all the possible data that we can get from an application sharing a web page or a url.
    struct ShareItem {
        var title: String?
        var url: String
        var icon: String? // TODO: This is just a placeholder until we figure out how to do this.
    }

    /// Look through the extensionContext for a url and title. Walks over all inputItems and then over all the attachments.
    /// Has a completionHandler because ultimately an XPC call to the sharing application is done.
    /// We can always extract a URL and sometimes a title. The favicon is currently just a placeholder, but future code can possibly interact with a web page to find a proper icon.
    static func extractSharedItemFromExtensionContext(extensionContext: NSExtensionContext?, completionHandler: (ShareItem?, NSError!) -> Void) {
        if extensionContext != nil {
            if let inputItems : [NSExtensionItem] = extensionContext!.inputItems as? [NSExtensionItem] {
                for inputItem in inputItems {
                    if let attachments = inputItem.attachments as? [NSItemProvider] {
                        for attachment in attachments {
                            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL) {
                                attachment.loadItemForTypeIdentifier(kUTTypeURL, options: nil, completionHandler: { (obj, err) -> Void in
                                    if err != nil {
                                        completionHandler(nil, err)
                                    } else {
                                        let title = inputItem.attributedContentText?.string as String?
                                        let url = obj as NSURL
                                        completionHandler(ShareItem(title: title, url: url.absoluteString!, icon: nil), nil)
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
    
    /// Return the shared identifier to be used with for example background http requests.
    /// This is in ExtensionUtils because I think we can eventually do something smart here
    /// to let the extension discover this value at runtime. (It is based on the app
    ///  identifier, which will change for production and test builds)
    ///
    /// :returns: the shared container identifier
    static func sharedContainerIdentifier() -> String {
        return "group.org.allizom.Client"
    }
}