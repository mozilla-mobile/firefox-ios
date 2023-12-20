// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import WebKit
import Shared

enum HistoryDeletionUtilityDateOptions {
    case lastHour
    case today
    case yesterday
    case allTime
}

protocol HistoryDeletionProtocol {
    func delete(_ sites: [String], completion: @escaping (Bool) -> Void)
    func deleteHistoryFrom(_ dateOption: HistoryDeletionUtilityDateOptions,
                           completion: @escaping (HistoryDeletionUtilityDateOptions) -> Void)
}

class HistoryDeletionUtility: HistoryDeletionProtocol {
    private var profile: Profile

    init(with profile: Profile) {
        self.profile = profile
    }

    // MARK: Interface
    func delete(
        _ sites: [String],
        completion: @escaping (Bool) -> Void
    ) {
        deleteFromHistory(sites)
        deleteMetadata(sites) { result in
            completion(result)
        }
    }

    func deleteHistoryFrom(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        completion: @escaping (HistoryDeletionUtilityDateOptions) -> Void
    ) {
        deleteWKWebsiteDataSince(dateOption, for: WKWebsiteDataStore.allWebsiteDataTypes())
        // For efficiency, we'll delete data in parallel, which is why closures are
        // not encloning each subsequent call
        deleteProfileHistorySince(dateOption) { result in
            self.clearRecentlyClosedTabs(using: dateOption)
            completion(dateOption)
        }

        deleteProfileMetadataSince(dateOption)

        reportDeletionFor(dateOption)
    }

    // MARK: URL based deletion functions
    private func deleteFromHistory(_ sites: [String]) {
        sites.forEach { _ = profile.places.deleteVisitsFor($0) }
    }

    private func deleteMetadata(
        _ sites: [String],
        completion: @escaping (Bool) -> Void
    ) {
        sites.forEach { currentSite in
            profile.places
                .deleteVisitsFor(url: currentSite)
                .uponQueue(.global()) { result in
                    guard let lastSite = sites.last,
                          lastSite == currentSite
                    else { return }

                    completion(result.isSuccess)
                }
        }
    }

    // MARK: - Date based deletion functions
    private func deleteWKWebsiteDataSince(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        for types: Set<String>
    ) {
        guard let date = dateFor(dateOption, requiringAllTimeAsPresent: false) else { return }

        WKWebsiteDataStore.default().removeData(
            ofTypes: types,
            modifiedSince: date,
            completionHandler: { }
        )
    }

    private func deleteProfileHistorySince(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        completion: @escaping (Bool?) -> Void
    ) {
        switch dateOption {
        case .allTime:
            profile.places.deleteEverythingHistory().uponQueue(.global()) { result in
                completion(result.isSuccess)
            }
        default:
            guard let date = dateFor(dateOption) else { return }
            profile.places.deleteVisitsBetween(date).uponQueue(.global()) { result in
                completion(result.isSuccess)
            }
        }
    }

    private func deleteProfileMetadataSince(_ dateOption: HistoryDeletionUtilityDateOptions) {
        guard let date = dateFor(dateOption) else { return }
        let dateInMilliseconds = date.toMillisecondsSince1970()

        profile.places.deleteHistoryMetadata(since: dateInMilliseconds) { _ in }
    }

    func deleteHistoryMetadataOlderThan(_ dateOption: HistoryDeletionUtilityDateOptions) {
        guard let date = dateFor(dateOption) else { return }
        let dateInMilliseconds = date.toMillisecondsSince1970()
        self.profile.places.deleteHistoryMetadataOlderThan(olderThan: dateInMilliseconds).uponQueue(.global()) { _ in }
    }

    private func clearRecentlyClosedTabs(using dateOption: HistoryDeletionUtilityDateOptions) {
        switch dateOption {
        case .allTime:
            profile.recentlyClosedTabs.clearTabs()
        default:
            guard let date = dateFor(dateOption) else { return }

            profile.recentlyClosedTabs.removeTabsFromDate(date)
        }
    }

    // MARK: - Helper functions

    public func deletionReferenceValue(for dateOption: HistoryDeletionUtilityDateOptions) -> Int64 {
        return dateFor(dateOption)?.toMillisecondsSince1970() ?? Int64.max
    }

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

    private func reportDeletionFor(_ dateOption: HistoryDeletionUtilityDateOptions) {
        switch dateOption {
        case .today:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .historyRemovedToday)
        case .yesterday:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .historyRemovedTodayAndYesterday)
        case .allTime:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .historyRemovedAll)
        default: break
        }
    }
}
