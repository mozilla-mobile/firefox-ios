// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage
import SwiftUI

import struct MozillaAppServices.VisitTransitionSet

private class FetchInProgressError: MaybeErrorType {
    internal var description: String {
        return "Fetch is already in-progress"
    }
}

class HistoryPanelViewModel: FeatureFlaggable {
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
    // Groups items we should have a single datasource containing sites and groups
    var searchTermGroups: [ASGroup<Site>] = []
    // Only individual sites
    var groupedSites = DateGroupedTableData<Site>()
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

    /// Begin the process of fetching history data, and creating ASGroups from them. A prefetch also triggers this.
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
                self.populateASGroups(fetchedSites: fetchedSites) { groups, items in
                    guard let groups = groups else {
                        completion(false)
                        return
                    }

                    self.searchTermGroups.append(contentsOf: groups)
                    self.createGroupedSites(sites: items)
                    self.buildGroupsVisibleSections()
                    completion(true)
                }
            }
        }
    }

    func createGroupedSites(sites: [Site]) {
        sites.forEach { site in
            if let latestVisit = site.latestVisit {
                self.groupedSites.add(site, timestamp: TimeInterval.fromMicrosecondTimestamp(latestVisit.date))
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
                self.searchResultSites = result.map { Site(url: $0.url, title: $0.title) }
                completion(!result.isEmpty)
            }
        }
    }

    func shouldShowEmptyState(searchText: String = "") -> Bool {
        guard isSearchInProgress else { return groupedSites.isEmpty && searchTermGroups.isEmpty }

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

        searchTermGroups.removeAll()
        groupedSites = DateGroupedTableData<Site>()
        buildVisibleSections()
    }

    func isSectionCollapsed(sectionIndex: Int) -> Bool {
        guard let sectionToHide = visibleSections[safe: sectionIndex] else { return false }

        return hiddenSections.contains(where: { $0 == sectionToHide })
    }

    /// Based on the latest visit of the group items gets the section where the group should be added
    /// if the section is available (visible) and not hidden returns it if not returns nil
    /// - Parameter group: ASGroup
    /// - Returns: Section where group should be added
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
        guard let individualItem = asGroup.groupedItems.last,
              let lastVisit = individualItem.latestVisit
        else { return nil }

        let groupDate = TimeInterval.timeIntervalSince1970ToDate(
            timeInterval: TimeInterval.fromMicrosecondTimestamp(lastVisit.date)
        )

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

    func deleteGroupsFor(dateOption: HistoryDeletionUtilityDateOptions) {
        if dateOption == .lastHour {
            deleteLastHourHistory()
        } else {
            deleteHistory(dateOption: dateOption)
        }
    }

    private func deleteHistory(dateOption: HistoryDeletionUtilityDateOptions) {
        guard let deletableSections = getDeletableSection(for: dateOption) else { return }
        deletableSections.forEach { section in
            // Remove grouped items for delete section
            var sectionItems: [AnyHashable] = groupsForSection(section: section)
            let singleItems = groupedSites.itemsForSection(section.rawValue - 1)
            sectionItems.append(contentsOf: singleItems)
            removeHistoryItems(item: sectionItems, at: section.rawValue)
        }
    }

    private func deleteLastHourHistory() {
        // Get the sections in which history items from the last hour could exist
        guard let deletableSections = getDeletableSection(for: .lastHour) else { return }

        deletableSections.forEach { section in
            let allHistoryItemsInSection = groupedSites.itemsForSection(section.rawValue - 1)

            // Filter the history items to only include items from the last hour
            let lastHourHistoryItems = allHistoryItemsInSection.filter { site in
                guard let latestVisit = site.latestVisit else {return false}
                let siteVisitTimeStamp = TimeInterval.fromMicrosecondTimestamp(latestVisit.date)
                let oneHourAgoTimeStamp = TimeInterval.fromMicrosecondTimestamp(
                    Date(timeIntervalSinceNow: -(60 * 60)).toMicrosecondsSince1970())
                return siteVisitTimeStamp >= oneHourAgoTimeStamp
            }
            removeHistoryItems(item: lastHourHistoryItems, at: section.rawValue)
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

    private func buildGroupsVisibleSections() {
        self.visibleSections = Sections.allCases.filter { section in
            return self.groupedSites.numberOfItemsForSection(section.rawValue - 1) > 0
            || !self.groupsForSection(section: section).isEmpty
        }
    }

    private func buildVisibleSections() {
        self.visibleSections = Sections.allCases.filter { section in
            self.groupedSites.numberOfItemsForSection(section.rawValue - 1) > 0
        }
    }

    /// Provide de-duplicated history and visible history sections.
    private func populateHistorySites(fetchedSites: [Site]) {
        let allCurrentGroupedSites = self.groupedSites.allItems()
        let allUniquedSitesToAdd = (allCurrentGroupedSites + fetchedSites)
            .filter { !allCurrentGroupedSites.contains($0) }

        allUniquedSitesToAdd.forEach { site in
            if let latestVisit = site.latestVisit {
                self.groupedSites.add(site, timestamp: TimeInterval.fromMicrosecondTimestamp(latestVisit.date))
            }
        }
    }

    /// Provide groups for currently fetched history items.
    private func populateASGroups(
        fetchedSites: [Site],
        completion: @escaping ([ASGroup<Site>]?, _ filteredItems: [Site]) -> Void
    ) {
        SearchTermGroupsUtility.getSiteGroups(
            with: self.profile,
            from: fetchedSites,
            using: .orderedDescending
        ) { group, individualItems in
            completion(group, individualItems)
        }
    }

    private func deleteSingle(site: Site) {
        groupedSites.remove(site)
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
            return [.today, .yesterday]
        case .today:
            return [.today]
        case .yesterday:
            return [.today, .yesterday]
        default:
            return nil
        }
    }
}
