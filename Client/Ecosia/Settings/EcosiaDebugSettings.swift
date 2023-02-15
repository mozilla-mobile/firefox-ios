// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Core
import Shared

final class PushBackInstallation: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Push back installation by 3 days (needs restart).", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Calendar.current.date(byAdding: .day, value: -3, to: User.shared.install).map {
            User.shared.install = $0
        }
    }
}

final class ToggleBrandRefreshIntro: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Toggle - Show Rebrand intro", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        let isOn = User.shared.showsRebrandIntro
        return NSAttributedString(string: isOn ? "True" : "False", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.showsRebrandIntro ? User.shared.hideRebrandIntro() : User.shared.showRebrandIntro()
        settings.tableView.reloadData()
    }
}

final class ToggleCounterIntro: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Toggle - Show Counter intro", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        let isOn = User.shared.showsCounterIntro
        return NSAttributedString(string: isOn ? "True" : "False", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.showsCounterIntro ? User.shared.hideCounterIntro() : User.shared.showCounterIntro()
        settings.tableView.reloadData()
    }
}

final class ShowTour: HiddenSetting, WelcomeDelegate {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Show Intro", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let welcome = Welcome(delegate: self)
        welcome.modalPresentationStyle = .fullScreen
        welcome.modalTransitionStyle = .coverVertical
        navigationController?.present(welcome, animated: true)
    }

    func welcomeDidFinish(_ welcome: Welcome) {
        welcome.dismiss(animated: true, completion: nil)
    }
}


final class CreateReferralCode: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Referral Code \(User.shared.referrals.code ?? "-")", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
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
        return NSAttributedString(string: "Debug: Add Referral", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
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
        return NSAttributedString(string: "Debug: Add Referral Claim", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
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
        return NSAttributedString(string: "Debug: Set search count to 0", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(User.shared.treeCount)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.treeCount = 0
        self.settings.tableView.reloadData()
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }
}

final class ChangeSearchCount: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Increase search count by 10", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(User.shared.treeCount)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.treeCount += 10
        self.settings.tableView.reloadData()
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }
}

final class UnleashDefaultBrowserSetting: HiddenSetting {
    override var title: NSAttributedString? {

        return NSAttributedString(string: "Debug: Unleash default browser variant", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        let variant = Unleash.getVariant(.defaultBrowser).name

        return NSAttributedString(string: "\(variant) (Click to reset)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Task {
            do {
                _ = try await Unleash.reset(env: .staging)
            } catch {
                debugPrint(error)
            }
            await MainActor.run {
                self.settings.tableView.reloadData()

                let alert = AlertController(title: "New variant assigned", message: "It might be the old one though", preferredStyle: .alert)
                navigationController?.topViewController?.present(alert, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        alert.dismiss(animated: true)
                    }
                }
            }
        }
    }
}
