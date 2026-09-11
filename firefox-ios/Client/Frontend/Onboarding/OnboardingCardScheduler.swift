// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Decides which onboarding cards are due
/// "Day N" is the Nth distinct calendar day the user opens the app
struct OnboardingDripScheduler {
    private let prefs: Prefs
    private let schedule: [Int: [OnboardingCard]]
    private let dateProvider: () -> Date

    init(
        prefs: Prefs,
        schedule: [Int: [OnboardingCard]] = OnboardingDripSchedule.cardsByDay,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.prefs = prefs
        self.schedule = schedule
        self.dateProvider = dateProvider
    }

    /// The current active-day number
    var currentActiveDay: Int {
        return Int(prefs.intForKey(PrefsKeys.onboardingDripActiveDayCount) ?? 0)
    }

    /// Advances the active-day counter at most once per calendar day
    func recordActiveDayIfNeeded() -> Int {
        let today = dayKey(for: dateProvider())
        let storedCount = currentActiveDay
        if let last = prefs.intForKey(PrefsKeys.onboardingDripLastActiveDate), Int(last) == today {
            return storedCount
        }
        let newCount = storedCount + 1
        prefs.setInt(Int32(newCount), forKey: PrefsKeys.onboardingDripActiveDayCount)
        prefs.setInt(Int32(today), forKey: PrefsKeys.onboardingDripLastActiveDate)
        return newCount
    }

    /// Returns the current active days cards and records them as shown
    /// Returns an empty array when nothing is due
    func consumeDueCards() -> [OnboardingCard] {
        let day = currentActiveDay
        let cards = schedule[day] ?? []
        guard !cards.isEmpty, lastCardActiveDay != day else { return [] }
        prefs.setInt(Int32(day), forKey: PrefsKeys.onboardingDripLastCardActiveDay)
        return cards
    }

    // MARK: - Debug helpers

    // Clears progress so the schedule replays from the first active day.
    func reset() {
        prefs.removeObjectForKey(PrefsKeys.onboardingDripActiveDayCount)
        prefs.removeObjectForKey(PrefsKeys.onboardingDripLastActiveDate)
        prefs.removeObjectForKey(PrefsKeys.onboardingDripLastCardActiveDay)
    }

    // Advances the counter by one and clears the shown marker, so the new day's card is
    // due the next time onboarding is checked
    func advanceOneDay() {
        prefs.setInt(Int32(currentActiveDay + 1), forKey: PrefsKeys.onboardingDripActiveDayCount)
        prefs.setInt(Int32(dayKey(for: dateProvider())), forKey: PrefsKeys.onboardingDripLastActiveDate)
        prefs.removeObjectForKey(PrefsKeys.onboardingDripLastCardActiveDay)
    }

    // Makes the next app launch count as a new active day
    func simulateNextDay() {
        prefs.setInt(Int32(previousDayKey()), forKey: PrefsKeys.onboardingDripLastActiveDate)
    }

    // Jumps straight to <day>, so the next app launch advances the counter to it
    func jump(toDay day: Int) {
        prefs.setInt(Int32(day - 1), forKey: PrefsKeys.onboardingDripActiveDayCount)
        prefs.setInt(Int32(previousDayKey()), forKey: PrefsKeys.onboardingDripLastActiveDate)
        prefs.removeObjectForKey(PrefsKeys.onboardingDripLastCardActiveDay)
    }

    // MARK: - Private

    private var lastCardActiveDay: Int {
        return Int(prefs.intForKey(PrefsKeys.onboardingDripLastCardActiveDay) ?? 0)
    }

    /// A comparable date key (e.g. 2026_09_03) used to detect a new active calendar day.
    private func dayKey(for date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return (comps.year ?? 0) * 10_000 + (comps.month ?? 0) * 100 + (comps.day ?? 0)
    }

    private func previousDayKey() -> Int {
        let now = dateProvider()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        return dayKey(for: yesterday)
    }
}
