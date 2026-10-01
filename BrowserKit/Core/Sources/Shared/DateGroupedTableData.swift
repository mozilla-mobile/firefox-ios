// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

private func getDate(hourOffset: Int) -> Date {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.year, .month, .day, .hour], from: Date())
    let today = calendar.date(from: components)!
    return calendar.date(byAdding: .hour, value: hourOffset, to: today)!
}

public struct DateGroupedTableData<T: Equatable> {
    // Timestamps at which we want the data to be split
    var timestamps: [TimeInterval] = []

    // Data associated with timestamps -- in each section
    var timestampData: [[(item: T, timing: TimeInterval)]] = []

    var timestampDataNumSections: Int {
        return timestampData.count
    }

    public var isEmpty: Bool {
        return timestampData.allSatisfy { $0.isEmpty }
    }

    public init(includeLastHour: Bool = false) {
        var timestamps: [TimeInterval] = []
        if includeLastHour {
            timestamps.append(Date().lastHour.timeIntervalSince1970) // 1 hour ago
        }
        timestamps.append(contentsOf: [
            getDate(hourOffset: 24 * -1).timeIntervalSince1970, // 24 hours ago
            getDate(hourOffset: 24 * -7).timeIntervalSince1970, // 7 days ago
            getDate(hourOffset: 24 * -28).timeIntervalSince1970]) // 4 weeks ago

        self.init(timestamps: timestamps)
    }

    // Timestamps should be ordered chronolgically
    public init(timestamps: [TimeInterval]) {
        self.timestamps = timestamps
        // Arrays maintaining data, split by timestamp. Additional array included for elements older than the last timestamp
        timestampData = Array(repeating: [(item: T, timing: TimeInterval)](), count: timestamps.count + 1)
    }

    @discardableResult
    public mutating func add(_ item: T, timestamp: TimeInterval) -> IndexPath {
        for i in 0..<timestamps.count where timestamp > timestamps[i] {
                timestampData[i].append((item, timestamp))
                return IndexPath(row: timestampData[i].count - 1, section: i)
        }
        // if we don't match any of the timestamps above, return the older data
        timestampData[timestampDataNumSections - 1].append((item, timestamp))
        return IndexPath(row: timestampData[timestampDataNumSections - 1].count - 1, section: timestampDataNumSections - 1)
    }

    public mutating func remove(_ item: T) {
        for i in 0..<timestampDataNumSections {
            if let index = timestampData[i].firstIndex(where: { item == $0.item }) {
                timestampData[i].remove(at: index)
                return
            }
        }
    }

    public func numberOfItemsForSection(_ section: Int) -> Int {
        guard section >= 0 && section < timestampDataNumSections else {return 0}
        return timestampData[section].count
    }

    public func itemsForSection(_ section: Int) -> [T] {
        guard section >= 0 && section < timestampDataNumSections else {return []}
        return timestampData[section].map({ $0.item })
    }

    /// Returns all currently fetched items in a single array: `[T.item]`.
    public func allItems() -> [T] {
        return timestampData.flatMap({ $0 }).map { $0.item }
    }
}
