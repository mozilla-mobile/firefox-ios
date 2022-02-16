// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

// MARK: - Wallpaper Type
enum WallpaperType {
    case defaultBackground
    case themed(type: WallpaperCollectionType)
}

extension WallpaperType: Equatable {
    static func ==(lhs: WallpaperType, rhs: WallpaperType) -> Bool {
        switch (lhs, rhs) {
        case (.defaultBackground, .defaultBackground):
            return true
        case (let .themed(lhsString), let .themed(rhsString)):
            return lhsString == rhsString
        default:
            return false
        }
    }
}

extension WallpaperType: Codable {
    enum CodingKeys: CodingKey {
        case defaultBackground, themed
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .defaultBackground:
            try container.encode(true, forKey: .defaultBackground)
        case .themed(let type):
            try container.encode(type, forKey: .themed)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .defaultBackground:
            self = .defaultBackground
        case .themed:
            let themeType = try container.decode(WallpaperCollectionType.self,
                                                 forKey: .themed)
            self = .themed(type: themeType)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath,
                                      debugDescription: "Unabled to decode enum.")
            )
        }
    }
}

// MARK: - Collection types
/// This enum will outline all types of different wallpaper collections we currently
/// and may offer in the future. As such, there may be items here that are outdated.
enum WallpaperCollectionType: String, Codable {
    case firefox
    case firefoxOverlay
    case projectHouse
}

// MARK: - Wallpaper
struct Wallpaper: Codable, Equatable {
    // MARK: - Variables
    let name: String
    let type: WallpaperType
    let accessibilityLabel: String
    private let shipDate: Date?
    private let expiryDate: Date?
    private let locales: [String]?

    var telemetryMetadata: [String: String] {
        var metadata = [String: String]()

        metadata[TelemetryWrapper.EventExtraKey.wallpaperName.rawValue] = name

        if type == .defaultBackground {
            metadata[TelemetryWrapper.EventExtraKey.wallpaperType.rawValue] = "default"
        } else if case .themed(let collection) = type {
            metadata[TelemetryWrapper.EventExtraKey.wallpaperType.rawValue] = collection.rawValue
        }

        return metadata
    }

    var meetsDateAndLocaleCriteria: Bool {
        if type == .defaultBackground { return true }

        switch (checkDateEligibility(), locales) {
        case (true, nil): return true
        case (false, nil): return false
        case (false, _): return false
        case (true, let locales?): return locales.contains(Locale.current.identifier)
        }
    }

    // MARK: - Initializer
    init(named name: String,
         ofType type: WallpaperType,
         withAccessibiltyLabel accessibilityLabel: String,
         shippingOn appearanceDate: Date? = nil,
         expiringOn expiryDate: Date? = nil,
         limitedToLocale locale: [String]? = nil) {
        self.name = name
        self.accessibilityLabel = accessibilityLabel
        self.expiryDate = expiryDate
        self.shipDate = appearanceDate
        self.type = type
        self.locales = locale
    }

    // MARK: - Private helper methods
    /// Checks to make sure that, if the wallpaper has time limits, they are respected.
    private func checkDateEligibility() -> Bool {
        let currentDate = Date()

        switch (shipDate, expiryDate) {
        case (nil, nil): return true
        case (let ship?, nil): return currentDate >= ship
        case (nil, let expiry?): return currentDate <= expiry
        case (let ship?, let expiry?): return (currentDate >= ship) && (currentDate <= expiry)
        }
    }
}


