// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Decides which onboarding cards are due
/// "Day N" is the Nth distinct calendar day the user opens the app
struct OnboardingCardScheduler {
    private let prefs: Prefs
    private let schedule: [Int: [OnboardingCard]]
    private let dateProvider: () -> Date

    init(
        prefs: Prefs,
        schedule: [Int: [OnboardingCard]] = OnboardingCardSchedule.cardsByDay,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.prefs = prefs
        self.schedule = schedule
        self.dateProvider = dateProvider
    }

    /// The current active-day number
    var currentActiveDay: Int {
        return Int(prefs.intForKey(PrefsKeys.onboardingActiveDayCount) ?? 0)
    }

    /// Advances the active-day counter at most once per calendar day
    func recordActiveDayIfNeeded() {
        let today = dayKey(for: dateProvider())
        let storedCount = currentActiveDay
        if let last = prefs.intForKey(PrefsKeys.onboardingLastActiveDate), Int(last) == today {
            return
        }
        let newCount = storedCount + 1
        prefs.setInt(Int32(newCount), forKey: PrefsKeys.onboardingActiveDayCount)
        prefs.setInt(Int32(today), forKey: PrefsKeys.onboardingLastActiveDate)
    }

    /// Returns the current active days cards and records them as shown
    /// Returns an empty array when nothing is due
    func consumeDueCards() -> [OnboardingCard] {
        let day = currentActiveDay
        let cards = schedule[day] ?? []
        guard !cards.isEmpty, lastCardActiveDay != day else { return [] }
        prefs.setInt(Int32(day), forKey: PrefsKeys.onboardingLastCardActiveDay)
        return cards
    }

    // MARK: - Debug helpers

    // Clears progress so the schedule replays from the first active day.
    func reset() {
        prefs.removeObjectForKey(PrefsKeys.onboardingActiveDayCount)
        prefs.removeObjectForKey(PrefsKeys.onboardingLastActiveDate)
        prefs.removeObjectForKey(PrefsKeys.onboardingLastCardActiveDay)
    }

    // Advances the counter by one and clears the shown marker, so the new day's card is
    // due the next time onboarding is checked
    func advanceOneDay() {
        prefs.setInt(Int32(currentActiveDay + 1), forKey: PrefsKeys.onboardingActiveDayCount)
        prefs.setInt(Int32(dayKey(for: dateProvider())), forKey: PrefsKeys.onboardingLastActiveDate)
        prefs.removeObjectForKey(PrefsKeys.onboardingLastCardActiveDay)
    }

    // Makes the next app launch count as a new active day
    func simulateNextDay() {
        prefs.setInt(Int32(previousDayKey()), forKey: PrefsKeys.onboardingLastActiveDate)
    }

    // Jumps straight to <day>, so the next app launch advances the counter to it
    func jump(toDay day: Int) {
        prefs.setInt(Int32(day - 1), forKey: PrefsKeys.onboardingActiveDayCount)
        prefs.setInt(Int32(previousDayKey()), forKey: PrefsKeys.onboardingLastActiveDate)
        prefs.removeObjectForKey(PrefsKeys.onboardingLastCardActiveDay)
    }

    // MARK: - Private

    private var lastCardActiveDay: Int {
        return Int(prefs.intForKey(PrefsKeys.onboardingLastCardActiveDay) ?? 0)
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
