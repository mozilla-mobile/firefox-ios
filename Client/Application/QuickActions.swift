// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import Shared

// MARK: - ShortcutType
enum ShortcutType: String {
    case newTab = "NewTab"
    case newPrivateTab = "NewPrivateTab"
    case openLastBookmark = "OpenLastBookmark"
    case qrCode = "QRCode"

    init?(fullType: String) {
        guard let last = fullType.components(separatedBy: ".").last else { return nil }

        self.init(rawValue: last)
    }

    var type: String {
        return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
    }
}

// MARK: - QuickActionInfos
struct QuickActionInfos {
    static let version = "1.0"
    static let versionKey = "dynamicQuickActionsVersion"
    static let tabURLKey = "url"
    static let tabTitleKey = "title"
}

// MARK: - QuickActions
protocol QuickActions {
    func addDynamicApplicationShortcutItemOfType(
        _ type: ShortcutType,
        fromShareItem shareItem: ShareItem,
        toApplication application: UIApplication
    )

    func addDynamicApplicationShortcutItemOfType(
        _ type: ShortcutType,
        withUserData userData: [String: String],
        toApplication application: UIApplication
    )

    func removeDynamicApplicationShortcutItemOfType(
        _ type: ShortcutType,
        fromApplication application: UIApplication
    )

    func handleShortCutItem(
        _ shortcutItem: UIApplicationShortcutItem,
        withBrowserViewController bvc: BrowserViewController,
        completionHandler: @escaping (Bool) -> Void
    )
}

extension QuickActions {
    func addDynamicApplicationShortcutItemOfType(
        _ type: ShortcutType,
        withUserData userData: [String: String] = [String: String](),
        toApplication application: UIApplication
    ) {
        addDynamicApplicationShortcutItemOfType(type, withUserData: userData, toApplication: application)
    }
}

struct QuickActionsImplementation: QuickActions, Loggable {

    // MARK: Administering Quick Actions
    func addDynamicApplicationShortcutItemOfType(_ type: ShortcutType,
                                                 fromShareItem shareItem: ShareItem,
                                                 toApplication application: UIApplication) {
        var userData = [QuickActionInfos.tabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActionInfos.tabTitleKey] = title
        }
        addDynamicApplicationShortcutItemOfType(type,
                                                withUserData: userData,
                                                toApplication: application)
    }

    func addDynamicApplicationShortcutItemOfType(
        _ type: ShortcutType,
        withUserData userData: [String: String] = [String: String](),
        toApplication application: UIApplication
    ) {
        // add the quick actions version so that it is always in the user info
        var userData: [String: String] = userData
        userData[QuickActionInfos.versionKey] = QuickActionInfos.version
        var dynamicShortcutItems = application.shortcutItems ?? [UIApplicationShortcutItem]()
        switch type {
        case .openLastBookmark:
            let openLastBookmarkShortcut = UIMutableApplicationShortcutItem(
                type: ShortcutType.openLastBookmark.type,
                localizedTitle: .QuickActionsLastBookmarkTitle,
                localizedSubtitle: userData[QuickActionInfos.tabTitleKey],
                icon: UIApplicationShortcutIcon(templateImageName: "quick_action_last_bookmark"),
                userInfo: userData as [String: NSSecureCoding]
            )

            if let index = (dynamicShortcutItems.firstIndex { $0.type == ShortcutType.openLastBookmark.type }) {
                dynamicShortcutItems[index] = openLastBookmarkShortcut
            } else {
                dynamicShortcutItems.append(openLastBookmarkShortcut)
            }
        default:
            Logger.browserLogger.warning("Cannot add static shortcut item of type \(type)")
        }
        application.shortcutItems = dynamicShortcutItems
    }

    func removeDynamicApplicationShortcutItemOfType(_ type: ShortcutType,
                                                    fromApplication application: UIApplication) {
        guard var dynamicShortcutItems = application.shortcutItems,
              let index = (dynamicShortcutItems.firstIndex { $0.type == type.type })
        else { return }

        dynamicShortcutItems.remove(at: index)
        application.shortcutItems = dynamicShortcutItems
    }

    // MARK: - Handling Quick Actions

    func handleShortCutItem(_ shortcutItem: UIApplicationShortcutItem,
                            withBrowserViewController bvc: BrowserViewController,
                            completionHandler: @escaping (Bool) -> Void) {

        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
        guard let shortCutType = ShortcutType(fullType: shortcutItem.type) else {
            completionHandler(false)
            return
        }

        DispatchQueue.main.async {
            self.handleShortCutItemOfType(shortCutType,
                                          userData: shortcutItem.userInfo,
                                          browserViewController: bvc)
            completionHandler(true)
        }
    }

    // MARK: - Private

    private func handleShortCutItemOfType(_ type: ShortcutType, userData: [String: NSSecureCoding]?,
                                          browserViewController: BrowserViewController) {
        switch type {
        case .newTab:
            handleOpenNewTab(withBrowserViewController: browserViewController, isPrivate: false)
        case .newPrivateTab:
            handleOpenNewTab(withBrowserViewController: browserViewController, isPrivate: true)
        case .openLastBookmark:
            if let urlToOpen = (userData?[QuickActionInfos.tabURLKey] as? String)?.asURL {
                handleOpenURL(withBrowserViewController: browserViewController, urlToOpen: urlToOpen)
            }
        case .qrCode:
            handleQRCode(with: browserViewController)
        }
    }

    private func handleOpenNewTab(withBrowserViewController bvc: BrowserViewController,
                                  isPrivate: Bool) {
        bvc.openBlankNewTab(focusLocationField: true, isPrivate: isPrivate)
    }

    private func handleOpenURL(withBrowserViewController bvc: BrowserViewController,
                               urlToOpen: URL) {
        // open bookmark in a non-private browsing tab
        bvc.switchToPrivacyMode(isPrivate: false)

        // find out if bookmarked URL is currently open
        // if so, open to that tab,
        // otherwise, create a new tab with the bookmarked URL
        bvc.switchToTabForURLOrOpen(urlToOpen)
    }

    private func handleQRCode(with vc: QRCodeViewControllerDelegate & UIViewController) {
        let qrCodeViewController = QRCodeViewController()
        qrCodeViewController.qrCodeDelegate = vc
        let controller = UINavigationController(rootViewController: qrCodeViewController)
        vc.presentedViewController?.dismiss(animated: true)
        vc.present(controller, animated: true, completion: nil)
    }
}
