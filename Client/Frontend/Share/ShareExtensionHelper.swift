/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private let log = Logger.browserLogger

class ShareExtensionHelper: NSObject {
    private weak var selectedTab: Browser?

    private let selectedURL: NSURL
    private var onePasswordExtensionItem: NSExtensionItem!
    private let activities: [UIActivity]

    init(url: NSURL, tab: Browser?, activities: [UIActivity]) {
        self.selectedURL = url
        self.selectedTab = tab
        self.activities = activities
    }

    func createActivityViewController(completionHandler: (Bool) -> Void) -> UIActivityViewController {
        var activityItems = [AnyObject]()

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = selectedTab?.url?.absoluteString ?? selectedURL.absoluteString
        printInfo.outputType = .General
        activityItems.append(printInfo)

        if let tab = selectedTab {
            activityItems.append(BrowserPrintPageRenderer(browser: tab))
        }

        if let title = selectedTab?.title {
            activityItems.append(TitleActivityItemProvider(title: title))
        }
        activityItems.append(self)

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: activities)

        // Hide 'Add to Reading List' which currently uses Safari.
        // We would also hide View Later, if possible, but the exclusion list doesn't currently support
        // third-party activity types (rdar://19430419).
        activityViewController.excludedActivityTypes = [
            UIActivityTypeAddToReadingList,
        ]

        // This needs to be ready by the time the share menu has been displayed and
        // activityViewController(activityViewController:, activityType:) is called,
        // which is after the user taps the button. So a million cycles away.
        if (ShareExtensionHelper.isPasswordManagerExtensionAvailable()) {
            findLoginExtensionItem()
        }

        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            if !completed {
                completionHandler(completed)
                return
            }

            if self.isPasswordManagerActivityType(activityType) {
                if let logins = returnedItems {
                    self.fillPasswords(logins)
                }
            }

            completionHandler(completed)
        }
        return activityViewController
    }
}

extension ShareExtensionHelper: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        if let displayURL = selectedTab?.displayURL {
            return displayURL
        }
        return selectedURL
    }

    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        if isPasswordManagerActivityType(activityType) {
            return onePasswordExtensionItem
        } else {
            // Return the URL for the selected tab. If we are in reader view then decode
            // it so that we copy the original and not the internal localhost one.
            if let url = selectedTab?.displayURL where ReaderModeUtils.isReaderModeURL(url) {
                return ReaderModeUtils.decodeURL(url)
            }
            return selectedTab?.displayURL ?? selectedURL
        }
    }

    func activityViewController(activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: String?) -> String {
        // Because of our UTI declaration, this UTI now satisfies both the 1Password Extension and the usual NSURL for Share extensions.
        return "org.appextension.fill-browser-action"
    }
}

private extension ShareExtensionHelper {
    static func isPasswordManagerExtensionAvailable() -> Bool {
        return OnePasswordExtension.sharedExtension().isAppExtensionAvailable()
    }

    func isPasswordManagerActivityType(activityType: String?) -> Bool {
        if (!ShareExtensionHelper.isPasswordManagerExtensionAvailable()) {
            return false
        }
        // A 'password' substring covers the most cases, such as pwsafe and 1Password.
        // com.agilebits.onepassword-ios.extension
        // com.app77.ios.pwsafe2.find-login-action-password-actionExtension
        // If your extension's bundle identifier does not contain "password", simply submit a pull request by adding your bundle identifier.
        return (activityType?.rangeOfString("password") != nil)
            || (activityType == "com.lastpass.ilastpass.LastPassExt")

    }

    func findLoginExtensionItem() {
        guard let selectedWebView = selectedTab?.webView else {
            return
        }

        // Add 1Password to share sheet
        OnePasswordExtension.sharedExtension().createExtensionItemForWebView(selectedWebView, completion: {(extensionItem, error) -> Void in
            if extensionItem == nil {
                log.error("Failed to create the password manager extension item: \(error).")
                return
            }

            // Set the 1Password extension item property
            self.onePasswordExtensionItem = extensionItem
        })
    }

    func fillPasswords(returnedItems: [AnyObject]) {
        guard let selectedWebView = selectedTab?.webView else {
            return
        }

        OnePasswordExtension.sharedExtension().fillReturnedItems(returnedItems, intoWebView: selectedWebView, completion: { (success, returnedItemsError) -> Void in
            if !success {
                log.error("Failed to fill item into webview: \(returnedItemsError).")
            }
        })
    }
}
