// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import MobileCoreServices
import WebKit
import UniformTypeIdentifiers

class ShareManager: NSObject, FeatureFlaggable {
    // TODO: FXIOS-10582 not the real URL we want to use, those are still being finalized
    static let downloadFirefoxAppStoreURL = URL(string: "https://mzl.la/3NDxAIS")!

    private struct ActivityIdentifiers {
        static let browserFill = "org.appextension.fill-browser-action"
        static let pocketIconExtension = "com.ideashower.ReadItLaterPro.AddToPocketExtension"
        static let pocketActionExtension = "com.ideashower.ReadItLaterPro.Action-Extension"
        // FIXME: Should this be com.apple.UIKit.activity.RemoteOpenInApplication-ByCopy ?
        static let isOpenByCopy = "remoteopeninapplication-bycopy"
        static let whatsApp = "net.whatsapp.WhatsApp.ShareExtension"
    }

    // Black list for activities to which we don't want to share
    private static let excludingActivities: [UIActivity.ActivityType] = [
        UIActivity.ActivityType.addToReadingList
    ]

    static func createActivityViewController(
        shareType: ShareType,
        shareMessage: ShareMessage?,
        completionHandler: @escaping (
            _ completed: Bool,
            _ activityType: UIActivity.ActivityType?
        ) -> Void
    ) -> UIActivityViewController {
        let activityItems = getActivityItems(forShareType: shareType, withExplicitShareMessage: shareMessage)
        let appActivities = getApplicationActivities(forShareType: shareType)

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
            if activityType?.rawValue == ActivityIdentifiers.pocketIconExtension {
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .shareSheet,
                                             value: .sharePocketIcon,
                                             extras: nil)
            } else if activityType?.rawValue == ActivityIdentifiers.pocketActionExtension {
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

    static func getActivityItems(
        forShareType shareType: ShareType,
        withExplicitShareMessage explicitShareMessage: ShareMessage?
    ) -> [Any] {
        var activityItems: [Any] = []

        switch shareType {
        case .file(let fileURL):
            activityItems.append(URLActivityItemProvider(url: fileURL))

            if let explicitShareMessage {
                activityItems.append(TitleSubtitleActivityItemProvider(shareMessage: explicitShareMessage))
            }

        case .site(let siteURL):
            activityItems.append(URLActivityItemProvider(url: siteURL))

            // For websites shared from a place without a webview (e.g. bookmarks), we don't actually have webview to offer
            // any advanced information (like title, printing, sent to the iOS home screen, etc.)
            if let explicitShareMessage {
                activityItems.append(TitleSubtitleActivityItemProvider(shareMessage: explicitShareMessage))
            }

        case .tab(let siteURL, let tab):
            // For websites, we also want to offer a few additional activity items besides the URL, like printing the
            // webpage or adding a website to the iOS home screen
            activityItems.append(URLActivityItemProvider(url: siteURL))

            // FIXME: Check for reader mode URLs?
            //            // Return the URL for the selected tab. If we are in reader view then decode
            //            // it so that we copy the original and not the internal localhost one.
            //            return url.isReaderModeURL ? url.decodeReaderModeURL : url

            // Only show the print activity if the tab's webview is loaded
            if tab.webView != nil {
                activityItems.append(
                    TabPrintPageRenderer(
                        tabDisplayTitle: tab.displayTitle,
                        tabURL: tab.url,
                        webView: tab.webView
                    )
                )
            }

            // Add the webview for an option to add a website to the iOS home screen
            if #available(iOS 16.4, *), let webView = tab.webView {
                activityItems.append(webView)
            }

            if let explicitShareMessage {
                activityItems.append(TitleSubtitleActivityItemProvider(shareMessage: explicitShareMessage))
            } else {
                // For feature parity with Safari, we use this provider to decide to which apps we should (or should not)
                // share a display title and/or subject line
                activityItems.append(TitleActivityItemProvider(title: tab.displayTitle))
            }
        }

        return activityItems
    }

    private static func getApplicationActivities(forShareType shareType: ShareType) -> [UIActivity] {
        var appActivities = [UIActivity]()

        if case .file(let url) = shareType {
            // Send to device is only available for files
            appActivities.append(SendToDeviceActivity(activityType: .sendToDevice, url: url))
        }

        return appActivities
    }
}
