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
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController, delegate: self)
            })
        } else {
            self.navigateToRequireInterval()
        }
    }

    private func navigateToRequireInterval() {
        navigationController?.pushViewController(RequirePasscodeIntervalViewController(), animated: true)
    }
}

extension RequirePasscodeSetting: PasscodeEntryDelegate {
    @objc func passcodeValidationDidSucceed() {
        navigationController?.dismissViewControllerAnimated(true) {
            self.navigateToRequireInterval()
        }
    }
}

class AuthenticationSetting: Setting {
    private var authInfo: AuthenticationKeychainInfo?

    private weak var navigationController: UINavigationController?
    private weak var switchControl: UISwitch?
    
    typealias AuthenticationCallback = (AuthenticationSetting -> Void)?

    private var touchIDSuccess: AuthenticationCallback = nil
    private var touchIDFallback: AuthenticationCallback = nil
    
    weak var authenticationDelegate: AuthenticationSettingDelegate?

    init(
        title: NSAttributedString?,
        navigationController: UINavigationController? = nil,
        delegate: SettingsDelegate? = nil,
        authenticationDelegate: AuthenticationSettingDelegate? = nil,
        enabled: Bool? = nil,
        touchIDSuccess: AuthenticationCallback = nil,
        touchIDFallback: AuthenticationCallback = nil)
    {
        self.touchIDSuccess = touchIDSuccess
        self.touchIDFallback = touchIDFallback
        self.navigationController = navigationController
        self.authenticationDelegate = authenticationDelegate
        super.init(title: title, delegate: delegate, enabled: enabled)
        authenticationDelegate?.setting = self
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)

        // In order for us to recognize a tap gesture without toggling the switch,
        // the switch is wrapped in a UIView which has a tap gesture recognizer. This way
        // we can disable interaction of the switch and still handle tap events.
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        self.authInfo = KeychainWrapper.authenticationInfo()
        control.on = authenticationDelegate?.authInfoUseAuthentication ?? false
        control.userInteractionEnabled = false
        switchControl = control

        let accessoryContainer = UIView(frame: control.frame)
        accessoryContainer.addSubview(control)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(AuthenticationSetting.switchTapped))
        accessoryContainer.addGestureRecognizer(gesture)

        cell.accessoryView = accessoryContainer
    }

    @objc private func switchTapped() {
        self.authInfo = KeychainWrapper.authenticationInfo()
        guard let authInfo = authInfo else {
            logger.error("Authentication info should always be present when modifying Touch ID preference.")
            return
        }
        guard let authenticationDelegate = authenticationDelegate else {
            logger.error("The Touch ID setting needs to refer to a specific instance.")
            return
        }
        
        if authenticationDelegate.authInfoUseAuthentication {
            AppAuthenticator.presentTouchAuthenticationUsingInfo(
                authInfo,
                touchIDReason: AuthenticationStrings.disableTouchReason,
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
        self.authInfo = KeychainWrapper.authenticationInfo()
        authenticationDelegate?.authInfoUseAuthentication = enabled
        KeychainWrapper.setAuthenticationInfo(authInfo)
        switchControl?.setOn(enabled, animated: true)
    }
}

protocol AuthenticationSettingDelegate: class {
    var purpose: AuthenticationKeychainInfo.AuthenticationPurpose { get }
    var authInfoUseAuthentication: Bool { get set }
    weak var setting: AuthenticationSetting? { get set }
}

class AuthenticationForPrivateBrowsingSetting: AuthenticationSettingDelegate {
    let purpose = AuthenticationKeychainInfo.AuthenticationPurpose.PrivateBrowsing
    var authInfoUseAuthentication: Bool {
        get {
            return setting?.authInfo?.useAuthenticationForPrivateBrowsing ?? false
        }
        set {
            setting?.authInfo?.useAuthenticationForPrivateBrowsing = newValue
        }
    }
    weak var setting: AuthenticationSetting?
}

class AuthenticationForLoginsSetting: AuthenticationSettingDelegate {
    var purpose = AuthenticationKeychainInfo.AuthenticationPurpose.Logins
    var authInfoUseAuthentication: Bool {
        get {
            return setting?.authInfo?.useAuthenticationForLogins ?? false
        }
        set {
            setting?.authInfo?.useAuthenticationForLogins = newValue
        }
    }
    weak var setting: AuthenticationSetting?
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

    private func passcodeEnabledSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let passcodeSectionTitle = NSAttributedString(string: AuthenticationStrings.passcode)
        let passcodeSection = SettingSection(title: passcodeSectionTitle, children: [
            TurnPasscodeOffSetting(settings: self),
            ChangePasscodeSetting(settings: self, delegate: nil, enabled: true)
        ])

        let requirePasscodeSectionChildren: [Setting] = [RequirePasscodeSetting(settings: self)]
        let authenticationSection = SettingSection(title: authenticationSectionTitle, children: [
            AuthenticationSetting(
                title: NSAttributedString.tableRowTitle(
                    NSLocalizedString("Private Browsing", tableName:  "AuthenticationManager", comment: "List section title for when to use authentication for private browsing")
                ),
                navigationController: self.navigationController,
                delegate: nil,
                authenticationDelegate: AuthenticationForPrivateBrowsingSetting(),
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
            ),
            AuthenticationSetting(
                title: NSAttributedString.tableRowTitle(
                    NSLocalizedString("Logins", tableName:  "AuthenticationManager", comment: "List section title for when to use Touch ID for logins")
                ),
                navigationController: self.navigationController,
                delegate: nil,
                authenticationDelegate: AuthenticationForLoginsSetting(),
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