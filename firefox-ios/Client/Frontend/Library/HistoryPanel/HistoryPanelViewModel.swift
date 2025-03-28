// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage
import SwiftUI

import struct MozillaAppServices.VisitTransitionSet

class HistoryPanelViewModel: FeatureFlaggable {
    enum Sections: Int, CaseIterable {
        case additionalHistoryActions
        case lastHour
        case lastTwentyFourHours
        case lastSevenDays
        case lastFourWeeks
        case older
        case searchResults

        var title: String? {
            switch self {
            case .lastHour:
                return .LibraryPanel.Sections.LastHour
            case .lastTwentyFourHours:
                return .LibraryPanel.Sections.LastTwentyFourHours
            case .lastSevenDays:
                return .LibraryPanel.Sections.LastSevenDays
            case .lastFourWeeks:
                return .LibraryPanel.Sections.LastFourWeeks
            case .older:
                return .LibraryPanel.Sections.Older
            case .additionalHistoryActions, .searchResults:
                return nil
            }
        }
    }

    // MARK: - Properties

    private let profile: Profile
    private var logger: Logger
    // Request limit and offset
    private let queryFetchLimit = 100
    // Is not intended to be use in prod code, only on test
    private(set) var currentFetchOffset = 0
    private let searchQueryFetchLimit = 50
    private var searchCurrentFetchOffset = 0

    // Search
    var isSearchInProgress = false
    var searchResultSites = [Site]()
    var searchHistoryPlaceholder: String = .LibraryPanel.History.SearchHistoryPlaceholder

    let historyActionables = HistoryActionablesModel.activeActionables
    var visibleSections: [Sections] = []
    // Only individual sites
    var dateGroupedSites = DateGroupedTableData<Site>(includeLastHour: true)
    var isFetchInProgress = false
    var shouldResetHistory = false
    // Collapsible sections
    var hiddenSections: [Sections] = []

    var hasRecentlyClosed: Bool {
        return !profile.recentlyClosedTabs.tabs.isEmpty
    }

    var emptyStateText: String {
        return !isSearchInProgress ? .HistoryPanelEmptyStateTitle : .LibraryPanel.History.NoHistoryResult
    }

    let historyPanelNotifications = [Notification.Name.FirefoxAccountChanged,
                                     Notification.Name.PrivateDataClearedHistory,
                                     Notification.Name.DynamicFontChanged,
                                     Notification.Name.DatabaseWasReopened,
                                     Notification.Name.OpenClearRecentHistory,
                                     Notification.Name.OpenRecentlyClosedTabs]

    // MARK: - Inits

    init(profile: Profile,
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
    }

    /// Begin the process of fetching history data. A prefetch also triggers this.
    func reloadData(completion: @escaping (Bool) -> Void) {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        guard !profile.isShutdown, !isFetchInProgress else {
            completion(false)
            return
        }

        if shouldResetHistory {
            resetHistory()
        }

        fetchData { [weak self] fetchedSites in
            DispatchQueue.global().async {
                guard let self = self,
                      !fetchedSites.isEmpty else {
                    completion(false)
                    return
                }

                self.currentFetchOffset += self.queryFetchLimit
                self.createGroupedSites(sites: fetchedSites)
                self.buildVisibleSections()
                completion(true)
            }
        }
    }

    func createGroupedSites(sites: [Site]) {
        sites.forEach { site in
            if let latestVisit = site.latestVisit {
                self.dateGroupedSites.add(site, timestamp: TimeInterval.fromMicrosecondTimestamp(latestVisit.date))
            }
        }
    }

    func performSearch(term: String, completion: @escaping (Bool) -> Void) {
        isFetchInProgress = true

        profile.places.interruptReader()
        profile.places.queryAutocomplete(
            matchingSearchQuery: term,
            limit: searchQueryFetchLimit
        ).uponQueue(.main) { result in
            self.isFetchInProgress = false

            guard result.isSuccess else {
                self.logger.log(
                    "Error searching history panel",
                    level: .warning,
                    category: .sync,
                    description: result.failureValue?.localizedDescription ?? "Unkown error searching history"
                )
                completion(false)
                return
            }
            if let result = result.successValue {
                self.searchResultSites = result.map { Site.createBasicSite(url: $0.url, title: $0.title) }
                completion(!result.isEmpty)
            }
        }
    }

    func shouldShowEmptyState(searchText: String = "") -> Bool {
        guard isSearchInProgress else { return dateGroupedSites.isEmpty }

        // if the search text is empty we show the regular history so the empty should not show
        return !searchText.isEmpty ? searchResultSites.isEmpty : false
    }

    func collapseSection(sectionIndex: Int) {
        guard let sectionToHide = visibleSections[safe: sectionIndex - 1] else { return }

        if hiddenSections.contains(where: { $0 == sectionToHide }) {
            let index = hiddenSections.firstIndex(of: sectionToHide) ?? 0
            hiddenSections.remove(at: index)
        } else {
            hiddenSections.append(sectionToHide)
        }
    }

    func removeAllData() {
        // Since we remove all data, we reset our fetchOffset back to the start.
        currentFetchOffset = 0

        dateGroupedSites = DateGroupedTableData<Site>(includeLastHour: true)
        buildVisibleSections()
    }

    func isSectionCollapsed(sectionIndex: Int) -> Bool {
        guard let sectionToHide = visibleSections[safe: sectionIndex] else { return false }

        return hiddenSections.contains(where: { $0 == sectionToHide })
    }

    func deleteGroupsFor(dateOption: HistoryDeletionUtilityDateOptions) {
        guard let deletableSections = getDeletableSection(for: dateOption) else { return }
        deletableSections.forEach { section in
            let sectionItems = dateGroupedSites.itemsForSection(section.rawValue - 1)
            removeHistoryItems(item: sectionItems, at: section.rawValue)
        }
    }

    /// This handles removing a Site from the view.
    func removeHistoryItems(item historyItem: [AnyHashable], at section: Int) {
        historyItem.forEach { item in
            if let site = item as? Site {
                deleteSingle(site: site)
            }
        }
        buildVisibleSections()
    }

    // MARK: - Private helpers

    private func fetchData(completion: @escaping (([Site]) -> Void)) {
        guard !isFetchInProgress else {
            completion([])
            return
        }

        isFetchInProgress = true

        profile.places.getSitesWithBound(
            limit: queryFetchLimit,
            offset: currentFetchOffset,
            excludedTypes: VisitTransitionSet(0)
        ).upon { [weak self] result in
            completion(result.successValue?.asArray() ?? [])

            // Force 100ms delay between resolution of the last batch of results
            // and the next time `fetchData()` can be called.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                guard let self = self else { return }
                self.isFetchInProgress = false
                self.logger.log("currentFetchOffset is: \(self.currentFetchOffset)",
                                level: .debug,
                                category: .library)
            }
        }
    }

    private func resetHistory() {
        removeAllData()
        shouldResetHistory = false
    }

    private func buildVisibleSections() {
        self.visibleSections = Sections.allCases.filter { section in
            self.dateGroupedSites.numberOfItemsForSection(section.rawValue - 1) > 0
        }
    }

    /// Provide de-duplicated history and visible history sections.
    private func populateHistorySites(fetchedSites: [Site]) {
        let allCurrentGroupedSites = self.dateGroupedSites.allItems()
        let allUniquedSitesToAdd = (allCurrentGroupedSites + fetchedSites)
            .filter { !allCurrentGroupedSites.contains($0) }

        allUniquedSitesToAdd.forEach { site in
            if let latestVisit = site.latestVisit {
                self.dateGroupedSites.add(site, timestamp: TimeInterval.fromMicrosecondTimestamp(latestVisit.date))
            }
        }
    }

    private func deleteSingle(site: Site) {
        dateGroupedSites.remove(site)
        self.profile.places.deleteVisitsFor(url: site.url).uponQueue(.main) { _ in
            NotificationCenter.default.post(name: .TopSitesUpdated, object: nil)
        }

        if isSearchInProgress, let indexToRemove = searchResultSites.firstIndex(of: site) {
            searchResultSites.remove(at: indexToRemove)
        }
    }

    private func getDeletableSection(for dateOption: HistoryDeletionUtilityDateOptions) -> [Sections]? {
        switch dateOption {
        case .lastHour:
            return [.lastHour]
        case .lastTwentyFourHours:
            return [.lastHour, .lastTwentyFourHours]
        case .lastSevenDays:
            return [.lastHour, .lastTwentyFourHours, .lastSevenDays]
        case .lastFourWeeks:
            return [.lastHour, .lastTwentyFourHours, .lastSevenDays, .lastFourWeeks]
        default:
            return nil
        }
    }
}
