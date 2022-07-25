// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

protocol WallpaperMetadataTestProvider {
    func getExpectedMetadata(for: WallpaperJSONId) -> WallpaperMetadata
}

extension WallpaperMetadataTestProvider {
    func getExpectedMetadata(for jsonType: WallpaperJSONId) -> WallpaperMetadata {
        switch jsonType {
        case .initial: return getInitialMetadata()
        default:
            fatalError("No such expected data exists")
        }
    }

    private func getInitialMetadata() -> WallpaperMetadata {
        let lastUpdatedDate = dateWith(year: 2001, month: 02, day: 03)
        let startDate = dateWith(year: 2002, month: 11, day: 28)
        let endDate = dateWith(year: 2022, month: 09, day: 10)

        return WallpaperMetadata(
            lastUpdated: lastUpdatedDate,
            collections: [
                WallpaperCollection(
                    id: "firefox",
                    availableLocales: ["en-US", "es-US", "en-CA", "fr-CA"],
                    availability: WallpaperCollectionAvailability(
                        start: startDate,
                        end: endDate),
                    wallpapers: [
                        Wallpaper(id: "beachVibes", textColour: "0xADD8E6")
                    ])
            ])
    }
    
    private func dateWith(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        let userCalendar = Calendar(identifier: .gregorian)
        guard let expectedDate = userCalendar.date(from: dateComponents) else {
            fatalError("Error creating expected date.")
        }

        return expectedDate
    }
}
