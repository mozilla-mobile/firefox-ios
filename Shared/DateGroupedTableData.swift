// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

fileprivate func getDate(dayOffset: Int) -> Date {
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

    var today: [(T, TimeInterval)] = []
    var yesterday: [(T, TimeInterval)] = []
    var lastWeek: [(T, TimeInterval)] = []
    var lastMonth: [(T, TimeInterval)] = []
    var older: [(T, TimeInterval)] = []

    public var isEmpty: Bool {
        return today.isEmpty && yesterday.isEmpty && lastWeek.isEmpty && lastMonth.isEmpty && older.isEmpty
    }

    public init() {}

    @discardableResult mutating public func add(_ item: T, timestamp: TimeInterval) -> IndexPath {
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

    mutating public func remove(_ item: T) {
        if let index = today.firstIndex(where: { item == $0.0 }) {
            today.remove(at: index)
        } else if let index = yesterday.firstIndex(where: { item == $0.0 }) {
            yesterday.remove(at: index)
        } else if let index = lastWeek.firstIndex(where: { item == $0.0 }) {
            lastWeek.remove(at: index)
        } else if let index = lastMonth.firstIndex(where: { item == $0.0 }) {
            lastMonth.remove(at: index)
        } else if let index = older.firstIndex(where: { item == $0.0 }) {
            older.remove(at: index)
        }
    }

    public func numberOfItemsForSection(_ section: Int) -> Int {
        switch section {
        case 0:
            return today.count
        case 1:
            return yesterday.count
        case 2:
            return lastWeek.count
        case 3:
            return lastMonth.count
        default:
            return older.count
        }
    }

    public func itemsForSection(_ section: Int) -> [T] {
        switch section {
        case 0:
            return today.map({ $0.0 })
        case 1:
            return yesterday.map({ $0.0 })
        case 2:
            return lastWeek.map({ $0.0 })
        case 3:
            return lastMonth.map({ $0.0 })
        default:
            return older.map({ $0.0 })
        }
    }
}
