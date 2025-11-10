// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Shared

class ActionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.alpha = 0

        getShareItem { [weak self] shareItem in
            guard let self = self else { return }

            guard let shareItem = shareItem else {
                self.finish(afterDelay: 0)
                return
            }

            switch shareItem {
            case .shareItem(let item):
                self.openFirefox(withUrl: item.url, isSearch: false)
            case .rawText(let text):
                self.openFirefox(withUrl: text, isSearch: true)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.alpha = 0
    }

    private func getShareItem(completion: @escaping (ExtensionUtils.ExtractedShareItem?) -> Void) {
        ExtensionUtils.extractSharedItem(fromExtensionContext: extensionContext) { [weak self] item, error in
            DispatchQueue.main.async {
                if let item = item, error == nil {
                    completion(item)
                } else {
                    completion(nil)
                    let errorToReport = error ?? CocoaError(.keyValueValidation)
                    self?.extensionContext?.cancelRequest(withError: errorToReport)
                }
            }
        }
    }

    private func openFirefox(withUrl urlString: String, isSearch: Bool) {
        let profile = BrowserProfile(localName: "profile")
        profile.prefs.setBool(true, forKey: PrefsKeys.AppExtensionTelemetryOpenUrl)

        guard let encodedContent = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            finish(afterDelay: 0)
            return
        }

        let firefoxUrlString = isSearch
            ? "firefox://open-text?text=\(encodedContent)"
            : "firefox://open-url?url=\(encodedContent)"

        guard let firefoxUrl = URL(string: firefoxUrlString) else {
            finish(afterDelay: 0)
            return
        }

        var responder = self as UIResponder?

        if #available(iOS 18.0, *) {
            while let current = responder {
                if let application = current as? UIApplication {
                    application.open(firefoxUrl, options: [:], completionHandler: nil)
                    finish(afterDelay: 0)
                    return
                }
                responder = current.next
            }
        } else {
            let selectorOpenURL = sel_registerName("openURL:")
            while let current = responder {
                if current.responds(to: selectorOpenURL) {
                    current.perform(selectorOpenURL, with: firefoxUrl, afterDelay: 0)
                    finish(afterDelay: 0)
                    return
                }
                responder = current.next
            }
        }

        finish(afterDelay: 0)
    }

    /// Fades out the UI and completes the extension request.
    func finish(afterDelay delay: TimeInterval) {
        UIView.animate(withDuration: 0.2, delay: delay, options: [], animations: {
            self.view.alpha = 0
        }) { _ in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
