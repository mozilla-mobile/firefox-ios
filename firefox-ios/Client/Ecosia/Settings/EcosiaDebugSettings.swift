// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared
import Common
import Ecosia

final class PushBackInstallation: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Push back installation by 3 days (needs restart).", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Calendar.current.date(byAdding: .day, value: -3, to: User.shared.install).map {
            User.shared.install = $0
        }
    }
}

final class ToggleImpactIntro: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Toggle - Show Impact intro", attributes: [:])
    }

    override var status: NSAttributedString? {
        let isOn = User.shared.shouldShowImpactIntro
        return NSAttributedString(string: isOn ? "True" : "False", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if User.shared.shouldShowImpactIntro {
            User.shared.hideImpactIntro()
        } else {
            User.shared.showImpactIntro()
        }
        settings.tableView.reloadData()
    }
}

final class ToggleDefaultBrowserPromo: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Toggle - Show Default Browser Promo", attributes: [:])
    }

    override var status: NSAttributedString? {
        let introSeen = profile.prefs.intForKey(PrefsKeys.IntroSeen) != nil
        return NSAttributedString(string: introSeen ? "False (click to reset)" : "True", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        profile.prefs.removeObjectForKey(PrefsKeys.IntroSeen)
        settings.tableView.reloadData()
    }

    let profile: Profile
    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }
}

final class ShowTour: HiddenSetting, WelcomeDelegate {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Show Intro", attributes: [:])
    }

    let windowUUID: WindowUUID
    init(settings: SettingsTableViewController, windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(settings: settings)
    }

    var parentPresenter: UIViewController?
    override func onClick(_ navigationController: UINavigationController?) {
        let welcome = Welcome(delegate: self, windowUUID: windowUUID)
        welcome.modalPresentationStyle = .fullScreen
        welcome.modalTransitionStyle = .coverVertical
        let presentingViewController = navigationController?.presentingViewController
        navigationController?.dismiss(animated: true) {
            presentingViewController?.present(welcome, animated: true)
        }
    }

    func welcomeDidFinish(_ welcome: Welcome) {
        if let presentedTour = welcome.presentedViewController {
            presentedTour.dismiss(animated: true) {
                welcome.dismiss(animated: true)
            }
        } else {
            welcome.dismiss(animated: true)
        }
    }
}

final class CreateReferralCode: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Referral Code \(User.shared.referrals.code ?? "-")", attributes: [:])
    }

    override var status: NSAttributedString? {
        return .init(string: "Toggle to create or erase code")
    }

    override func onClick(_ navigationController: UINavigationController?) {

        if User.shared.referrals.code == nil {
            User.shared.referrals.code = "TEST123"

            let alertTitle = "Code created"
            let alert = AlertController(title: alertTitle, message: User.shared.referrals.code, preferredStyle: .alert)
            navigationController?.topViewController?.present(alert, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    alert.dismiss(animated: true)
                }
                self.settings.tableView.reloadData()
            }
        } else {
            User.shared.referrals.code = nil

            let alert = AlertController(title: "Code erased!", message: "Reopen app to create new one", preferredStyle: .alert)
            navigationController?.topViewController?.present(alert, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    alert.dismiss(animated: true)
                }
                self.settings.tableView.reloadData()
            }
        }
    }
}

final class AddReferral: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Add Referral", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.referrals.claims += 1

        let alertTitle = "Referral count increased by one."
        let alert = AlertController(title: alertTitle, message: "Open NTP to see spotlight", preferredStyle: .alert)
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true)
            }
        }
    }
}

final class AddClaim: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Add Referral Claim", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.referrals.isClaimed = true
        User.shared.referrals.isNewClaim = true

        let alertTitle = "User got referred."
        let alert = AlertController(title: alertTitle, message: "Open NTP to see claim", preferredStyle: .alert)
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true)
            }
        }
    }
}

final class ResetSearchCount: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Set search count to 0", attributes: [:])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(User.shared.searchCount)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.searchCount = 0
        self.settings.tableView.reloadData()
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }
}

final class ChangeSearchCount: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Increase search count by 10", attributes: [:])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(User.shared.searchCount)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.searchCount += 10
        self.settings.tableView.reloadData()
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }
}

final class ResetDefaultBrowserNudgeCard: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Makes the Default Browser nudge card visible again", attributes: [:])
    }

    override var status: NSAttributedString? {
        let status = "\(User.shared.shouldShowDefaultBrowserSettingNudgeCard)"
        let suggestion = User.shared.shouldShowDefaultBrowserSettingNudgeCard ? "" : " (Click to show)"
        return NSAttributedString(string: "Card visible: \(status)\(suggestion)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard !User.shared.shouldShowDefaultBrowserSettingNudgeCard else { return }
        User.shared.showDefaultBrowserSettingNudgeCard()
        self.settings.settings = self.settings.generateSettings()
        self.settings.tableView.reloadData()
    }
}

final class ResetAccountImpactNudgeCard: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Makes the Account Impact nudge card visible again", attributes: [:])
    }

    override var status: NSAttributedString? {
        let status = "\(User.shared.shouldShowAccountImpactNudgeCard)"
        let suggestion = User.shared.shouldShowAccountImpactNudgeCard ? "" : " (Click to show)"
        return NSAttributedString(string: "Card visible: \(status)\(suggestion)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard !User.shared.shouldShowAccountImpactNudgeCard else { return }
        User.shared.showAccountImpactNudgeCard()
        self.settings.settings = self.settings.generateSettings()
        self.settings.tableView.reloadData()
    }
}

class UnleashVariantResetSetting: HiddenSetting {
    var titleName: String? { return nil }
    var variant: Unleash.Variant? { return nil }
    var unleashEnabled: Bool? { return nil }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Unleash \(titleName ?? "Unknown") variant", attributes: [:])
    }

    override var status: NSAttributedString? {
        var statusName = variant?.name ?? "Unknown"
        if statusName == "Unknown", let unleashEnabled = unleashEnabled {
            statusName = unleashEnabled ? "enabled" : "disabled"
        }
        return NSAttributedString(string: "\(statusName) (Click to reset)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Task {
            do {
                _ = try await Unleash.reset(env: .current, appVersion: AppInfo.ecosiaAppVersion)
            } catch {
                debugPrint(error)
            }
            await MainActor.run {
                self.settings.tableView.reloadData()
                let alert = AlertController(title: "Unleash reset ✅",
                                            message: "The local Unleash cache has been wiped out",
                                            preferredStyle: .alert)
                alert.addAction(.init(title: "Ok", style: .default))
                navigationController?.topViewController?.present(alert, animated: true)
            }
        }
    }
}

final class UnleashBrazeIntegrationSetting: UnleashVariantResetSetting {
    override var titleName: String? {
        "Braze Integration"
    }

    override var unleashEnabled: Bool? {
        Unleash.isEnabled(.brazeIntegration)
    }
}

final class UnleashNativeSRPVAnalyticsSetting: UnleashVariantResetSetting {
    override var titleName: String? {
        "Native SRPV Analytics"
    }

    override var unleashEnabled: Bool? {
        Unleash.isEnabled(.nativeSRPVAnalytics)
    }
}

final class UnleashAISearchMVPSetting: UnleashVariantResetSetting {
    override var titleName: String? {
        "AI Search MVP"
    }

    override var variant: Unleash.Variant? {
        Unleash.getVariant(.aiSearchMVP)
    }

    override var unleashEnabled: Bool? {
        Unleash.isEnabled(.aiSearchMVP)
    }
}

final class AnalyticsIdentifierSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Analytics Identifier", attributes: [:])
    }

    var analyticsIdentifier: String { User.shared.analyticsId.uuidString }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(analyticsIdentifier) (Click to copy)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        UIPasteboard.general.string = analyticsIdentifier
    }
}

final class UnleashIdentifierSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Unleash Identifier", attributes: [:])
    }

    var analyticsIdentifier: String { Unleash.userId.uuidString }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(Unleash.userId.uuidString) (Click to copy)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        UIPasteboard.general.string = Unleash.userId.uuidString
    }
}

final class AnalyticsStagingUrlSetting: HiddenSetting {

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Toggle - Swap Analytics Staging URL", attributes: [:])
    }

    override var status: NSAttributedString? {
        let isOn = Analytics.shouldUseMicroInstance
        let snowplowInstance = isOn ? "Micro" : "Mini"
        return NSAttributedString(string: "\(snowplowInstance) instance (Click to toggle)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Analytics.shouldUseMicroInstance.toggle()
        settings.tableView.reloadData()
    }
}

final class SimulateAuthErrorSetting: HiddenSetting {
    /// UserDefaults key for storing auth error simulation state
    /// Note: Persists across app restarts - toggle again to disable
    public static let debugKey = "DebugSimulateAuthError"

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Toggle - Simulate Auth Error", attributes: [:])
    }

    override var status: NSAttributedString? {
        let isEnabled = Self.isEnabled
        let status = isEnabled ? "ON (Auth will fail)" : "OFF"
        return NSAttributedString(string: "\(status) (Click to toggle)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let currentValue = Self.isEnabled
        UserDefaults.standard.set(!currentValue, forKey: Self.debugKey)
        settings.tableView.reloadData()

        let alert = AlertController(
            title: !currentValue ? "Auth Error Enabled ✅" : "Auth Error Disabled ✅",
            message: !currentValue ? "Next login/logout will fail with an error." : "Auth errors disabled.",
            preferredStyle: .alert
        )
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    /// Check if auth error simulation is enabled
    public static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: debugKey)
    }
}

final class SimulateImpactAPIErrorSetting: HiddenSetting {
    /// UserDefaults key for storing impact API error simulation state
    /// Note: Persists across app restarts - toggle again to disable
    public static let debugKey = "DebugSimulateImpactAPIError"

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Toggle - Simulate Impact API Error", attributes: [:])
    }

    override var status: NSAttributedString? {
        let isEnabled = Self.isEnabled
        let status = isEnabled ? "ON (API will fail)" : "OFF"
        return NSAttributedString(string: "\(status) (Click to toggle)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let currentValue = Self.isEnabled
        UserDefaults.standard.set(!currentValue, forKey: Self.debugKey)
        settings.tableView.reloadData()

        let alert = AlertController(
            title: !currentValue ? "Impact API Error Enabled ✅" : "Impact API Error Disabled ✅",
            message: !currentValue ? "Next impact API call will fail." : "Impact API errors disabled.",
            preferredStyle: .alert
        )
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    /// Check if impact API error simulation is enabled
    public static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: debugKey)
    }
}

// MARK: - Seed & Level Debug Settings

final class DebugAddSeedsLoggedOut: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Add 1 Seed (Logged Out) - 10s delay", attributes: [:])
    }

    override var status: NSAttributedString? {
        let maxSeeds = UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers
        let currentSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let remaining = max(0, maxSeeds - currentSeeds)
        return NSAttributedString(string: "\(currentSeeds)/\(maxSeeds) seeds | \(remaining) remaining (cap always ON)", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Check if user is logged in
        guard !EcosiaAuthenticationService.shared.isLoggedIn else {
            let errorAlert = AlertController(
                title: "Already Logged In",
                message: "This feature is for logged-out users only. Please use the logged-in debug options instead.",
                preferredStyle: .alert
            )
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            navigationController?.topViewController?.present(errorAlert, animated: true)
            return
        }

        let currentSeeds = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
        let maxSeeds = UserDefaultsSeedProgressManager.maxSeedsForLoggedOutUsers

        // Check if already at cap
        if currentSeeds >= maxSeeds {
            let alert = AlertController(
                title: "Seed Cap Reached",
                message: "Already at maximum (\(maxSeeds) seeds) for logged-out users",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            navigationController?.topViewController?.present(alert, animated: true)
            return
        }

        let alert = AlertController(
            title: "Seed Queued ✅",
            message: "Navigate to home or open Account Impact within 10 seconds to see animation",
            preferredStyle: .alert
        )

        navigationController?.topViewController?.present(alert, animated: true) {
            // Dismiss alert after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                alert.dismiss(animated: true)
            }

            // Add seed after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                UserDefaultsSeedProgressManager.addSeeds(1)
                EcosiaLogger.accounts.info("Debug: Added 1 seed for logged-out user")
            }
        }
    }
}

final class DebugAddSeedsLoggedIn: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Add 5 Seeds (Logged In) - 10s delay", attributes: [:])
    }

    override var status: NSAttributedString? {
        let currentSeeds = EcosiaAuthUIStateProvider.shared.seedCount
        return NSAttributedString(string: "Current: \(currentSeeds) seeds", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard EcosiaAuthenticationService.shared.isLoggedIn else {
            let errorAlert = AlertController(
                title: "Not Logged In",
                message: "Please log in first to use this feature",
                preferredStyle: .alert
            )
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            navigationController?.topViewController?.present(errorAlert, animated: true)
            return
        }

        let alert = AlertController(
            title: "Seeds Queued ✅",
            message: "Navigate to home or open Account Impact within 10 seconds to see animation",
            preferredStyle: .alert
        )

        navigationController?.topViewController?.present(alert, animated: true) {
            // Dismiss alert after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                alert.dismiss(animated: true)
            }

            // Add seeds after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                Task { @MainActor in
                    EcosiaAuthUIStateProvider.shared.debugAddSeeds(5)
                }
            }
        }
    }
}

final class DebugForceLevelUp: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Force Level Up (Logged In) - 10s delay", attributes: [:])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "Triggers sparkle animation", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard EcosiaAuthenticationService.shared.isLoggedIn else {
            let errorAlert = AlertController(
                title: "Not Logged In",
                message: "Please log in first to use this feature",
                preferredStyle: .alert
            )
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            navigationController?.topViewController?.present(errorAlert, animated: true)
            return
        }

        let alert = AlertController(
            title: "Level Up Queued ✅",
            message: "Navigate to Account Impact within 10 seconds to see level-up animation",
            preferredStyle: .alert
        )

        navigationController?.topViewController?.present(alert, animated: true) {
            // Dismiss alert after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                alert.dismiss(animated: true)
            }

            // Trigger level-up animation after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                Task { @MainActor in
                    EcosiaAuthUIStateProvider.shared.debugTriggerLevelUpAnimation()
                }
            }
        }
    }
}

final class DebugAddCustomSeeds: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Add Custom Seeds (Logged In)", attributes: [:])
    }

    override var status: NSAttributedString? {
        let currentSeeds = EcosiaAuthUIStateProvider.shared.seedCount
        return NSAttributedString(string: "Current: \(currentSeeds) seeds | Input custom amount", attributes: [:])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard EcosiaAuthenticationService.shared.isLoggedIn else {
            let errorAlert = AlertController(
                title: "Not Logged In",
                message: "Please log in first to use this feature",
                preferredStyle: .alert
            )
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
            navigationController?.topViewController?.present(errorAlert, animated: true)
            return
        }

        let alert = AlertController(
            title: "Add Custom Seeds",
            message: "Enter the number of seeds to add (1-1000)",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Number of seeds"
            textField.keyboardType = .numberPad
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let text = textField.text,
                  let seedCount = Int(text),
                  seedCount > 0 && seedCount <= 1000 else {
                let errorAlert = AlertController(
                    title: "Invalid Input",
                    message: "Please enter a number between 1 and 1000",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                navigationController?.topViewController?.present(errorAlert, animated: true)
                return
            }

            self?.addCustomSeeds(count: seedCount, navigationController: navigationController)
        })

        navigationController?.topViewController?.present(alert, animated: true)
    }

    private func addCustomSeeds(count: Int, navigationController: UINavigationController?) {
        let confirmAlert = AlertController(
            title: "Seeds Queued ✅",
            message: "Adding \(count) seeds in 10 seconds. Navigate to home or open Account Impact to see animation.",
            preferredStyle: .alert
        )

        navigationController?.topViewController?.present(confirmAlert, animated: true) {
            // Dismiss alert after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                confirmAlert.dismiss(animated: true)
            }

            // Add seeds after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                Task { @MainActor in
                    EcosiaAuthUIStateProvider.shared.debugAddSeeds(count)
                }
            }
        }
    }
}
