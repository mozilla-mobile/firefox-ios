/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SwiftKeychainWrapper
import LocalAuthentication

private let logger = Logger.browserLogger

private func presentNavAsFormSheet(presented: UINavigationController, presenter: UINavigationController?) {
    presented.modalPresentationStyle = .FormSheet
    presenter?.presentViewController(presented, animated: true, completion: nil)
}

class TurnPasscodeOnSetting: Setting {
    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil) {
        super.init(title: NSAttributedString.tableRowTitle(AuthenticationStrings.turnOnPasscode),
                   delegate: delegate)
    }

    override func onClick(navigationController: UINavigationController?) {
        presentNavAsFormSheet(UINavigationController(rootViewController: SetupPasscodeViewController()),
                              presenter: navigationController)
    }
}

class TurnPasscodeOffSetting: Setting {
    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil) {
        super.init(title: NSAttributedString.tableRowTitle(AuthenticationStrings.turnOffPasscode),
                   delegate: delegate)
    }

    override func onClick(navigationController: UINavigationController?) {
        presentNavAsFormSheet(UINavigationController(rootViewController: RemovePasscodeViewController()),
                              presenter: navigationController)
    }
}

class ChangePasscodeSetting: Setting {
    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil, enabled: Bool) {
        let attributedTitle: NSAttributedString = (enabled ?? false) ?
            NSAttributedString.tableRowTitle(AuthenticationStrings.changePasscode) :
            NSAttributedString.disabledTableRowTitle(AuthenticationStrings.changePasscode)

        super.init(title: attributedTitle,
                   delegate: delegate,
                   enabled: enabled)
    }

    override func onClick(navigationController: UINavigationController?) {
        presentNavAsFormSheet(UINavigationController(rootViewController: ChangePasscodeViewController()),
                              presenter: navigationController)
    }
}

class RequirePasscodeSetting: Setting {
    private weak var navigationController: UINavigationController?

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var style: UITableViewCellStyle { return .Value1 }

    override var status: NSAttributedString {
        // Only show the interval if we are enabled and have an interval set.
        let authenticationInterval = KeychainWrapper.authenticationInfo()
        if let interval = authenticationInterval?.requiredPasscodeInterval where enabled {
            return NSAttributedString.disabledTableRowTitle(interval.settingTitle)
        }
        return NSAttributedString(string: "")
    }

    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil, enabled: Bool? = nil) {
        self.navigationController = settings.navigationController
        let title = AuthenticationStrings.requirePasscode
        let attributedTitle = (enabled ?? true) ? NSAttributedString.tableRowTitle(title) : NSAttributedString.disabledTableRowTitle(title)
        super.init(title: attributedTitle,
                   delegate: delegate,
                   enabled: enabled)
    }

    override func onClick(_: UINavigationController?) {
        guard let authInfo = KeychainWrapper.authenticationInfo() else {
            navigateToRequireInterval()
            return
        }

        if authInfo.requiresValidation(.ModifyAuthenticationSettings) {
            AppAuthenticator.presentTouchAuthenticationUsingInfo(authInfo,
            touchIDReason: AuthenticationStrings.requirePasscodeTouchReason,
            success: {
                self.navigateToRequireInterval()
            },
            cancel: nil,
            fallback: {
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController, success: {
                    self.navigationController?.dismissViewControllerAnimated(true) {
                        self.navigateToRequireInterval()
                    }
                }, cancel: nil)
            })
        } else {
            self.navigateToRequireInterval()
        }
    }

    private func navigateToRequireInterval() {
        navigationController?.pushViewController(RequirePasscodeIntervalViewController(), animated: true)
    }
}

class AuthenticationSetting: Setting {
    private weak var navigationController: UINavigationController?
    private weak var switchControl: UISwitch?
    
    typealias AuthenticationCallback = (AuthenticationSetting -> Void)?
    
    private var touchIDSuccess: AuthenticationCallback = nil
    private var touchIDFallback: AuthenticationCallback = nil
    
    var purpose: AuthenticationKeychainInfo.AuthenticationPurpose = .Other
    var requiresAuthentication: Bool {
        return true
    }
    
    init(
        title: NSAttributedString?,
        navigationController: UINavigationController? = nil,
        delegate: SettingsDelegate? = nil,
        enabled: Bool? = nil,
        touchIDSuccess: AuthenticationCallback = nil,
        touchIDFallback: AuthenticationCallback = nil)
    {
        self.touchIDSuccess = touchIDSuccess
        self.touchIDFallback = touchIDFallback
        self.navigationController = navigationController
        super.init(title: title, delegate: delegate, enabled: enabled)
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.selectionStyle = .None

        // In order for us to recognize a tap gesture without toggling the switch,
        // the switch is wrapped in a UIView which has a tap gesture recognizer. This way
        // we can disable interaction of the switch and still handle tap events.
        let control = UISwitch()
        control.onTintColor = self.enabled ? UIConstants.ControlTintColor : UIConstants.ControlDisabledColor
        control.on = requiresAuthentication
        control.userInteractionEnabled = false
        switchControl = control

        let accessoryContainer = UIView(frame: control.frame)
        accessoryContainer.addSubview(control)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(AuthenticationSetting.switchTapped))
        accessoryContainer.addGestureRecognizer(gesture)

        cell.accessoryView = accessoryContainer
    }

    @objc private func switchTapped() {
        guard let authInfo = KeychainWrapper.authenticationInfo() else {
            logger.error("Authentication info should always be present when modifying Touch ID preference.")
            return
        }

        if requiresAuthentication {
            AppAuthenticator.presentTouchAuthenticationUsingInfo(
                authInfo,
                touchIDReason: AuthenticationStrings.disableAuthenticationReason,
                success: {
                    self.touchIDSuccess?(self)
                },
                cancel: nil,
                fallback: {
                    self.touchIDFallback?(self)
                }
            )
        } else {
            toggleTouchID(enabled: true)
        }
    }

    func toggleTouchID(enabled enabled: Bool) {
        switchControl?.setOn(enabled, animated: true)
    }
}

class AuthenticationForModifyingAuthenticationSettings: AuthenticationSetting {
    override init(title: NSAttributedString?, navigationController: UINavigationController?, delegate: SettingsDelegate?, enabled: Bool?, touchIDSuccess: AuthenticationCallback, touchIDFallback: AuthenticationCallback) {
        super.init(title: title, navigationController: navigationController, delegate: delegate, enabled: enabled, touchIDSuccess: touchIDSuccess, touchIDFallback: touchIDFallback)
        purpose = .ModifyAuthenticationSettings
    }
}

class AuthenticationForPrivateBrowsingSetting: AuthenticationSetting {
    override var requiresAuthentication: Bool {
        return KeychainWrapper.authenticationInfo()?.useAuthenticationForPrivateBrowsing ?? false
    }
    
    override init(title: NSAttributedString?, navigationController: UINavigationController?, delegate: SettingsDelegate?, enabled: Bool?, touchIDSuccess: AuthenticationCallback, touchIDFallback: AuthenticationCallback) {
        super.init(title: title, navigationController: navigationController, delegate: delegate, enabled: enabled, touchIDSuccess: touchIDSuccess, touchIDFallback: touchIDFallback)
        purpose = .PrivateBrowsing
    }
    
    override func toggleTouchID(enabled enabled: Bool) {
        guard let authInfo = KeychainWrapper.authenticationInfo() else {
            return
        }
        authInfo.useAuthenticationForPrivateBrowsing = enabled
        KeychainWrapper.setAuthenticationInfo(authInfo)
        super.toggleTouchID(enabled: enabled)
    }
}

class AuthenticationForLoginsSetting: AuthenticationSetting {
    override var requiresAuthentication: Bool {
        return KeychainWrapper.authenticationInfo()?.useAuthenticationForLogins ?? false
    }
    
    override init(title: NSAttributedString?, navigationController: UINavigationController?, delegate: SettingsDelegate?, enabled: Bool?, touchIDSuccess: AuthenticationCallback, touchIDFallback: AuthenticationCallback) {
        super.init(title: title, navigationController: navigationController, delegate: delegate, enabled: enabled, touchIDSuccess: touchIDSuccess, touchIDFallback: touchIDFallback)
        purpose = .Logins
    }
    
    override func toggleTouchID(enabled enabled: Bool) {
        guard let authInfo = KeychainWrapper.authenticationInfo() else {
            return
        }
        authInfo.useAuthenticationForLogins = enabled
        KeychainWrapper.setAuthenticationInfo(authInfo)
        super.toggleTouchID(enabled: enabled)
    }
}

class AuthenticationSettingsViewController: SettingsTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitleForTouchIDState()

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(AuthenticationSettingsViewController.refreshSettings(_:)), name: NotificationPasscodeDidRemove, object: nil)
        notificationCenter.addObserver(self, selector: #selector(AuthenticationSettingsViewController.refreshSettings(_:)), name: NotificationPasscodeDidCreate, object: nil)
        notificationCenter.addObserver(self, selector: #selector(AuthenticationSettingsViewController.refreshSettings(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)

        tableView.accessibilityIdentifier = "AuthenticationManager.settingsTableView"
    }

    deinit {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: NotificationPasscodeDidRemove, object: nil)
        notificationCenter.removeObserver(self, name: NotificationPasscodeDidCreate, object: nil)
        notificationCenter.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    override func generateSettings() -> [SettingSection] {
        if let _ = KeychainWrapper.authenticationInfo() {
            return passcodeEnabledSettings()
        } else {
            return passcodeDisabledSettings()
        }
    }

    private func updateTitleForTouchIDState() {
        if LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            navigationItem.title = AuthenticationStrings.touchIDPasscodeSetting
        } else {
            navigationItem.title = AuthenticationStrings.passcode
        }
    }
    
    private var authenticationSectionTitle: NSAttributedString {
        if LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            return NSAttributedString(string: AuthenticationStrings.authenticateFeaturesWithTouchIDPasscode)
        } else {
            return NSAttributedString(string: AuthenticationStrings.authenticateFeaturesWithPasscode)
        }
    }
    
    private func privateBrowsingSetting(navigationController: UINavigationController?) -> AuthenticationForPrivateBrowsingSetting {
        return AuthenticationForPrivateBrowsingSetting(
            title: NSAttributedString.tableRowTitle(
                NSLocalizedString("Private Browsing", tableName:  "AuthenticationManager", comment: "List section title for when to use authentication for private browsing")
            ),
            navigationController: navigationController,
            delegate: nil,
            enabled: true,
            touchIDSuccess: { touchIDSetting in
                touchIDSetting.toggleTouchID(enabled: false)
            },
            touchIDFallback: { [unowned self] touchIDSetting in
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController,
                    success: {
                        touchIDSetting.toggleTouchID(enabled: false)
                        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                    },
                    cancel: nil
                )
            }
        )
    }
    
    private func loginsSetting(navigationController: UINavigationController?) -> AuthenticationForLoginsSetting {
        return AuthenticationForLoginsSetting(
            title: NSAttributedString.tableRowTitle(
                NSLocalizedString("Logins", tableName:  "AuthenticationManager", comment: "List section title for when to use Touch ID for logins")
            ),
            navigationController: navigationController,
            delegate: nil,
            enabled: true,
            touchIDSuccess: { touchIDSetting in
                touchIDSetting.toggleTouchID(enabled: false)
            },
            touchIDFallback: { [unowned self] touchIDSetting in
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController,
                    success: { 
                        touchIDSetting.toggleTouchID(enabled: false)
                        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                    },
                    cancel: nil
                )
            }
        )
    }

    private func passcodeEnabledSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let passcodeSectionTitle = NSAttributedString(string: AuthenticationStrings.passcode)
        let passcodeSection = SettingSection(title: passcodeSectionTitle, children: [
            TurnPasscodeOffSetting(settings: self),
            ChangePasscodeSetting(settings: self, delegate: nil, enabled: true)
        ])

        let requirePasscodeSectionChildren: [Setting] = [RequirePasscodeSetting(settings: self)]
        let authenticationSection = SettingSection(title: authenticationSectionTitle, children: [
            privateBrowsingSetting(self.navigationController),
            loginsSetting(self.navigationController)
        ])

        let requirePasscodeSection = SettingSection(title: nil, children: requirePasscodeSectionChildren)
        settings += [
            passcodeSection,
            requirePasscodeSection,
            authenticationSection
        ]

        return settings
    }

    private func passcodeDisabledSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let passcodeSectionTitle = NSAttributedString(string: AuthenticationStrings.passcode)
        let passcodeSection = SettingSection(title: passcodeSectionTitle, children: [
            TurnPasscodeOnSetting(settings: self),
            ChangePasscodeSetting(settings: self, delegate: nil, enabled: false)
        ])

        let requirePasscodeSection = SettingSection(title: nil, children: [
            RequirePasscodeSetting(settings: self, delegate: nil, enabled: false),
        ])
        
        let authenticationSection = SettingSection(title: authenticationSectionTitle, children: [
            AuthenticationSetting(
                title: NSAttributedString.tableRowTitle(
                    NSLocalizedString("Private Browsing", tableName:  "AuthenticationManager", comment: "List section title for when to use authentication for private browsing")
                ),
                enabled: false
            ),
            AuthenticationSetting(
                title: NSAttributedString.tableRowTitle(
                    NSLocalizedString("Logins", tableName:  "AuthenticationManager", comment: "List section title for when to use Touch ID for logins")
                ),
                enabled: false
            )
        ])

        settings += [
            passcodeSection,
            requirePasscodeSection,
            authenticationSection
        ]

        return settings
    }
}

extension AuthenticationSettingsViewController {
    func refreshSettings(notification: NSNotification) {
        updateTitleForTouchIDState()
        settings = generateSettings()
        tableView.reloadData()
    }
}