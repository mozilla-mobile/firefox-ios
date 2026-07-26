// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

// MARK: - ShortcutType
enum ShortcutType: String {
    case newTab = "NewTab"
    case newPrivateTab = "NewPrivateTab"
    case openLastBookmark = "OpenLastBookmark"
    case appIcon = "AppIcon"
    case mergeWindows = "MergeWindows"

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
protocol QuickActions: Sendable {
    @MainActor
    func addDynamicApplicationShortcutItemOfType(
        _ type: ShortcutType,
        withUserData userData: [String: String],
        toApplication application: UIApplication
    )

    @MainActor
    func removeDynamicApplicationShortcutItemOfType(
        _ type: ShortcutType,
        fromApplication application: UIApplication
    )
}

extension QuickActions {
    @MainActor
    func addDynamicApplicationShortcutItemOfType(
        _ type: ShortcutType,
        withUserData userData: [String: String] = [String: String](),
        toApplication application: UIApplication
    ) {
        addDynamicApplicationShortcutItemOfType(type, withUserData: userData, toApplication: application)
    }
}

struct QuickActionsImplementation: QuickActions {
    // MARK: Administering Quick Actions
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
        case .mergeWindows:
            let mergeWindowsShortcut = UIMutableApplicationShortcutItem(
                type: ShortcutType.mergeWindows.type,
                localizedTitle: .QuickActionsMergeAllWindowsTitle,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(templateImageName: StandardImageIdentifiers.Large.tabTray),
                userInfo: userData as [String: NSSecureCoding]
            )

            if let index = (dynamicShortcutItems.firstIndex { $0.type == ShortcutType.mergeWindows.type }) {
                dynamicShortcutItems[index] = mergeWindowsShortcut
            } else {
                dynamicShortcutItems.append(mergeWindowsShortcut)
            }
        default:
            break
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

// MARK: - MergeWindowsQuickActionController

/// Keeps the "Merge All Windows" home screen Quick Action in sync with the number of open iPad
/// windows: the action is only offered while two or more windows are open. Call `update()` whenever
/// the set of open windows changes (a scene becoming active or disconnecting).
@MainActor
struct MergeWindowsQuickActionController {
    private let quickActions: QuickActions
    private let windowManager: WindowManager
    private let application: UIApplication

    init(quickActions: QuickActions = QuickActionsImplementation(),
         windowManager: WindowManager = AppContainer.shared.resolve(),
         application: UIApplication = .shared) {
        self.quickActions = quickActions
        self.windowManager = windowManager
        self.application = application
    }

    /// Adds the merge Quick Action when 2+ windows are open, otherwise removes it.
    func update() {
        if windowManager.windows.count >= 2 {
            quickActions.addDynamicApplicationShortcutItemOfType(.mergeWindows, toApplication: application)
        } else {
            quickActions.removeDynamicApplicationShortcutItemOfType(.mergeWindows, fromApplication: application)
        }
    }
}
