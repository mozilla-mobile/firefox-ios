// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Persists blocked-tracker counts long term, keyed by category. Keeps the
/// in-progress ISO-8601 week separate from a single lifetime running total, and
/// records the date tracking first began. Lifetime figures are the running total
/// plus the current week.
protocol TrackerBlockStatsStore {
    func record(category: BlocklistCategory, count: Int, date: Date)
    func lifetimeTotal() -> Int
    func lifetimeByCategory() -> [BlocklistCategory: Int]
    func currentWeekTotal(for date: Date) -> Int
    func currentWeekByCategory(for date: Date) -> [BlocklistCategory: Int]
    func trackingStartDate() -> Date?
    func reset()
}

/// Prefs-backed store that keeps the in-progress week separate from a lifetime
/// running total. `record` runs on a hot path (once per newly-blocked host), so
/// it only ever decodes/encodes the small, fixed-size current-week value.
/// Completed weeks are folded into the running total on a week rollover, an
/// operation that happens at most once per week, not per insert. The running
/// total has no per-week identity, so storage stays a fixed size no matter how
/// long tracking has run.
final class DefaultTrackerBlockStatsStoreUtility: TrackerBlockStatsStore {
    private let prefs: Prefs
    private let calendar: Calendar
    private let currentWeekKey: String
    private let lifetimeKey: String
    private let startDateKey: String

    init(
        prefs: Prefs,
        calendar: Calendar = Calendar(identifier: .iso8601),
        currentWeekKey: String = PrefsKeys.TrackerBlockStatsCurrentWeek,
        lifetimeKey: String = PrefsKeys.TrackerBlockStatsLifetime,
        startDateKey: String = PrefsKeys.TrackerBlockStatsStartDate
    ) {
        self.prefs = prefs
        self.calendar = calendar
        self.currentWeekKey = currentWeekKey
        self.lifetimeKey = lifetimeKey
        self.startDateKey = startDateKey
    }

    // MARK: - TrackerBlockStatsStore

    func record(category: BlocklistCategory, count: Int, date: Date) {
        guard count > 0 else { return }
        setStartDateIfNeeded(date)
        let (year, week) = isoYearWeek(for: date)

        var current = loadCurrentWeek()
        // A new week has started: fold the completed week into the running total.
        if let existing = current, existing.year != year || existing.week != week {
            foldIntoLifetime(existing)
            current = nil
        }

        var bucket = current ?? TrackerBlockStatsBucket(year: year, week: week, counts: [:])
        bucket.counts[category.storageKey, default: 0] += count
        saveCurrentWeek(bucket)
    }

    func lifetimeTotal() -> Int {
        return loadLifetime().total + (loadCurrentWeek()?.total ?? 0)
    }

    func lifetimeByCategory() -> [BlocklistCategory: Int] {
        var counts = loadLifetime().counts
        if let current = loadCurrentWeek() {
            for (key, count) in current.counts {
                counts[key, default: 0] += count
            }
        }
        return aggregate(counts: counts)
    }

    func currentWeekTotal(for date: Date) -> Int {
        return currentWeekBucket(for: date)?.total ?? 0
    }

    func currentWeekByCategory(for date: Date) -> [BlocklistCategory: Int] {
        guard let bucket = currentWeekBucket(for: date) else { return [:] }
        return aggregate(counts: bucket.counts)
    }

    func trackingStartDate() -> Date? {
        guard let timestamp = prefs.timestampForKey(startDateKey) else { return nil }
        return Date.fromTimestamp(timestamp)
    }

    func reset() {
        prefs.removeObjectForKey(currentWeekKey)
        prefs.removeObjectForKey(lifetimeKey)
        prefs.removeObjectForKey(startDateKey)
    }

    // MARK: - Helpers

    private func isoYearWeek(for date: Date) -> (year: Int, week: Int) {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return (components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }

    /// Returns the stored current-week bucket only if it belongs to the ISO week
    /// of `date`. A stale bucket from a prior week (not yet rolled over because
    /// no new hit has been recorded) is treated as absent.
    private func currentWeekBucket(for date: Date) -> TrackerBlockStatsBucket? {
        let (year, week) = isoYearWeek(for: date)
        guard let current = loadCurrentWeek(), current.year == year, current.week == week else {
            return nil
        }
        return current
    }

    private func foldIntoLifetime(_ bucket: TrackerBlockStatsBucket) {
        guard bucket.total > 0 else { return }
        var lifetime = loadLifetime()
        for (key, count) in bucket.counts {
            lifetime.counts[key, default: 0] += count
        }
        saveLifetime(lifetime)
    }

    private func setStartDateIfNeeded(_ date: Date) {
        guard prefs.timestampForKey(startDateKey) == nil else { return }
        prefs.setTimestamp(date.toTimestamp(), forKey: startDateKey)
    }

    private func aggregate(counts: [String: Int]) -> [BlocklistCategory: Int] {
        var result = [BlocklistCategory: Int]()
        for (storageKey, count) in counts {
            guard let category = BlocklistCategory(storageKey: storageKey) else { continue }
            result[category, default: 0] += count
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

    private func loadLifetime() -> TrackerBlockStatsRunningTotal {
        return decode(TrackerBlockStatsRunningTotal.self, forKey: lifetimeKey) ?? TrackerBlockStatsRunningTotal()
    }

    private func saveLifetime(_ total: TrackerBlockStatsRunningTotal) {
        encode(total, forKey: lifetimeKey)
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
