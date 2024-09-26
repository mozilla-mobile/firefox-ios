// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

import struct MozillaAppServices.HistoryHighlight
import struct MozillaAppServices.HistoryMetadata

class SearchTermGroupsUtility {
    public static func getHighlightGroups(
        with profile: Profile,
        from highlights: [HistoryHighlight],
        using ordering: ComparisonResult,
        completion: @escaping ([ASGroup<HistoryHighlight>]?, _ filteredItems: [HistoryHighlight]) -> Void
    ) {
        getGroups(with: profile, from: highlights, using: ordering, completion: completion)
    }

    public static func getSiteGroups(
        with profile: Profile,
        from sites: [Site],
        using ordering: ComparisonResult,
        completion: @escaping ([ASGroup<Site>]?, _ filteredItems: [Site]) -> Void
    ) {
        getGroups(with: profile, from: sites, using: ordering, completion: completion)
    }

    public static func getTabGroups(
        with profile: Profile,
        from tabs: [Tab],
        using ordering: ComparisonResult,
        completion: @escaping ([ASGroup<Tab>]?, _ filteredItems: [Tab]) -> Void
    ) {
        getGroups(with: profile, from: tabs, using: ordering, completion: completion)
    }

    /// Create item groups from metadata.
    ///
    /// This function take a type `T` generic, and creates groups based on metadata available
    /// from Application Services.
    ///
    /// - Parameters:
    ///   - profile: The user's `Profile` info
    ///   - items: List of items we want to make the groups from. This is a generic type and
    ///   currently only supports `Tab`, `URL` and `HistoryHighlight`
    ///   - ordering: Order in which we want to return groups, `.orderedAscending` or
    ///   `.orderedDescending`. `.orderedSame` is also possible, but will return the exact
    ///   order of the group that was provided. Note: this does not affect the groups' items,
    ///   which will always return in ascending order.
    ///   - completion: completion handler that contains `[ASGroup<T>]`  dictionary and a
    ///   filteredItems list, `[T]`, which is comprised of items from the original input
    ///   that are not part of a group.
    private static func getGroups<T: Equatable>(
        with profile: Profile,
        from items: [T],
        using ordering: ComparisonResult,
        completion: @escaping ([ASGroup<T>]?, _ filteredItems: [T]) -> Void
    ) {
        guard items is [Tab] || items is [Site] || items is [HistoryHighlight] else { return completion(nil, [T]()) }

        let lastTwoWeek = Int64(Date().lastTwoWeek.timeIntervalSince1970)
        profile.places.getHistoryMetadataSince(since: lastTwoWeek).uponQueue(.global()) { result in
            guard let historyMetadata = result.successValue else { return completion(nil, [T]()) }

            let searchTermMetaDataGroup = buildMetadataGroups(from: historyMetadata)
            let (groupDictionary, ungroupedTabs) = createGroupDictionaryAndSoloItems(
                from: items,
                and: searchTermMetaDataGroup
            )
            let filteredGroups = createGroups(from: groupDictionary)
            let orderedGroups = order(groups: filteredGroups, using: ordering)

            completion(orderedGroups, ungroupedTabs)
        }
    }

    /// Builds metadata groups using the provided metadata from ApplicationServices
    ///
    /// - Parameter ASMetadata: An array of `HistoryMetadata` used for splitting groups
    /// - Returns: A dictionary whose keys are search terms used for grouping
    private static func buildMetadataGroups(from ASMetadata: [HistoryMetadata]) -> [String: [HistoryMetadata]] {
        let searchTerms = Set(ASMetadata.map({ return $0.searchTerm }))
        var searchTermMetaDataGroup: [String: [HistoryMetadata]] = [:]

        for term in searchTerms {
            if let term = term {
                let elements = ASMetadata.filter({ $0.searchTerm == term })
                searchTermMetaDataGroup[term] = elements
            }
        }

        return searchTermMetaDataGroup
    }

    /// Creates filtered dictionary of items from an array of provided items, grouped by
    /// relevant search term, based on the provided search term metadata.
    ///
    /// - Parameters:
    ///   - items: The original list of items containing metadata upon which to sort
    ///   - searchTermMetadata: Application Services provided metadata
    /// - Returns: A tuple with a filtered dictionary of groups and a tracking array
    private static func createGroupDictionaryAndSoloItems<T: Equatable>(
        from items: [T],
        and searchTermMetadata: [String: [HistoryMetadata]]
    ) -> (itemGroupData: [String: [T]], itemsInGroups: [T]) {
        let (groupedItems, itemsInGroups) = buildItemGroups(from: items, and: searchTermMetadata)
        let (filteredGroupData, filtereditems) = filter(items: itemsInGroups, from: groupedItems, and: items)

        return (filteredGroupData, filtereditems)
    }

    /// Creates a dictionary of items, grouped by relevant search term, using the provided,
    /// search term data from Application Services.
    ///
    /// - Parameters:
    ///   - items: The original list of items containing metadata upon which to sort
    ///   - searchTermMetadata: AS search term metadata
    /// - Returns: A tuple with the group dictionary and a tracking array
    private static func buildItemGroups<T: Equatable>(
        from items: [T],
        and searchTermMetadata: [String: [HistoryMetadata]]
    ) -> (itemGroupData: [String: [T]], itemsInGroups: [T]) {
        var itemGroupData: [String: [T]] = [:]
        var itemsInGroups = [T]()

        outeritemLoop: for item in items {
            innerMetadataLoop: for (searchTerm, historyMetaList) in searchTermMetadata where historyMetaList
                .contains(where: { metadata in
                var stringURL: String = ""

                if let item = item as? Site {
                    stringURL = item.url
                } else if let item = item as? Tab, let url = item.lastKnownUrl?.absoluteString {
                    stringURL = url
                } else if let item = item as? HistoryHighlight {
                    stringURL = item.url
                }

                return metadata.url == stringURL || metadata.referrerUrl == stringURL
            }) {
                itemsInGroups.append(item)
                if itemGroupData[searchTerm] == nil {
                    itemGroupData[searchTerm] = [item]
                } else {
                    itemGroupData[searchTerm]?.append(item)
                }
                break innerMetadataLoop
            }
        }

        return (itemGroupData, itemsInGroups)
    }

    /// Parses the original array and the group dictionary and removes duplicate items,
    /// so no items in groups appear outside of groups, and also ensure that there are no
    /// groups containing a single item.
    ///
    /// - Parameters:
    ///   - itemsInGroups: Tracking array for items that are currently in groups
    ///   - itemGroups: Dictionary of grouped items according to search terms
    ///   - originalItems: Original array of items provided
    /// - Returns: A tuple containing all filtered groups and item
    private static func filter<T: Equatable>(
        items itemsInGroups: [T],
        from itemGroups: [String: [T]],
        and originalItems: [T]
    ) -> (filteredGroups: [String: [T]], filteredItems: [T]) {
        let (filteredGroups, itemsInGroups) = filterSingleItemGroups(from: itemGroups, and: itemsInGroups)
        let ungroupedItems = filterDuplicate(itemsInGroups: itemsInGroups, from: originalItems)

        return (filteredGroups, ungroupedItems)
    }

    /// Removes any groups containing a single item.
    ///
    /// - Parameters:
    ///   - itemGroups: Groups dictionary to check for groups containing a single item
    ///   - itemsInGroups: Array to keep track of any items that are currently in groups
    /// - Returns: A tuple containing groups that have two or more items, and a tracking array.
    private static func filterSingleItemGroups<T: Equatable>(
        from itemGroups: [String: [T]],
        and itemsInGroups: [T]
    ) -> (itemGroupData: [String: [T]], itemsInGroups: [T]) {
        var itemsInGroups = itemsInGroups

        // 3. Tab groups should have at least 2 tabs per search term so we remove smaller groups
        let filteredGroupData = itemGroups.filter { itemGroup in
            let temp = itemGroup.value
            if temp.count > 1 {
                return true
            } else {
                if let onlyItem = temp.first,
                   let index = itemsInGroups.firstIndex(of: onlyItem) {
                    itemsInGroups.remove(at: index)
                }
                return false
            }
        }

        return (filteredGroupData, itemsInGroups)
    }

    /// Removes duplicate items from the original item list; specifically, any items in
    /// groups are removed.
    ///
    /// - Parameters:
    ///   - itemsInGroups: Items that are present in groups
    ///   - items: The original items that were provided
    /// - Returns: A filtered array of the original items, containing no items present in groups
    private static func filterDuplicate<T: Equatable>(itemsInGroups: [T], from items: [T]) -> [T] {
        // 4. Filter the tabs so it doesn't include same tabs as tab groups
        return items.filter { item in !itemsInGroups.contains(item) }
    }

    /// Takes a dictionary and creates ASGroups from it.
    ///
    /// If dictionary contains `Tab`s, then the group will be assigned a timestamp based
    /// on the `firstCreatedTime` of the first item in the group.
    ///
    /// - Parameter groupDictionary: Dictionary that is to be processed
    /// - Returns: An array of `ASGroup<T>`
    private static func createGroups<T: Equatable>(from groupDictionary: [String: [T]]) -> [ASGroup<T>] {
        return groupDictionary.map {
            let orderedItems = orderItemsIn(group: $0.value)
            var timestamp: Timestamp = 0
            if let firstItem = orderedItems.first, let tab = firstItem as? Tab {
                timestamp = tab.firstCreatedTime
            }

            // Base timestamp on score to order historyHighlight properly
            if let firstItem = orderedItems.first, let highlight = firstItem as? HistoryHighlight {
                timestamp = Date.now() - Timestamp(highlight.score)
            }

            return ASGroup<T>(searchTerm: $0.key.capitalized, groupedItems: orderedItems, timestamp: timestamp)
        }
    }

    /// Orders items in a group, chronologically, in an ascending order
    ///
    /// - Parameter group: A group in which items must be sorted
    /// - Returns: The items in the group, sorted chronologically, in ascending order
    private static func orderItemsIn<T: Equatable>(group: [T]) -> [T] {
        return group.sorted {
            if let firstTab = $0 as? Tab, let secondTab = $1 as? Tab {
                return firstTab.firstCreatedTime < secondTab.firstCreatedTime
            } else if let firstSite = $0 as? Site, let secondSite = $1 as? Site {
                let firstSiteATimestamp = TimeInterval.fromMicrosecondTimestamp(firstSite.latestVisit?.date ?? 0)
                let secondSiteTimestamp = TimeInterval.fromMicrosecondTimestamp(secondSite.latestVisit?.date ?? 0)
                return firstSiteATimestamp < secondSiteTimestamp
            } else if let firstHighlight = $0 as? HistoryHighlight, let secondHighlight = $1 as? HistoryHighlight {
                return firstHighlight.score > secondHighlight.score
            } else {
                fatalError("Error: We should never pass a type \(T.self) to this function.")
            }
        }
    }

    /// Orders ASGroups based on their timestamp, according to the desired order.
    ///
    /// - Parameters:
    ///   - groups: An `ASGroup` of type `T`
    ///   - order: Generally, this would be either `.orderedAscending` or `.orderedDescending`
    ///   depending on what order we want to get the group. `.orderedSame` is possible
    ///   as well, but it just returns the exact same groups as the function was passed
    ///   with no changes.
    /// - Returns: The passed in group, sorted according to its `ASGroup<T>.timestamp` property
    private static func order<T: Equatable>(groups: [ASGroup<T>], using order: ComparisonResult) -> [ASGroup<T>] {
        switch order {
        case .orderedAscending:
            return groups.sorted { $0.timestamp < $1.timestamp }
        case .orderedDescending:
            return groups.sorted { $0.timestamp > $1.timestamp }
        case .orderedSame:
            return groups
        }
    }
}

class StopWatchTimer {
    private var timer: Timer?
    var isPaused = true
    // Recorded in seconds
    var elapsedTime: Int32 = 0

    func startOrResume() {
        timer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(incrementValue),
            userInfo: nil,
            repeats: true
        )
    }

    @objc
    func incrementValue() {
        elapsedTime += 1
    }

    func pauseOrStop() {
        timer?.invalidate()
    }

    func resetTimer() {
        elapsedTime = 0
        timer = nil
    }
}
