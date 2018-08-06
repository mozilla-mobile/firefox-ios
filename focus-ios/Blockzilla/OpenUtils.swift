/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry
import OnePasswordExtension

class OpenUtils: NSObject {
    private let app = UIApplication.shared
    fileprivate let selectedURL: URL
    fileprivate let browserFillIdentifier = "org.appextension.fill-browser-action"
    fileprivate let webViewController: WebViewController

    init(url: URL, webViewController: WebViewController) {
        self.selectedURL = url
        self.webViewController = webViewController
    }

    func buildShareViewController(url: URL) -> UIActivityViewController {
        var activityItems: [Any] = [url]
        
        activityItems.append(self)

        let printFormatter = UIPrintFormatter()
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = url.absoluteString
        printInfo.outputType = .general
        activityItems.append(printInfo)
        
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        activityItems.append(renderer)

        let shareController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

        // This needs to be ready by the time the share menu has been displayed and
        // activityViewController(activityViewController:, activityType:) is called,
        // which is after the user taps the button. So a million cycles away.
        findLoginExtensionItem()

        shareController.popoverPresentationController?.permittedArrowDirections = .up
        shareController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            if !completed {
                return
            }
            
            // Bug 1392418 - When copying a url using the share extension there are 2 urls in the pasteboard.
            // Make sure the pasteboard only has one url.
            if let url = UIPasteboard.general.urls?.first {
                UIPasteboard.general.urls = [url]
            }
            
            if self.isPasswordManagerActivityType(activityType.map { $0.rawValue }) {
                Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.autofill)
                if let logins = returnedItems {
                    self.fillPasswords(returnedItems: logins as [AnyObject])
                    Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.autofill)
                }
            }
        }
        return shareController
    }
}

extension OpenUtils: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return selectedURL
    }
    
    // IMPORTANT: This method needs Swift compiler optimization DISABLED to prevent a nasty
    // crash from happening in release builds. It seems as though the check for `nil` may
    // get removed by the optimizer which leads to a crash when that happens.
    @_semantics("optimize.sil.never") func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // activityType actually is nil sometimes (in the simulator at least)
        if activityType != nil && isPasswordManagerActivityType(activityType?.rawValue) {
            return webViewController.onePasswordExtensionItem
        } else {
            return selectedURL
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        if let type = activityType, isPasswordManagerActivityType(type.rawValue) {
            return browserFillIdentifier
        }
        return activityType == nil ? browserFillIdentifier : kUTTypeURL as String
    }
}

private extension OpenUtils {
    func isPasswordManagerActivityType(_ activityType: String?) -> Bool {
        // A 'password' substring covers the most cases, such as pwsafe and 1Password.
        // com.agilebits.onepassword-ios.extension
        // com.app77.ios.pwsafe2.find-login-action-password-actionExtension
        // If your extension's bundle identifier does not contain "password", simply submit a pull request by adding your bundle identifier.
        guard let activityType = activityType else { return false }
        return (activityType.range(of: "password") != nil)
            || (activityType == "com.lastpass.ilastpass.LastPassExt")
            || (activityType == "in.sinew.Walletx.WalletxExt")
            || (activityType == "com.8bit.bitwarden.find-login-action-extension")
        
    }
    
    func findLoginExtensionItem() {
        // Add 1Password to share sheet
        webViewController.createPasswordManagerExtensionItem()
    }
    
    func fillPasswords(returnedItems: [AnyObject]) {
        webViewController.fillPasswords(returnedItems: returnedItems)
    }
}
