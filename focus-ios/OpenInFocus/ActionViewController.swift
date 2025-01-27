/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Social
import MobileCoreServices

extension NSObject {
    func callSelector(selector: Selector, object: AnyObject?, delay: TimeInterval) {
        let delay = delay * Double(NSEC_PER_SEC)
        let time = DispatchTime(uptimeNanoseconds: UInt64(delay))
        DispatchQueue.main.asyncAfter(deadline: time) {
            Thread.detachNewThreadSelector(selector, toTarget: self, with: object)
        }
    }
}

extension NSURL {
    var encodedUrl: String? { return absoluteString?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics) }
}

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

class ActionViewController: SLComposeServiceViewController {
    private var isKlar: Bool { return (Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String).contains("Klar") }
    private var urlScheme: String { return isKlar ? "firefox-klar" : "firefox-focus" }

    override func isContentValid() -> Bool { return true }
    override func didSelectPost() { return }

    func focusUrl(url: String) -> NSURL? {
        return NSURL(string: "\(self.urlScheme)://open-url?url=\(url)")
    }

    func textUrl(text: String) -> NSURL? {
        guard let query = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return NSURL(string: "\(self.urlScheme)://open-text?text=\(query)")
    }

    override func configurationItems() -> [Any]! {
        let inputItems: [NSExtensionItem] = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        var urlProvider: NSItemProvider?
        var textProvider: NSItemProvider?

        // Look for the first URL the host application is sharing.
        // If there isn't a URL grab the first text item
        for item: NSExtensionItem in inputItems {
            let attachments: [NSItemProvider] = item.attachments ?? []
            for attachment in attachments {
                if urlProvider == nil && attachment.isUrl {
                    urlProvider = attachment
                } else if textProvider == nil && attachment.isText {
                    textProvider = attachment
                }
            }
        }

        // If a URL is found, process it. Otherwise we will try to convert
        // the text item to a URL falling back to sending just the text.
        if let urlProvider = urlProvider {
            urlProvider.processUrl { [weak self] (urlItem, error) in
                guard let self = self else { return }
                Task { @MainActor in
                    guard let url = (urlItem as? NSURL)?.encodedUrl, let focusUrl = self.focusUrl(url: url) else { self.cancel(); return }
                    self.handleUrl(focusUrl)
                }
            }
        } else if let textProvider = textProvider {
            textProvider.processText { [weak self] (textItem, error) in
                guard let self = self else { return }
                Task { @MainActor in
                    guard let text = textItem as? String else { self.cancel(); return }
                    guard let focusUrl = self.textUrl(text: text) else { self.cancel(); return }
                    self.handleUrl(focusUrl)
                }
            }
        } else {
            // If no item was processed. Cancel the share action to prevent the
            // extension from locking the host application due to the hidden
            // ViewController
            self.cancel()
        }

        return []
    }

    private func handleUrl(_ url: NSURL) {
        // From http://stackoverflow.com/questions/24297273/openurl-not-work-in-action-extension
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        while responder != nil {
            if #available(iOS 18.0, *) {
                if let application = responder as? UIApplication {
                    application.open(url as URL, options: [:], completionHandler: nil)
                }
            } else {
                if responder!.responds(to: selectorOpenURL) {
                    responder!.callSelector(selector: selectorOpenURL, object: url, delay: 0)
                }
            }

            responder = responder!.next
        }
        finish()
    }

    override func viewDidAppear(_ animated: Bool) {
        // Stop keyboard from showing
        textView.resignFirstResponder()
        textView.isEditable = false

        super.viewDidAppear(animated)
    }

    override func willMove(toParent parent: UIViewController?) {
        view.alpha = 0
    }
}

extension ActionViewController {
    func finish(afterDelay: TimeInterval = 0) {
        UIView.animate(
            withDuration: 0.2,
            delay: afterDelay,
            options: [],
            animations: {
                self.view.alpha = 0
            },
            completion: { _ in
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        )
    }
}
