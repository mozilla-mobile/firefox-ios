// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Core
import Shared
import Common

final class PushBackInstallation: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Push back installation by 3 days (needs restart).", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Calendar.current.date(byAdding: .day, value: -3, to: User.shared.install).map {
            User.shared.install = $0
        }
    }
}

final class ToggleImpactIntro: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Toggle - Show Impact intro", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        let isOn = User.shared.shouldShowImpactIntro
        return NSAttributedString(string: isOn ? "True" : "False", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.shouldShowImpactIntro ? User.shared.hideImpactIntro() : User.shared.showImpactIntro()
        settings.tableView.reloadData()
    }
}

final class ShowTour: HiddenSetting, WelcomeDelegate {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Show Intro", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
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
        return NSAttributedString(string: "Debug: Referral Code \(User.shared.referrals.code ?? "-")", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
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
        return NSAttributedString(string: "Debug: Add Referral", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
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
        return NSAttributedString(string: "Debug: Add Referral Claim", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
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
        return NSAttributedString(string: "Debug: Set search count to 0", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(User.shared.searchCount)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.searchCount = 0
        self.settings.tableView.reloadData()
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }
}

final class ChangeSearchCount: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Increase search count by 10", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "\(User.shared.searchCount)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        User.shared.searchCount += 10
        self.settings.tableView.reloadData()
        NotificationCenter.default.post(name: .HomePanelPrefsChanged, object: nil)
    }
}

final class UnleashDefaultBrowserSetting: HiddenSetting {
    override var title: NSAttributedString? {

        return NSAttributedString(string: "Debug: Unleash Reset", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        let variant = Unleash.getVariant(.defaultBrowser).name

        return NSAttributedString(string: "\(variant) (Click to reset)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
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
                navigationController?.topViewController?.show(alert, sender: nil)
            }
        }
    }
}

final class EngagementServiceIdentifierSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Engagement Service Identifier parameter", attributes: [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.tableView.rowText]
        
        guard let identifier = ClientEngagementService.shared.identifier else {
            return NSAttributedString(string: "n/a", attributes: attributes)
        }
        let variant = Unleash.getVariant(.defaultBrowser).name
        return NSAttributedString(string: "\(identifier) (Click to copy)", attributes: attributes)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let identifier = ClientEngagementService.shared.identifier else { return }
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = identifier
    }
}

