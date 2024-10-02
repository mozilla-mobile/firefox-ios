// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

extension NSItemProvider {
    var isText: Bool { return hasItemConformingToTypeIdentifier(UTType.text.identifier) }
    var isUrl: Bool { return hasItemConformingToTypeIdentifier(UTType.url.identifier) }

    func processText(completion: CompletionHandler?) {
        loadItem(forTypeIdentifier: UTType.text.identifier, options: nil, completionHandler: completion)
    }

    func processUrl(completion: CompletionHandler?) {
        loadItem(forTypeIdentifier: UTType.url.identifier, options: nil, completionHandler: completion)
    }
}

public struct ExtensionUtils {
    public enum ExtractedShareItem {
        case shareItem(ShareItem)
        case rawText(String)

        public func isUrlType() -> Bool {
            if case .shareItem = self {
                return true
            } else {
                return false
            }
        }
    }

    /// Look through the extensionContext for a url and title. Walks over all inputItems and then over all
    /// the attachments. Has a completionHandler because ultimately an XPC call to the sharing application is done.
    /// We can always extract a URL and sometimes a title. The favicon is currently just a placeholder, but
    /// future code can possibly interact with a web page to find a proper icon.
    /// If no URL is found, but a text provider *is*, then use the raw text as a fallback.
    public static func extractSharedItem(
        fromExtensionContext extensionContext: NSExtensionContext?,
        completionHandler: @escaping (ExtractedShareItem?, Error?) -> Void
    ) {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem]
        else {
            completionHandler(nil, nil)
            return
        }

        var textProviderFallback: NSItemProvider?

        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }

            for attachment in attachments {
                if attachment.isUrl {
                    let title = inputItem.attributedContentText?.string
                    attachment.processUrl { obj, err in
                        guard err == nil else {
                            completionHandler(nil, err)
                            return
                        }

                        guard let url = obj as? URL else {
                            completionHandler(
                                nil,
                                NSError(
                                    domain: "org.mozilla.fennec",
                                    code: 999,
                                    userInfo: ["Problem": "Non-URL result."]
                                )
                            )
                            return
                        }

                        let extracted = ExtractedShareItem.shareItem(
                            ShareItem(
                                url: url.absoluteString,
                                title: title
                            )
                        )
                        completionHandler(extracted, nil)
                    }

                    return
                }

                if attachment.isText {
                    textProviderFallback = attachment
                }
            }
        }

        // See if the text is URL-like enough to be an url, in particular, check if it has a valid TLD.
        @Sendable
        func textToUrl(_ text: String) -> URL? {
            guard text.contains(".") else { return nil }
            var text = text
            if !text.hasPrefix("http") {
                text = "http://" + text
            }
            let url = URL(string: text, invalidCharacters: false)
            return url?.publicSuffix != nil ? url : nil
        }

        if let textProvider = textProviderFallback {
            textProvider.processText { obj, err in
                guard err == nil, let text = obj as? String else {
                    completionHandler(nil, err)
                    return
                }

                if let url = textToUrl(text) {
                    let extracted = ExtractedShareItem.shareItem(ShareItem(url: url.absoluteString, title: nil))
                    completionHandler(extracted, nil)
                    return
                }

                let extracted = ExtractedShareItem.rawText(text)
                completionHandler(extracted, nil)
            }
        } else {
            completionHandler(nil, nil)
        }
    }
}
