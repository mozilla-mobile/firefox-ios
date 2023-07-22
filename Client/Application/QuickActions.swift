// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
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

struct QuickActionsImplementation: QuickActions {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

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
                icon: UIApplicationShortcutIcon(templateImageName: StandardImageIdentifiers.Large.bookmarkFill),
                userInfo: userData as [String: NSSecureCoding]
            )

            if let index = (dynamicShortcutItems.firstIndex { $0.type == ShortcutType.openLastBookmark.type }) {
                dynamicShortcutItems[index] = openLastBookmarkShortcut
            } else {
                dynamicShortcutItems.append(openLastBookmarkShortcut)
            }
        default:
            logger.log("Cannot add static shortcut item of type \(type)", level: .warning, category: .unlabeled)
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
}
