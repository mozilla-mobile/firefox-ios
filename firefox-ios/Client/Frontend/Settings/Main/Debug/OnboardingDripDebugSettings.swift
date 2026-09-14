// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared


class ResetOnboardingDripSetting: HiddenSetting {
    private weak var settingsDelegate: SharedSettingsDelegate?

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Reset Onboarding (day 1 + drip)")
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: SharedSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let prefs = settings.profile?.prefs else { return }
        OnboardingDripScheduler(prefs: prefs).reset()
        // Normal first-run onboarding (day 1)
        prefs.removeObjectForKey(PrefsKeys.IntroSeen)
        prefs.removeObjectForKey(PrefsKeys.OnboardingLastCardSeen)
        prefs.removeObjectForKey(PrefsKeys.onboardingDripActiveDayCount)
        // Notification card state, so the day-2 decline / homepage card replay from scratch
        // prefs.removeObjectForKey(PrefsKeys.onboardingNotificationsDeclined)
        // prefs.removeObjectForKey(PrefsKeys.onboardingNotificationCardDismissed)
        settingsDelegate?.askedToReload()
    }
}

class AdvanceOnboardingDripSetting: HiddenSetting {
    private weak var settingsDelegate: SharedSettingsDelegate?

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Onboarding Drip: simulate next day")
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: SharedSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let prefs = settings.profile?.prefs else { return }
        OnboardingDripScheduler(prefs: prefs).simulateNextDay()
        settingsDelegate?.askedToReload()
    }
}

class JumpToOnboardingDripDaySetting: HiddenSetting {
    private weak var settingsDelegate: SharedSettingsDelegate?
    private let day: Int

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Onboarding Drip: jump to day \(day)")
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: SharedSettingsDelegate,
         day: Int) {
        self.settingsDelegate = settingsDelegate
        self.day = day
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let prefs = settings.profile?.prefs else { return }
        OnboardingDripScheduler(prefs: prefs).jump(toDay: day)
        // Mark first-run onboarding as seen so the drip (which only runs post-day-1) shows the card.
        prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        settingsDelegate?.askedToReload()
    }
}
