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

    /// Deletes sites from the history and from metadata.
    ///
    /// Completion block is included for testing and should not be used otherwise.
    public func delete(_ sites: [String], completion: ((Bool) -> Void)? = nil) {
        deleteFromHistory(sites)
        deleteMetadata(sites) { result in
            completion?(result)
        }
    }

    public func deleteHistoryFrom(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        completion: ((Date?) -> Void)? = nil
    ) {
        deleteWKWebsiteDataSince(dateOption,
                                 for: WKWebsiteDataStore.allWebsiteDataTypes())
        deleteProfileHistorySince(dateOption) {
            self.deleteProfileMetadataSince(dateOption) { time in
                completion?(time)
            }
        }
    }

    // MARK: Private url based deletion functions

    private func deleteFromHistory(_ sites: [String]) {
        sites.forEach { profile.history.removeHistoryForURL($0) }
    }

    private func deleteMetadata(_ sites: [String], completion: ((Bool) -> Void)? = nil) {
        sites.forEach { currentSite in
            profile.places
                .deleteVisitsFor(url: currentSite)
                .uponQueue(.global(qos: .userInitiated)) { result in
                    guard let lastSite = sites.last,
                          lastSite == currentSite
                    else { return }

                    completion?(result.isSuccess)
                }
        }
    }

    // MARK: Private date based deletion functions
    private func deleteWKWebsiteDataSince(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        for types: Set<String>
    ) {
        guard let unwrappedDate = dateFor(dateOption) else { return }
        let date = dateOption == .allTime ? .distantPast : unwrappedDate

        WKWebsiteDataStore.default().removeData(ofTypes: types,
                                                modifiedSince: date,
                                                completionHandler: { })
    }

    private func deleteProfileHistorySince(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        completion: (() -> Void)? = nil
    ) {
        switch dateOption {
        case .allTime:
            profile.history
                .clearHistory()
                .uponQueue(.global(qos: .userInteractive)) { result in
                    if result.isSuccess { completion?() }
                    // ROUX: does this need to be here?
                    //                guard let completion = didComplete else { return }
                    //                self.profile.recentlyClosedTabs.removeTabsFromDate(startOfDay)
                    //                completion?(nil)
                }

        default:
            guard let date = dateFor(dateOption) else { return }

            profile.history
                .removeHistoryFromDate(date)
                .uponQueue(.global(qos: .userInteractive)) { result in
                    if result.isSuccess { completion?() }
                    // ROUX: does this need to be here?
                    //                guard let completion = didComplete else { return }
                    //                self.profile.recentlyClosedTabs.removeTabsFromDate(startOfDay)
                    //                completion?(nil)
                }
        }
    }

    private func deleteProfileMetadataSince(
        _ dateOption: HistoryDeletionUtilityDateOptions,
        completion: ((Date?) -> Void)? = nil
    ) {
        guard let date = dateFor(dateOption) else { return }
        let dateInMilliseconds = date.toMillisecondsSince1970()

        profile.places
            .deleteHistoryMetadataOlderThan(olderThan: dateInMilliseconds)
            .uponQueue(.global(qos: .userInteractive)) { result in
                if result.isSuccess { completion?(date) }
            }
    }

//    private func deleteAllHistoryData(completion: ((Date?) -> Void)? = nil) {
//
//        profile.history.clearHistory().uponQueue(.global(qos: .userInteractive)) { _ in
//            // INT64_MAX represents the oldest possible time that AS would have
//            self.profile.places
//                .deleteHistoryMetadataOlderThan(olderThan: INT64_MAX)
//                .uponQueue(.global(qos: .userInteractive)) { _ in
//                guard let completion = completion else { return }
//                completion(nil)
//            }
//        }
//    }
//
    private func dateFor(_ dateOption: HistoryDeletionUtilityDateOptions) -> Date? {
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
            return Date()
        }
    }
}
