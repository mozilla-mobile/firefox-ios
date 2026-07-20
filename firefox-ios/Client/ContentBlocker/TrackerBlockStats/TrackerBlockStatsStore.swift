// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Persists blocked-tracker counts long term, bucketed by ISO-8601 calendar
/// week and by category. Lifetime figures are derived by summing all buckets.
protocol TrackerBlockStatsStore {
    func record(category: BlocklistCategory, count: Int, date: Date)
    func lifetimeTotal() -> Int
    func lifetimeByCategory() -> [BlocklistCategory: Int]
    func weeklyTotal(for date: Date) -> Int
    func weeklyByCategory(for date: Date) -> [BlocklistCategory: Int]
    func reset()
}

/// Prefs-backed store that keeps the in-progress week separate from completed
/// weeks. `record` runs on a hot path (once per newly-blocked host), so it only
/// ever decodes/encodes the small, fixed-size current-week value. Completed
/// weeks are folded into the archive on a week rollover, an operation that
/// happens at most once per week, not per insert.
final class DefaultTrackerBlockStatsStoreUtility: TrackerBlockStatsStore {
    private let prefs: Prefs
    private let calendar: Calendar
    private let currentWeekKey: String
    private let archiveKey: String

    init(
        prefs: Prefs,
        calendar: Calendar = Calendar(identifier: .iso8601),
        currentWeekKey: String = PrefsKeys.TrackerBlockStatsCurrentWeek,
        archiveKey: String = PrefsKeys.TrackerBlockStatsArchive
    ) {
        self.prefs = prefs
        self.calendar = calendar
        self.currentWeekKey = currentWeekKey
        self.archiveKey = archiveKey
    }

    // MARK: - TrackerBlockStatsStore

    func record(category: BlocklistCategory, count: Int, date: Date) {
        guard count > 0 else { return }
        let (year, week) = isoYearWeek(for: date)

        var current = loadCurrentWeek()
        // A new week has started: retire the completed week into the archive.
        if let existing = current, existing.year != year || existing.week != week {
            archive(existing)
            current = nil
        }

        var bucket = current ?? TrackerBlockStatsBucket(year: year, week: week, counts: [:])
        bucket.counts[category.storageKey, default: 0] += count
        saveCurrentWeek(bucket)
    }

    func lifetimeTotal() -> Int {
        let archived = loadArchive().buckets.reduce(0) { $0 + $1.total }
        return archived + (loadCurrentWeek()?.total ?? 0)
    }

    func lifetimeByCategory() -> [BlocklistCategory: Int] {
        var buckets = loadArchive().buckets
        if let current = loadCurrentWeek() { buckets.append(current) }
        return aggregate(buckets: buckets)
    }

    func weeklyTotal(for date: Date) -> Int {
        return bucket(for: date)?.total ?? 0
    }

    func weeklyByCategory(for date: Date) -> [BlocklistCategory: Int] {
        guard let bucket = bucket(for: date) else { return [:] }
        return aggregate(buckets: [bucket])
    }

    func reset() {
        prefs.removeObjectForKey(currentWeekKey)
        prefs.removeObjectForKey(archiveKey)
    }

    // MARK: - Helpers

    private func isoYearWeek(for date: Date) -> (year: Int, week: Int) {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }

    private func bucket(for date: Date) -> TrackerBlockStatsBucket? {
        let (year, week) = isoYearWeek(for: date)
        if let current = loadCurrentWeek(), current.year == year, current.week == week {
            return current
        }
        return loadArchive().buckets.first { $0.year == year && $0.week == week }
    }

    private func archive(_ bucket: TrackerBlockStatsBucket) {
        guard bucket.total > 0 else { return }
        var data = loadArchive()
        if let index = data.buckets.firstIndex(where: { $0.year == bucket.year && $0.week == bucket.week }) {
            for (key, count) in bucket.counts {
                data.buckets[index].counts[key, default: 0] += count
            }
        } else {
            data.buckets.append(bucket)
        }
        saveArchive(data)
    }

    private func aggregate(buckets: [TrackerBlockStatsBucket]) -> [BlocklistCategory: Int] {
        var result = [BlocklistCategory: Int]()
        for bucket in buckets {
            for (storageKey, count) in bucket.counts {
                guard let category = BlocklistCategory(storageKey: storageKey) else { continue }
                result[category, default: 0] += count
            }
        }
        return result
    }

    // MARK: - Persistence

    private func loadCurrentWeek() -> TrackerBlockStatsBucket? {
        return decode(TrackerBlockStatsBucket.self, forKey: currentWeekKey)
    }

    private func saveCurrentWeek(_ bucket: TrackerBlockStatsBucket) {
        encode(bucket, forKey: currentWeekKey)
    }

    private func loadArchive() -> TrackerBlockStatsData {
        return decode(TrackerBlockStatsData.self, forKey: archiveKey) ?? TrackerBlockStatsData()
    }

    private func saveArchive(_ data: TrackerBlockStatsData) {
        encode(data, forKey: archiveKey)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let json = prefs.stringForKey(key),
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(type, from: data)
        else {
            return nil
        }
        return decoded
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let encoded = try? JSONEncoder().encode(value),
              let json = String(data: encoded, encoding: .utf8)
        else { return }
        prefs.setString(json, forKey: key)
    }
}
