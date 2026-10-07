// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct InAppMessagingManifest: Codable {
    let schemaVersion: Int
    let messages: [InAppMessage]
}

struct InAppMessage: Codable, Identifiable, Hashable {
    let id: String
    let surface: Surface
    let content: Content
    let targeting: Targeting?
    let priority: Int
    let maxImpressions: Int?

    enum Surface: String, Codable {
        case banner
        case modal
        case newTabCard
        case webview
    }

    struct Content: Codable, Hashable {
        let title: String?
        let body: String?
        let ctaLabel: String?
        let ctaAction: CTAAction?
        let imageURL: String?
        let webviewURL: String?
        let dismissLabel: String?
    }

    struct CTAAction: Codable, Hashable {
        let type: ActionType
        let value: String

        enum ActionType: String, Codable {
            case openURL
            case deepLink
            case dismiss
        }
    }

    struct Targeting: Codable, Hashable {
        let locales: [String]?
        let minAppVersion: String?
        let maxAppVersion: String?
        let startDate: String?
        let endDate: String?
        let rolloutPercent: Double?
    }
}
