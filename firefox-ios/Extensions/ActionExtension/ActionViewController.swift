// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Shared
import Common
import Localizations

class ActionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.alpha = 0

        getShareItem { [weak self] shareItem in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let shareItem = shareItem else {
                    self.finish(afterDelay: 0)
                    return
                }

                // Directly open Firefox without showing a sheet
                switch shareItem {
                case .shareItem(let item):
                    self.openFirefox(withUrl: item.url, isSearch: false)
                case .rawText(let text):
                    self.openFirefox(withUrl: text, isSearch: true)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Keep view invisible since we're opening Firefox directly
        view.alpha = 0
    }

    /// Extracts the shared item using the extension's helper.
    private func getShareItem(completion: @escaping (ExtensionUtils.ExtractedShareItem?) -> Void) {
        let context = extensionContext
        ExtensionUtils.extractSharedItem(fromExtensionContext: context) { [weak self] item, error in
            if let item = item, error == nil {
                completion(item)
            } else {
                completion(nil)
                DispatchQueue.main.async {
                    self?.extensionContext?.cancelRequest(withError: CocoaError(.keyValueValidation))
                }
            }
        }
    }

    /// Opens Firefox with the given URL or text.
    private func openFirefox(withUrl url: String, isSearch: Bool) {
        // Telemetry is handled in the app delegate that receives this event.
        let profile = BrowserProfile(localName: "profile")
        profile.prefs.setBool(true, forKey: PrefsKeys.AppExtensionTelemetryOpenUrl)

        func firefoxUrl(_ url: String) -> String {
            let encoded = url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics) ?? ""
            if isSearch {
                return "firefox://open-text?text=\(encoded)"
            }
            return "firefox://open-url?url=\(encoded)"
        }

        guard let url = URL(string: firefoxUrl(url)) else {
            finish(afterDelay: 0)
            return
        }

        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        while let current = responder {
            if #available(iOS 18.0, *) {
                if let application = responder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                    finish(afterDelay: 0)
                    return
                }
            } else {
                if current.responds(to: selectorOpenURL) {
                    current.perform(selectorOpenURL, with: url, afterDelay: 0)
                    finish(afterDelay: 0)
                    return
                }
            }

            responder = current.next
        }

        // If we couldn't open Firefox, finish anyway
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
