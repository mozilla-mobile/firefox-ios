// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import MobileCoreServices
import WebKit
import UniformTypeIdentifiers

class ShareManager: NSObject, FeatureFlaggable {
    private weak var selectedTab: Tab?

    private let url: URL
    private let title: String?
    private var onePasswordExtensionItem: NSExtensionItem!
    private let browserFillIdentifier = "org.appextension.fill-browser-action"
    private let pocketIconExtension = "com.ideashower.ReadItLaterPro.AddToPocketExtension"
    private let pocketActionExtension = "com.ideashower.ReadItLaterPro.Action-Extension"

    private var excludingActivities: [UIActivity.ActivityType] {
        return [UIActivity.ActivityType.addToReadingList]
    }

    // Can be a file:// or http(s):// url
    init(url: URL, title: String? = nil, tab: Tab?) {
        self.url = url
        self.title = title
        self.selectedTab = tab
    }

    func createActivityViewController(
        _ webView: WKWebView? = nil,
        completionHandler: @escaping (
            _ completed: Bool,
            _ activityType: UIActivity.ActivityType?
        ) -> Void
    ) -> UIActivityViewController {
        var activityItems = getActivityItems(url: url)
        // Note: webview is required for adding websites to the iOS home screen
        if #available(iOS 16.4, *), let webView = webView {
            activityItems.append(webView)
        }
        let appActivities = getApplicationActivities()
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: appActivities
        )

        activityViewController.excludedActivityTypes = excludingActivities

        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            guard completed else {
                completionHandler(completed, activityType)
                return
            }

            // Add telemetry for Pocket activityType
            if activityType?.rawValue == self.pocketIconExtension {
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .shareSheet,
                                             value: .sharePocketIcon,
                                             extras: nil)
            } else if activityType?.rawValue == self.pocketActionExtension {
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .shareSheet,
                                             value: .shareSaveToPocket,
                                             extras: nil)
            }

            completionHandler(completed, activityType)
        }

        return activityViewController
    }

    /// Get the data to be shared if the URL is a file we will share just the url if not we prepare
    /// UIPrintInfo to get the option to print the page and tab URL and title
    /// - Parameter url: url from the selected tab
    /// - Returns: An array of elements to be shared
    private func getActivityItems(url: URL) -> [Any] {
        // If url is file return only url to be shared
        guard !url.isFileURL else { return [url] }

        var activityItems = [Any]()

        // Add the title (if it exists)
        if let title = self.title {
            activityItems.append(title)
        }

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = (url.absoluteString as NSString).lastPathComponent
        printInfo.outputType = .general
        activityItems.append(printInfo)

        // when tab is not loaded (webView != nil) don't show print activity
        if let tab = selectedTab, tab.webView != nil {
            activityItems.append(
                TabPrintPageRenderer(
                    tabDisplayTitle: tab.displayTitle,
                    tabURL: tab.url,
                    webView: tab.webView
                )
            )
        }

        if let title = selectedTab?.title {
            activityItems.append(TitleActivityItemProvider(title: title))
        }
        activityItems.append(self)

        return activityItems
    }

    private func getApplicationActivities() -> [UIActivity] {
        var appActivities = [UIActivity]()

        let sendToDeviceActivity = SendToDeviceActivity(activityType: .sendToDevice, url: url)
        appActivities.append(sendToDeviceActivity)

        return appActivities
    }
}

extension ShareManager: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        if isPasswordManager(activityType: activityType) {
            return onePasswordExtensionItem
        } else if isOpenByCopy(activityType: activityType) {
            return url
        }

        // Return the URL for the selected tab. If we are in reader view then decode
        // it so that we copy the original and not the internal localhost one.
        return url.isReaderModeURL ? url.decodeReaderModeURL : url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        if isPasswordManager(activityType: activityType) {
            return browserFillIdentifier
        } else if isOpenByCopy(activityType: activityType) {
            return url.isFileURL ? UTType.fileURL.identifier : UTType.url.identifier
        }

        return activityType == nil ? browserFillIdentifier : UTType.url.identifier
    }

    private func isPasswordManager(activityType: UIActivity.ActivityType?) -> Bool {
        guard let activityType = activityType?.rawValue else { return false }
        // A 'password' substring covers the most cases, such as pwsafe and 1Password.
        // com.agilebits.onepassword-ios.extension
        // com.app77.ios.pwsafe2.find-login-action-password-actionExtension
        // If your extension's bundle identifier does not contain "password", simply submit a pull request
        // by adding your bundle identifier.
        return (activityType.contains("password"))
            || (activityType == "com.lastpass.ilastpass.LastPassExt")
            || (activityType == "in.sinew.Walletx.WalletxExt")
            || (activityType == "com.8bit.bitwarden.find-login-action-extension")
            || (activityType == "me.mssun.passforios.find-login-action-extension")
    }

    private func isOpenByCopy(activityType: UIActivity.ActivityType?) -> Bool {
        guard let activityType = activityType?.rawValue else { return false }
        return activityType.lowercased().contains("remoteopeninapplication-bycopy")
    }
}
