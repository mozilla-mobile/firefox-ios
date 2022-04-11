// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import SwiftUI

private class FetchInProgressError: MaybeErrorType {
    internal var description: String {
        return "Fetch is already in-progress"
    }
}

class HistoryPanelViewModel: Loggable, FeatureFlagsProtocol {

    enum Sections: Int, CaseIterable {
        case additionalHistoryActions
        case today
        case yesterday
        case lastWeek
        case lastMonth
        case older
        case searchResults

        var title: String? {
            switch self {
            case .today:
                return .LibraryPanel.Sections.Today
            case .yesterday:
                return .LibraryPanel.Sections.Yesterday
            case .lastWeek:
                return .LibraryPanel.Sections.LastWeek
            case .lastMonth:
                return .LibraryPanel.Sections.LastMonth
            case .older:
                return .LibraryPanel.Sections.Older
            case .additionalHistoryActions, .searchResults:
                return nil
            }
        }
    }

    // MARK: - Properties

    private let profile: Profile
    private let queryFetchLimit = 100
    private var currentFetchOffset = 0
    // Search offset and Limit
    private let searchQueryFetchLimit = 50
    private var searchCurrentFetchOffset = 0
    let historyActionables = HistoryActionablesModel.activeActionables

    var visibleSections: [Sections] = []
    var searchTermGroups: [ASGroup<Site>] = []
    var isFetchInProgress = false
    var isSearchInProgress = false
    var groupedSites = DateGroupedTableData<Site>()
    var searchResultSites = [Site]()
    var searchHistoryPlaceholder: String = .LibraryPanel.History.SearchHistoryPlaceholder

    private var hasRecentlyClosed: Bool {
        return profile.recentlyClosedTabs.tabs.count > 0
    }

    var emptyStateText: String {
        return !isSearchInProgress ? .HistoryPanelEmptyStateTitle : .LibraryPanel.History.NoHistoryResult
    }

    var shouldShowEmptyState: Bool {
        return isSearchInProgress ? searchResultSites.isEmpty : groupedSites.isEmpty
    }

    let historyPanelNotifications = [Notification.Name.FirefoxAccountChanged,
                                     Notification.Name.PrivateDataClearedHistory,
                                     Notification.Name.DynamicFontChanged,
                                     Notification.Name.DatabaseWasReopened,
                                     Notification.Name.OpenClearRecentHistory]

    // MARK: - Inits

    init(profile: Profile) {
        self.profile = profile
    }

    deinit {
        browserLog.debug("HistoryPanelViewModel Deinitialized.")
    }

    // MARK: - Private helpers

    /// Begin the process of fetching history data, and creating ASGroups from them. A prefetch also triggers this.
    func reloadData() {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        guard !profile.isShutdown, !isFetchInProgress else {
            browserLog.debug("HistoryPanel tableView data could NOT be reloaded! Either the profile wasn't shut down, or there's a fetch in progress.")
            return
        }

        fetchData().uponQueue(.global(qos: .userInteractive)) { result in
            if let sites = result.successValue {
                let fetchedSites = sites.asArray()

                self.populateHistorySites(fetchedSites: fetchedSites)

                if self.featureFlags.isFeatureActiveForBuild(.historyGroups) {
                    self.populateASGroups()
                }

                self.visibleSections = Sections.allCases.filter { section in
                    self.groupedSites.numberOfItemsForSection(section.rawValue - 1) > 0
                    || !self.groupsForSection(section: section).isEmpty
                }
            }
        }
    }

    // Add completion to reload on finish
    func performSearch(term: String, completion: @escaping (Bool) -> Void) {
        isFetchInProgress = true

        profile.history.getHistory(matching: term,
                                   limit: searchQueryFetchLimit,
                                   offset: searchCurrentFetchOffset) { results in
            self.isFetchInProgress = false
            self.searchResultSites = results
            completion(!results.isEmpty)
        }
    }

    func updateSearchOffset() {
        searchCurrentFetchOffset += searchQueryFetchLimit
    }

    /// A helper for the reload function.
    private func fetchData() -> Deferred<Maybe<Cursor<Site>>> {
        isFetchInProgress = true

        return profile.history.getSitesByLastVisit(limit: queryFetchLimit, offset: currentFetchOffset) >>== { result in
            // Force 100ms delay between resolution of the last batch of results
            // and the next time `fetchData()` can be called.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.currentFetchOffset += self.queryFetchLimit
                self.isFetchInProgress = false

                self.browserLog.debug("currentFetchOffset is: \(self.currentFetchOffset)")
            }

            return deferMaybe(result)
        }
    }

    /// Provide de-duplicated history and visible history sections.
    private func populateHistorySites(fetchedSites: [Site]) {
        let allCurrentGroupedSites = self.groupedSites.allItems()
        let allUniquedSitesToAdd = (allCurrentGroupedSites + fetchedSites).uniqued().filter { !allCurrentGroupedSites.contains($0) }

        allUniquedSitesToAdd.forEach { site in
            if let latestVisit = site.latestVisit {
                self.groupedSites.add(site, timestamp: TimeInterval.fromMicrosecondTimestamp(latestVisit.date))
            }
        }

        self.visibleSections = Sections.allCases.filter { section in
            self.groupedSites.numberOfItemsForSection(section.rawValue - 1) > 0
        }
    }

    /// Provide groups for curruently fetched history items.
    private func populateASGroups() {
        SearchTermGroupsManager.getSiteGroups(with: self.profile, from: self.groupedSites.allItems(), using: .orderedDescending) { group, filteredItems in
            guard var searchTermGrouping = group else { return }

            // Remove overlapping history & STG items
            searchTermGrouping.forEach { group in
                group.groupedItems.forEach { self.groupedSites.remove($0) }
            }

            // Remove overlapping STGs. This happens when the queryFetchLimit is too low - then STGManager makes duplicate groups.
            self.searchTermGroups.forEach { group in
                searchTermGrouping = searchTermGrouping.filter { $0.displayTitle != group.displayTitle }
            }

            self.searchTermGroups.append(contentsOf: searchTermGrouping)
        }
    }

    // MARK: - Public facing helpers

    /// This helps us place an ASGroup<Site> in the correct section.
    func groupBelongsToSection(asGroup: ASGroup<Site>) -> HistoryPanelViewModel.Sections? {
        guard let individualItem = asGroup.groupedItems.last, let lastVisit = individualItem.latestVisit else { return nil }

        let groupDate = TimeInterval.timeIntervalSince1970ToDate(timeInterval: TimeInterval.fromMicrosecondTimestamp(lastVisit.date))

        if groupDate.isToday() {
            return .today
        } else if groupDate.isYesterday() {
            return .yesterday
        } else if groupDate.isWithinLast7Days() {
            return .lastWeek
        } else if groupDate.isWithinLast14Days() {
            // Since two weeks falls within here, lastMonth will have an ASGroup, if it exists.
            return .lastMonth
        }

        return nil
    }

    func groupsForSection(section: Sections) -> [ASGroup<Site>] {
        let groups = searchTermGroups.filter { group in
            if let groupInSection = groupBelongsToSection(asGroup: group) {
                return groupInSection == section
            }

            return false
        }

        return groups
    }

    /// This will remove entire sections of data on triggering the Clear History flow.
    func removeVisibleSectionFor(date: Date) {
        // handle the past one hour later
        var sectionToRemove: [Sections]

        // Selecting today and every option after gives us a date of the day before... So we adjust.
        let adjustedDate = date.dayAfter

        if adjustedDate.isToday() {
            sectionToRemove = [.today]
        } else if adjustedDate.isYesterday() {
            sectionToRemove = [.today, .yesterday]
        } else {
            sectionToRemove = Sections.allCases
        }

        sectionToRemove.forEach { section in
            visibleSections = visibleSections.filter { $0 != section }
        }
    }

    /// This handles removing either a Site or an ASGroup<Site> from the view.
    func removeHistoryItems(item historyItem: AnyHashable, at section: Int) {
        guard let timeSection = Sections(rawValue: section) else { return }

        let isSectionWithNoSites: Bool
        let isSectionWithGroups: Bool

        if let site = historyItem as? Site {
            groupedSites.remove(site)
            profile.history.removeHistoryForURL(site.url)
        } else if let group = historyItem as? ASGroup<Site> {
            group.groupedItems.forEach { site in
                groupedSites.remove(site)
                profile.history.removeHistoryForURL(site.url)
            }

            searchTermGroups = searchTermGroups.filter { $0 != group }
        }

        isSectionWithNoSites = groupedSites.numberOfItemsForSection(section - 1) == 0
        isSectionWithGroups = searchTermGroups.contains { group in
            if let groupSection = groupBelongsToSection(asGroup: group) {
                return groupSection == timeSection
            }

            return false
        }

        if isSectionWithNoSites, !isSectionWithGroups {
            visibleSections = visibleSections.filter { $0 != timeSection }
        }
    }
}
