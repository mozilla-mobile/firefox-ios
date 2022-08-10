// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import WebKit

enum HistoryDeletionUtilityDateOptions {
    case lastHour
    case today
    case yesterday
    case allTime
}

class HistoryDeletionUtility {

    private var profile: Profile

    init(with profile: Profile) {
        self.profile = profile
    }

    // MARK: URL based deletion functions
    public func delete(_ sites: [String]) async -> Bool {
        deleteFromHistory(sites)
        return await deleteMetadata(sites)
    }

    private func deleteFromHistory(_ sites: [String]) {
        sites.forEach { profile.history.removeHistoryForURL($0) }
    }

    private func deleteMetadata(_ sites: [String]) async -> Bool {
        return await withCheckedContinuation { continuation in
            sites.forEach { currentSite in
                profile.places
                    .deleteVisitsFor(url: currentSite)
                    .uponQueue(.global(qos: .userInitiated)) { result in
                        guard let lastSite = sites.last,
                              lastSite == currentSite
                        else { return }

                        continuation.resume(returning: result.isSuccess)
                    }
            }
        }
    }

    // MARK: - Date based deletion functions
    public func deleteHistoryFrom(_ dateOption: HistoryDeletionUtilityDateOptions) async -> HistoryDeletionUtilityDateOptions {

        await deleteWKWebsiteDataSince(dateOption, for: WKWebsiteDataStore.allWebsiteDataTypes())
        _ = await deleteProfileHistorySince(dateOption)
        _ = await deleteProfileMetadataSince(dateOption)
        clearRecentlyClosedTabs(using: dateOption)

        return dateOption
    }

    private func deleteWKWebsiteDataSince(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        for types: Set<String>
    ) async {
        guard let date = dateFor(dateOption, requiringAllTimeAsPresent: false) else { return }

        await WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: date)
    }

    private func deleteProfileHistorySince(_ dateOption: HistoryDeletionUtilityDateOptions) async -> Bool? {
        switch dateOption {
        case .allTime:
            return await withCheckedContinuation { continuation in
                profile.history
                    .clearHistory()
                    .uponQueue(.global(qos: .userInteractive)) { result in
                        continuation.resume(returning: result.isSuccess)
                    }
            }

        default:
            guard let date = dateFor(dateOption) else { return nil }

            return await withCheckedContinuation { continuation in
                profile.history
                    .removeHistoryFromDate(date)
                    .uponQueue(.global(qos: .userInteractive)) { result in
                        continuation.resume(returning: result.isSuccess)
                    }
            }
        }
    }

    private func deleteProfileMetadataSince(_ dateOption: HistoryDeletionUtilityDateOptions) async -> Bool? {
        guard let date = dateFor(dateOption) else { return nil }
        let dateInMilliseconds = date.toMillisecondsSince1970()

        return await withCheckedContinuation { continuation in
            profile.places
                .deleteHistoryMetadata(since: dateInMilliseconds)
                .uponQueue(.global(qos: .userInteractive)) { result in
                    continuation.resume(returning: result.isSuccess)
                }
        }
    }

    private func clearRecentlyClosedTabs(using dateOption: HistoryDeletionUtilityDateOptions) {
        switch dateOption {
        case .allTime:
            profile.recentlyClosedTabs.clearTabs()
        default:
            guard let date = dateFor(dateOption) else { return }

            profile.recentlyClosedTabs.removeTabsFromDate(date)
        }

        NotificationCenter.default.post(name: .TopSitesUpdated, object: self)
    }

    // MARK: - Helper functions
    private func dateFor(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        requiringAllTimeAsPresent: Bool = true
    ) -> Date? {
        switch dateOption {
        case .lastHour:
            return Calendar.current.date(byAdding: .hour, value: -1, to: Date())
        case .today:
            return Calendar.current.startOfDay(for: Date())
        case .yesterday:
            guard let yesterday = Calendar.current.date(byAdding: .hour,
                                                        value: -24,
                                                        to: Date())
            else { return nil }

            return Calendar.current.startOfDay(for: yesterday)
        case .allTime:
            let pastReferenceDate = Date(timeIntervalSinceReferenceDate: 0)
            return requiringAllTimeAsPresent ? Date() : pastReferenceDate
        }
    }
}
