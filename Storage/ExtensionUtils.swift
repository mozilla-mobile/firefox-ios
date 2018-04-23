/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import MobileCoreServices

extension NSItemProvider {
    var isText: Bool { return hasItemConformingToTypeIdentifier(String(kUTTypeText)) }
    var isUrl: Bool { return hasItemConformingToTypeIdentifier(String(kUTTypeURL)) }

    func processText(completion: CompletionHandler?) {
        loadItem(forTypeIdentifier: String(kUTTypeText), options: nil, completionHandler: completion)
    }

    func processUrl(completion: CompletionHandler?) {
        loadItem(forTypeIdentifier: String(kUTTypeURL), options: nil, completionHandler: completion)
    }
}

public struct ExtensionUtils {
    /// Look through the extensionContext for a url and title. Walks over all inputItems and then over all the attachments.
    /// Has a completionHandler because ultimately an XPC call to the sharing application is done.
    /// We can always extract a URL and sometimes a title. The favicon is currently just a placeholder, but
    /// future code can possibly interact with a web page to find a proper icon.
    public static func extractSharedItemFromExtensionContext(_ extensionContext: NSExtensionContext?, completionHandler: @escaping (ShareItem?, Error?) -> Void) {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            completionHandler(nil, nil)
            return
        }

        var textProviderFallback: NSItemProvider?

        for inputItem in inputItems {
            guard let attachments = inputItem.attachments as? [NSItemProvider] else { continue }

            for attachment in attachments {
                if attachment.isUrl {
                    attachment.processUrl { obj, err in
                        guard err == nil else {
                            completionHandler(nil, err)
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

                if attachment.isText {
                    if textProviderFallback != nil {
                        NSLog("\(#function) More than one text attachment, only one expected.")
                    }
                    textProviderFallback = attachment
                }
            }
        }

        if let textProvider = textProviderFallback {
            textProvider.processText { obj, err in
                guard err == nil, let text = obj as? String else {
                    completionHandler(nil, err)
                    return
                }

                if let url = URL(string: text) {
                    completionHandler(ShareItem(url: url.absoluteString, title: nil, favicon: nil), nil)
                } else {

                    completionHandler(nil, nil)
                    // maybe do a text search urlScheme://open-text?text=\(query)
                }

            }
            return
        }

        completionHandler(nil, nil)
    }
}
