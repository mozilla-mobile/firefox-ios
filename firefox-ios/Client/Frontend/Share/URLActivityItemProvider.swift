// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UniformTypeIdentifiers
import Shared

class URLActivityItemProvider: UIActivityItemProvider, @unchecked Sendable {
    private struct ActivityIdentifiers {
        static let whatsApp = "net.whatsapp.WhatsApp.ShareExtension"
    }

    private static var isSentFromFirefoxTreatmentA: Bool {
        return LegacyFeatureFlagsManager.shared.isFeatureEnabled(.sentFromFirefoxTreatmentA, checking: .buildOnly)
    }

    private let url: URL
    private let allowSentFromFirefoxTreatment: Bool // FXIOS-9879 For the Sent from Firefox experiment
    private let whatsAppShareText: String // FXIOS-9879 For the Sent from Firefox experiment

    // We don't want to add this URL to Safari's Reading List
    static let excludedActivities = [
        UIActivity.ActivityType.addToReadingList,
    ]

    init(url: URL, allowSentFromFirefoxTreatment: Bool = false) {
        // If the user is sharing a reader mode URL, we must decode it so we don't share internal localhost URLs
        let parsedURL = url.isReaderModeURL
                        ? url.decodeReaderModeURL ?? url
                        : url

        self.url = parsedURL

        // FXIOS-9879 For the Sent from Firefox experiment
        self.allowSentFromFirefoxTreatment = allowSentFromFirefoxTreatment
        if URLActivityItemProvider.isSentFromFirefoxTreatmentA {
            whatsAppShareText = String.localizedStringWithFormat(.SentFromFirefox.SocialShare.ShareMessageA,
                                                                 parsedURL.absoluteString,
                                                                 AppName.shortName.rawValue,
                                                                 "https://mzl.la/4fOWPpd")
        } else {
            whatsAppShareText = String.localizedStringWithFormat(.SentFromFirefox.SocialShare.ShareMessageB,
                                                                 parsedURL.absoluteString,
                                                                 AppName.shortName.rawValue,
                                                                 "https://mzl.la/3YSUOl8")
        }

        super.init(placeholderItem: parsedURL)
    }

    override var placeholderItem: Any? {
        return url
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        if let activityType = activityType, URLActivityItemProvider.excludedActivities.contains(activityType) {
            return NSNull()
        } else if allowSentFromFirefoxTreatment, activityType?.rawValue == ActivityIdentifiers.whatsApp {
            // FXIOS-9879 For the Sent from Firefox experiment, we override sharing the URL to instead share text to WhatsApp
            return whatsAppShareText
        }

        return url
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        if allowSentFromFirefoxTreatment, activityType?.rawValue == ActivityIdentifiers.whatsApp {
            // FXIOS-9879 For the Sent from Firefox experiment, we override sharing the URL to instead share text to WhatsApp
            return UTType.plainText.identifier
        }

        return url.isFileURL ? UTType.fileURL.identifier : UTType.url.identifier
    }
}
