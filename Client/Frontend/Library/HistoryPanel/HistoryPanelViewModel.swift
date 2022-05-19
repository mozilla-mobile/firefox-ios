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

class HistoryPanelViewModel: Loggable, FeatureFlaggable {

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
    // Request limit and offset
    private let queryFetchLimit = 100
    private var currentFetchOffset = 0
    private let searchQueryFetchLimit = 50
    private var searchCurrentFetchOffset = 0

    // Search
    var isSearchInProgress = false
    var searchResultSites = [Site]()
    var searchHistoryPlaceholder: String = .LibraryPanel.History.SearchHistoryPlaceholder

    let historyActionables = HistoryActionablesModel.activeActionables
    var visibleSections: [Sections] = []
    // Groups items we should have a single datasource containing sites and groups
    var searchTermGroups: [ASGroup<Site>] = []
    // Only individual sites
    var groupedSites = DateGroupedTableData<Site>()
    var isFetchInProgress = false
    var shouldResetHistory = false
    var hiddenSections: [Sections] = []

    private var hasRecentlyClosed: Bool {
        return profile.recentlyClosedTabs.tabs.count > 0
    }

    var emptyStateText: String {
        return !isSearchInProgress ? .HistoryPanelEmptyStateTitle : .LibraryPanel.History.NoHistoryResult
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

    /// Begin the process of fetching history data, and creating ASGroups from them. A prefetch also triggers this.
    func reloadData(completion: @escaping (Bool) -> Void) {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        guard !profile.isShutdown, !isFetchInProgress else {
            browserLog.debug("HistoryPanel tableView data could NOT be reloaded! Either the profile wasn't shut down, or there's a fetch in progress.")
            completion(false)
            return
        }

        if shouldResetHistory {
            resetHistory()
        }

        fetchData().uponQueue(.global(qos: .userInteractive)) { result in
            guard let fetchedSites = result.successValue?.asArray(), !fetchedSites.isEmpty else {
                completion(false)
                return
            }

            self.currentFetchOffset += self.queryFetchLimit
            if self.featureFlags.isFeatureEnabled(.historyGroups, checking: .buildOnly) {
                self.populateASGroups(fetchedSites: fetchedSites) {
                    self.buildVisibleSections()
                    completion(true)
                }
            } else {
                self.populateHistorySites(fetchedSites: fetchedSites)
                completion(true)
            }
        }
    }

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

    func shouldShowEmptyState(searchText: String) -> Bool {
        guard isSearchInProgress else { return groupedSites.isEmpty && searchTermGroups.isEmpty }

        // if the search text is empty we show the regular history so the empty should not show
        return !searchText.isEmpty ? searchResultSites.isEmpty : false
    }

    func updateSearchOffset() {
        searchCurrentFetchOffset += searchQueryFetchLimit
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
        /// Since we remove all data, we reset our fetchOffset back to the start.
        currentFetchOffset = 0

        searchTermGroups.removeAll()
        groupedSites = DateGroupedTableData<Site>()
        buildVisibleSections()
    }

    func isSectionCollapsed(sectionIndex: Int) -> Bool {
        guard let sectionToHide = visibleSections[safe: sectionIndex] else { return false }

        return hiddenSections.contains(where: { $0 == sectionToHide })
    }

    // MARK: - Private helpers

    /// A helper for the reload function.
    private func fetchData() -> Deferred<Maybe<Cursor<Site>>> {
        isFetchInProgress = true

        return profile.history.getSitesByLastVisit(limit: queryFetchLimit, offset: currentFetchOffset) >>== { result in
            // Force 100ms delay between resolution of the last batch of results
            // and the next time `fetchData()` can be called.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.isFetchInProgress = false

                self.browserLog.debug("currentFetchOffset is: \(self.currentFetchOffset)")
            }

            return deferMaybe(result)
        }
    }

    private func resetHistory() {
        removeAllData()

        shouldResetHistory = false
    }

    private func buildVisibleSections() {
        self.visibleSections = Sections.allCases.filter { section in
            return self.groupedSites.numberOfItemsForSection(section.rawValue - 1) > 0
            || !self.groupsForSection(section: section).isEmpty
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
    private func populateASGroups(fetchedSites: [Site], completion: @escaping () -> Void) {
        SearchTermGroupsUtility.getSiteGroups(with: self.profile, from: fetchedSites, using: .orderedDescending) { group, filteredItems in
            guard let searchTermGrouping = group else { return }

            self.searchTermGroups.append(contentsOf: searchTermGrouping)

            filteredItems.forEach { site in
                if let latestVisit = site.latestVisit {
                    self.groupedSites.add(site, timestamp: TimeInterval.fromMicrosecondTimestamp(latestVisit.date))
                }
            }
            completion()
        }
    }

    // MARK: - Public facing helpers

    func shouldAddGroupToSections(group: ASGroup<Site>) -> HistoryPanelViewModel.Sections? {
        guard let section = groupBelongsToSection(asGroup: group),
                visibleSections.contains(section),
              !hiddenSections.contains(section) else {
            return nil
        }

        return section
    }

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

    func deleteGroupsForDates(date: Date) {
        guard let deletableSections = getDeletableSection(date: date) else { return }

        deletableSections.forEach { section in
            // Remove grouped items for delete section
            var sectionItems: [AnyHashable] = groupsForSection(section: section)
            let singleItems = groupedSites.itemsForSection(section.rawValue - 1)
            sectionItems.append(contentsOf: singleItems)
            removeHistoryItems(item: sectionItems, at: section.rawValue)
        }
    }

    /// This handles removing either a Site or an ASGroup<Site> from the view.
    func removeHistoryItems(item historyItem: [AnyHashable], at section: Int) {
        historyItem.forEach { item in
            if let site = item as? Site {
                deleteSingle(site: site)
            } else if let group = item as? ASGroup<Site> {
                group.groupedItems.forEach { site in
                    deleteSingle(site: site)
                }
                searchTermGroups = searchTermGroups.filter { $0 != group }
            }
        }
        buildVisibleSections()
    }

    private func deleteSingle(site: Site) {
        groupedSites.remove(site)
        profile.history.removeHistoryForURL(site.url)
    }

    private func getDeletableSection(date: Date) -> [Sections]? {
        var deletableSections: [Sections]?

        if date.isToday() {
            deletableSections = [.today]
        } else if date.isYesterday() {
            deletableSections = [.today, .yesterday]
        }

        return deletableSections
    }
}
