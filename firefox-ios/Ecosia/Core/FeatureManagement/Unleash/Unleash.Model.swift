// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Unleash {
    public struct Model: Codable {
        public var id = UUID()
        var toggles = Set<Toggle>()
        var updated = Date(timeIntervalSince1970: 0)
        var appVersion: String = ""
        var deviceRegion: String = ""
        public var etag: String = ""

        public subscript(_ name: Toggle.Name) -> Toggle? {
            toggles.first { $0.name == name.rawValue }
        }
    }

    public struct Toggle: Codable, Hashable {
        public enum Name: String {
            case brazeIntegration = "mob_ios_braze_integration"
            case configTest = "mob_ios_staging_config"
            case seedCounterNTP = "mob_ios_seed_counter_ntp"
            case nativeSRPVAnalytics = "mob_ios_native_srpv_analytics"
            case newsletterCard = "mob_ios_newsletter_card"
            case aiSearchMVP = "ai2-67-ai-search-mvp"
        }

        public let name: String
        public let enabled: Bool
        public let variant: Variant

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }

        public func hash(into: inout Hasher) {
            into.combine(name)
        }
    }

    public struct Variant: Codable {
        public let name: String
        public let enabled: Bool
        public let payload: Payload?
    }

    public struct Payload: Codable {
        public let type, value: String
    }

    struct FeatureResponse: Codable {
        let toggles: [Toggle]
    }
}
