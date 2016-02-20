/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SwiftKeychainWrapper

private let ImmediatelyInSeconds: Int32 = 0
private let OneMinuteInSeconds: Int32 = 1 * 60
private let FiveMinutesInSeconds: Int32 = 5 * 60
private let TenMinutesInSeconds: Int32 = 10 * 60
private let FifteenMinutesInSeconds: Int32 = 15 * 60
private let OneHourInSeconds: Int32 = 1 * 60 * 60

private let PrefKeyTouchIDEnabled = "authentication.touchIDEnabled"
private let PrefKeyRequirePasscodeInterval = "authentication.requirePasscodeInterval"

let KeychainKeyPasscode = "AppPasscode"

struct AuthenticationStrings {
    static let enterPasscode    = NSLocalizedString("Enter a passcode", tableName: "AuthenticationManager", comment: "Title for entering a passcode")
    static let reenterPasscode  = NSLocalizedString("Re-enter passcode", tableName: "AuthenticationManager", comment: "Title for re-entering a passcode")
    static let setPasscode      = NSLocalizedString("Set Passcode", tableName: "AuthenticationManager", comment: "Screen title for Set Passcode")
    static let turnOffPasscode  = NSLocalizedString("Turn Passcode Off", tableName: "AuthenticationManager", comment: "Title for setting to turn off passcode")
    static let turnOnPasscode   = NSLocalizedString("Turn Passcode On", tableName: "AuthenticationManager", comment: "Title for setting to turn on passcode")
    static let changePasscode   = NSLocalizedString("Change Passcode", tableName: "AuthenticationManager", comment: "Title for screen when changing your passcode")
    static let enterNewPasscode = NSLocalizedString("Enter a new passcode", tableName: "AuthenticationManager", comment: "Title for screen when updating your existin passcode")
}

private extension NSAttributedString {
    static func rowTitle(string: String) -> NSAttributedString {
        return NSAttributedString(string: string, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    static func disabledRowTitle(string: String) -> NSAttributedString {
        return NSAttributedString(string: string, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewDisabledRowTextColor])
    }
}

class TurnPasscodeOnSetting: Setting {
    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil) {
        super.init(title: NSAttributedString(string: AuthenticationStrings.turnOnPasscode, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
                   delegate: delegate)
    }

    override func onClick(navigationController: UINavigationController?) {
        // Navigate to passcode configuration screen
        let passcodeVC = PasscodeConfirmViewController.newPasscodeVC()
        passcodeVC.title = AuthenticationStrings.setPasscode
        let passcodeNav = UINavigationController(rootViewController: passcodeVC)
        navigationController?.presentViewController(passcodeNav, animated: true, completion: nil)
    }
}

class TurnPasscodeOffSetting: Setting {
    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil) {
        super.init(title: NSAttributedString(string: AuthenticationStrings.turnOffPasscode, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
                   delegate: delegate)
    }

    override func onClick(navigationController: UINavigationController?) {
        let passcodeVC = PasscodeConfirmViewController.removePasscodeVC()
        passcodeVC.title = AuthenticationStrings.turnOffPasscode
        let passcodeNav = UINavigationController(rootViewController: passcodeVC)
        navigationController?.presentViewController(passcodeNav, animated: true, completion: nil)
    }
}

class ChangePasscodeSetting: Setting {
    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil, enabled: Bool) {
        let attributedTitle: NSAttributedString = (enabled ?? false) ?
            NSAttributedString.rowTitle(AuthenticationStrings.changePasscode) :
            NSAttributedString.disabledRowTitle(AuthenticationStrings.changePasscode)

        super.init(title: attributedTitle,
                   delegate: delegate,
                   enabled: enabled)
    }

    override func onClick(navigationController: UINavigationController?) {
        let passcodeVC = PasscodeConfirmViewController.changePasscodeVC()
        passcodeVC.title = AuthenticationStrings.changePasscode
        let passcodeNav = UINavigationController(rootViewController: passcodeVC)
        navigationController?.presentViewController(passcodeNav, animated: true, completion: nil)
    }
}

class RequirePasscodeSetting: Setting {
    private let intervalLookup = [
        ImmediatelyInSeconds:       NSLocalizedString("Immediately", tableName: "AuthenticationManager", comment: "'Immediately' interval item for selecting when to require passcode"),
        OneMinuteInSeconds:         NSLocalizedString("After 1 minute", tableName: "AuthenticationManager", comment: "'After 1 minute' interval item for selecting when to require passcode"),
        FiveMinutesInSeconds:       NSLocalizedString("After 5 minutes", tableName: "AuthenticationManager", comment: "'After 5 minutes' interval item for selecting when to require passcode"),
        TenMinutesInSeconds:        NSLocalizedString("After 10 minutes", tableName: "AuthenticationManager", comment: "'After 10 minutes' interval item for selecting when to require passcode"),
        FifteenMinutesInSeconds:    NSLocalizedString("After 15 minutes", tableName: "AuthenticationManager", comment: "'After 15 minutes' interval item for selecting when to require passcode"),
        OneHourInSeconds:           NSLocalizedString("After 1 hour", tableName: "AuthenticationManager", comment: "'After 1 hour' interval item for selecting when to require passcode"),
    ]

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var style: UITableViewCellStyle { return .Value1 }

    override var status: NSAttributedString {
        if let interval = requireInterval, intervalTitle = intervalLookup[interval] {
            return NSAttributedString(string: intervalTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
        }
        return NSAttributedString(string: "")
    }

    private var requireInterval: Int32?

    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil, requireInterval: Int32? = nil, enabled: Bool? = nil) {
        let title = NSLocalizedString("Require Passcode", tableName: "AuthenticationManager", comment: "Title for setting to require a passcode")
        let attributedTitle = (enabled ?? true) ? NSAttributedString.rowTitle(title) : NSAttributedString.disabledRowTitle(title)
        super.init(title: attributedTitle,
                   delegate: delegate,
                   enabled: enabled)
        self.requireInterval = requireInterval
    }

    override func onClick(navigationController: UINavigationController?) {
        // Navigate to passcode configuration screen
    }
}

class AuthenticationSettingsViewController: SettingsTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("Touch ID & Passcode", tableName: "AuthenticationManager", comment: "Title for Touch ID/Passcode settings option")

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: Selector("passcodeStateChanged:"), name: NotificationPasscodeDidRemove, object: nil)
        notificationCenter.addObserver(self, selector: Selector("passcodeStateChanged:"), name: NotificationPasscodeDidCreate, object: nil)
    }

    deinit {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: NotificationPasscodeDidRemove, object: nil)
        notificationCenter.removeObserver(self, name: NotificationPasscodeDidCreate, object: nil)
    }

    override func generateSettings() -> [SettingSection] {
        if let _ = KeychainWrapper.stringForKey(KeychainKeyPasscode) {
            return passcodeEnabledSettings()
        } else {
            return passcodeDisabledSettings()
        }
    }

    private func passcodeEnabledSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let passcodeSectionTitle = NSAttributedString(string: NSLocalizedString("Passcode", tableName: "AuthenticationManager", comment: "List section title for passcode settings"))
        let passcodeSection = SettingSection(title: passcodeSectionTitle, children: [
            TurnPasscodeOffSetting(settings: self),
            ChangePasscodeSetting(settings: self, delegate: nil, enabled: true)
        ])

        let prefs = profile.prefs
        let requirePasscodeSection = SettingSection(title: nil, children: [
            RequirePasscodeSetting(settings: self),
            BoolSetting(prefs: prefs,
                prefKey: "touchid.logins",
                defaultValue: false,
                titleText: NSLocalizedString("Use Touch ID", tableName:  "AuthenticationManager", comment: "List section title for when to use Touch ID")
            ),
        ])

        settings += [
            passcodeSection,
            requirePasscodeSection,
        ]

        return settings
    }

    private func passcodeDisabledSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let passcodeSectionTitle = NSAttributedString(string: NSLocalizedString("Passcode", tableName: "AuthenticationManager", comment: "List section title for passcode settings"))
        let passcodeSection = SettingSection(title: passcodeSectionTitle, children: [
            TurnPasscodeOnSetting(settings: self),
            ChangePasscodeSetting(settings: self, delegate: nil, enabled: false)
        ])

        let requirePasscodeSection = SettingSection(title: nil, children: [
            RequirePasscodeSetting(settings: self, delegate: nil, requireInterval: profile.prefs.intForKey(PrefKeyRequirePasscodeInterval), enabled: false),
        ])

        settings += [
            passcodeSection,
            requirePasscodeSection,
        ]

        return settings
    }
}

extension AuthenticationSettingsViewController {
    func passcodeStateChanged(notification: NSNotification) {
        generateSettings()
        tableView.reloadData()
    }
}