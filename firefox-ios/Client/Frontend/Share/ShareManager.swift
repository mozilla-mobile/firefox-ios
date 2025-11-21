// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MobileCoreServices
import WebKit
import UniformTypeIdentifiers

class ShareManager: NSObject, FeatureFlaggable {
    private struct ActivityIdentifiers {
        static let pocketIconExtension = "com.ideashower.ReadItLaterPro.AddToPocketExtension"
        static let pocketActionExtension = "com.ideashower.ReadItLaterPro.Action-Extension"
        static let whatsApp = "net.whatsapp.WhatsApp.ShareExtension"
    }

    // Black list for activities to which we don't want to share
    private static let excludingActivities: [UIActivity.ActivityType] = [
        UIActivity.ActivityType.addToReadingList
    ]

    @MainActor
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

        activityViewController.completionWithItemsHandler = { activityType, completed, _, _ in
            completionHandler(completed, activityType)
        }

        return activityViewController
    }

    @MainActor
    static func getActivityItems(
        forShareType shareType: ShareType,
        withExplicitShareMessage explicitShareMessage: ShareMessage?
    ) -> [Any] {
        var activityItems: [Any] = []

        switch shareType {
        case .file(let fileURL, _):
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
            let isSentFromFirefoxEnabled = LegacyFeatureFlagsManager.shared.isFeatureEnabled(
                .sentFromFirefox,
                checking: .buildAndUser
            )
            activityItems.append(
                URLActivityItemProvider(
                    url: siteURL,
                    allowSentFromFirefoxTreatment: isSentFromFirefoxEnabled
                )
            )

            // For websites, we also want to offer a few additional activity items besides the URL, like printing the
            // webpage or adding a website to the iOS home screen

            // Only show the print activity if the tab's webview is loaded
            if tab.webView != nil {
                let viewPrintFormatter = tab.webView?.viewPrintFormatter()
                activityItems.append(
                    TabPrintPageRenderer(
                        tabDisplayTitle: tab.displayTitle,
                        tabURL: tab.url,
                        viewPrintFormatter: viewPrintFormatter
                    )
                )
            }

            // Add the webview for an option to add a website to the iOS home screen
            if #available(iOS 16.4, *), let webView = tab.webView {
                activityItems.append(HomePageActivity(url: webView.url,
                                                      title: webView.title))
            }

            if let explicitShareMessage {
                activityItems.append(TitleSubtitleActivityItemProvider(shareMessage: explicitShareMessage))
            } else {
                // For feature parity with Safari, we use this provider to decide to which apps we should (or should not)
                // share a display title and/or subject line
                activityItems.append(
                    TitleActivityItemProvider(
                        title: tab.displayTitle,
                        applySentFromFirefoxTreatment: isSentFromFirefoxEnabled
                    )
                )
            }
        }

        // For all share types, record basic telemetry
        activityItems.append(
            ShareTelemetryActivityItemProvider(
                shareTypeName: shareType.typeName,
                shareMessage: explicitShareMessage
            )
        )

        return activityItems
    }

    @MainActor
    static func getApplicationActivities(forShareType shareType: ShareType) -> [UIActivity] {
        var appActivities = [UIActivity]()

        // Set up the "Send to Device" activity, which shares URLs between a Firefox account user's synced devices. We can
        // only share URLs to real websites, not internal `file://` URLs.
        switch shareType {
        case .file(_, let remoteURL):
            // Some downloaded files may have an associated remote URL (if the file was just downloaded in the tab).
            // Files which are shared from the Downloads Panel will NOT have any associated remote URL (we don't store that
            // history).
            if let remoteURL {
                appActivities.append(SendToDeviceActivity(activityType: .sendToDevice, url: remoteURL))
            }
        default:
            appActivities.append(SendToDeviceActivity(activityType: .sendToDevice, url: shareType.wrappedURL))
        }

        return appActivities
    }
}
