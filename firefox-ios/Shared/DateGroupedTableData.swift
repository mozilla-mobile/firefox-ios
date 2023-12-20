// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

private func getDate(dayOffset: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.year, .month, .day], from: Date())
    let today = calendar.date(from: components)!
    return calendar.date(byAdding: .day, value: dayOffset, to: today)!
}

public struct DateGroupedTableData<T: Equatable> {
    let todayTimestamp = getDate(dayOffset: 0).timeIntervalSince1970
    let yesterdayTimestamp = getDate(dayOffset: -1).timeIntervalSince1970
    let lastWeekTimestamp = getDate(dayOffset: -7).timeIntervalSince1970
    let lastMonthTimestamp = getDate(dayOffset: -30).timeIntervalSince1970

    var today: [(item: T, timing: TimeInterval)] = []
    var yesterday: [(item: T, timing: TimeInterval)] = []
    var lastWeek: [(item: T, timing: TimeInterval)] = []
    var lastMonth: [(item: T, timing: TimeInterval)] = []
    var older: [(item: T, timing: TimeInterval)] = []

    public var isEmpty: Bool {
        return today.isEmpty && yesterday.isEmpty && lastWeek.isEmpty && lastMonth.isEmpty && older.isEmpty
    }

    public init() {}

    @discardableResult
    public mutating func add(_ item: T, timestamp: TimeInterval) -> IndexPath {
        if timestamp > todayTimestamp {
            today.append((item, timestamp))
            return IndexPath(row: today.count - 1, section: 0)
        } else if timestamp > yesterdayTimestamp {
            yesterday.append((item, timestamp))
            return IndexPath(row: yesterday.count - 1, section: 1)
        } else if timestamp > lastWeekTimestamp {
            lastWeek.append((item, timestamp))
            return IndexPath(row: lastWeek.count - 1, section: 2)
        } else if timestamp > lastMonthTimestamp {
            lastMonth.append((item, timestamp))
            return IndexPath(row: lastMonth.count - 1, section: 3)
        } else {
            older.append((item, timestamp))
            return IndexPath(row: older.count - 1, section: 4)
        }
    }

    public mutating func remove(_ item: T) {
        if let index = today.firstIndex(where: { item == $0.item }) {
            today.remove(at: index)
        } else if let index = yesterday.firstIndex(where: { item == $0.item }) {
            yesterday.remove(at: index)
        } else if let index = lastWeek.firstIndex(where: { item == $0.item }) {
            lastWeek.remove(at: index)
        } else if let index = lastMonth.firstIndex(where: { item == $0.item }) {
            lastMonth.remove(at: index)
        } else if let index = older.firstIndex(where: { item == $0.item }) {
            older.remove(at: index)
        }
    }

    public func numberOfItemsForSection(_ section: Int) -> Int {
        switch section {
        case 0: return today.count
        case 1: return yesterday.count
        case 2: return lastWeek.count
        case 3: return lastMonth.count
        case 4: return older.count
        default: return 0
        }
    }

    public func itemsForSection(_ section: Int) -> [T] {
        switch section {
        case 0: return today.map({ $0.item })
        case 1: return yesterday.map({ $0.item })
        case 2: return lastWeek.map({ $0.item })
        case 3: return lastMonth.map({ $0.item })
        case 4: return older.map({ $0.item })
        default: return []
        }
    }

    /// Returns all currently fetched items in a single array: `[T.item]`.
    public func allItems() -> [T] {
        let allItems = (today + yesterday + lastWeek + lastMonth + older)
            .map { $0.item }

        return allItems
    }
}
