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

struct WallpaperImageSet {
    let portrait: UIImage?
    let landscape: UIImage?
}

// MARK: - Collection types
/// This enum will outline all types of different wallpaper collections we currently
/// and may offer in the future. As such, there may be items here that are outdated.
enum WallpaperCollectionType: String, Codable {
    case firefox
    case projectHouse
}

// MARK: - Wallpaper
struct Wallpaper: Codable, Equatable {
    // MARK: - Variables
    let name: String
    let type: WallpaperType
    private let expiryDate: Date?
    private let locales: [String]?

    var image: WallpaperImageSet {
        var fileName = name
        if UIDevice.current.userInterfaceIdiom == .pad { fileName += "_pad" }

        return WallpaperImageSet(portrait: UIImage(named: fileName),
                                 landscape: UIImage(named: fileName + "_ls"))
    }

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

    var isEligibleForDisplay: Bool {
        if type == .defaultBackground { return true }

        switch (expiryDate, locales) {
        case (nil, nil): return true
        case (let date?, nil): return checkEligibilityFor(date: date)
        case (nil, let locales?): return checkEligibilityFor(locales: locales)
        case (let date?, let locales?):
            return checkEligibilityFor(date: date) && checkEligibilityFor(locales: locales)
        }
    }

    // MARK: - Initializer
    init(named name: String,
         ofType type: WallpaperType,
         expiringOn date: Date? = nil,
         limitedToLocale locale: [String]? = nil) {
        self.name = name
        self.expiryDate = date
        self.type = type
        self.locales = locale
    }

    // MARK: - Private helper methods
    /// Checking if a date of format `yyyyMMdd` is
    private func checkEligibilityFor(date expiryDate: Date) -> Bool {
        let currentDate = Date()

        if currentDate <= expiryDate { return true }
        return false
    }

    private func checkEligibilityFor(locales: [String]) -> Bool {
        if locales.contains(Locale.current.identifier) { return true }
        return false
    }
}

