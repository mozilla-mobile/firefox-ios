/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Social
import MobileCoreServices

extension NSObject {
    func callSelector(selector: Selector, object: AnyObject?, delay: TimeInterval) {
        let delay = delay * Double(NSEC_PER_SEC)
        let time = DispatchTime.init(uptimeNanoseconds: UInt64(delay))
        DispatchQueue.main.asyncAfter(deadline: time) {
            Thread.detachNewThreadSelector(selector, toTarget:self, with: object)
        }
    }
}

class ActionViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        return
    }

    override func configurationItems() -> [Any]! {
        let item: NSExtensionItem = extensionContext!.inputItems[0] as! NSExtensionItem
        let itemProvider: NSItemProvider = item.attachments![0] as! NSItemProvider
        let type = kUTTypeURL as String

        if itemProvider.hasItemConformingToTypeIdentifier(type) {
            itemProvider.loadItem(forTypeIdentifier: type, options: nil, completionHandler: {
                (urlItem, error) in

                guard let url = (urlItem as! NSURL).absoluteString?.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.alphanumerics),
                    let focusUrl = NSURL(string: "firefox-focus://open-url?url=\(url)") else { return }

                // From http://stackoverflow.com/questions/24297273/openurl-not-work-in-action-extension
                var responder = self as UIResponder?
                let selectorOpenURL = sel_registerName("openURL:")
                while (responder != nil) {
                    if responder!.responds(to: selectorOpenURL) {
                        responder!.callSelector(selector: selectorOpenURL!, object: focusUrl, delay: 0)
                    }

                    responder = responder!.next
                }

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))) {
                    self.cancel()
                }
            })
        }

        return []
    }

    override func viewDidAppear(_ animated: Bool) {
        // Stop keyboard from showing
        textView.resignFirstResponder()
        textView.isEditable = false

        super.viewDidAppear(animated)
    }

    override func willMove(toParentViewController parent: UIViewController?) {
        view.alpha = 0
    }
}
