//
//  QuickActions.swift
//  Client
//
//  Created by Emily Toop on 11/20/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import Foundation

import Shared
import XCGLogger

@available(iOS 9, *)
enum ShortcutType: String {
    case NewTab
    case NewPrivateTab
    case OpenLastBookmark

    init?(fullType: String) {
        guard let last = fullType.componentsSeparatedByString(".").last else { return nil }

        self.init(rawValue: last)
    }

    var type: String {
        return NSBundle.mainBundle().bundleIdentifier! + ".\(self.rawValue)"
    }
}

@available(iOS 9, *)
protocol QuickActionHandlerDelegate {
    func handleShortCutItemType(type: ShortcutType, userData: [String: NSSecureCoding]?)
}

@available(iOS 9, *)
struct QuickActions {

    private let log = Logger.browserLogger

    static let QuickActionsVersion = "1.0"
    static let QuickActionsVersionKey = "dynamicQuickActionsVersion"

    private let lastBookmarkTitle = NSLocalizedString("Open Last Bookmark", comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch")

    static var sharedInstance = QuickActions()

    var launchedShortcutItem: UIApplicationShortcutItem?

    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem, completionBlock: (type: ShortcutType, userData: [String: NSSecureCoding]?)->Void ) -> Bool {

        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
        guard let shortCutType = ShortcutType(fullType: shortcutItem.type) else { return false }

        dispatch_async(dispatch_get_main_queue()) {
            completionBlock(type: shortCutType, userData: shortcutItem.userInfo)
        }

        return true
    }

    mutating func addDynamicApplicationShortcutItemOfType(type: ShortcutType, var withUserData userData: [NSObject : AnyObject] = [NSObject : AnyObject](), toApplication application: UIApplication) -> Bool {
        // add the quick actions version so that it is always in the user info
        userData[QuickActions.QuickActionsVersionKey] = QuickActions.QuickActionsVersion
        var dynamicShortcutItems = application.shortcutItems ?? [UIApplicationShortcutItem]()
        switch(type) {
        case .OpenLastBookmark:
            let openLastBookmarkShortcut = UIMutableApplicationShortcutItem(type: ShortcutType.OpenLastBookmark.type,
                localizedTitle: lastBookmarkTitle,
                localizedSubtitle: userData["bookmarkTitle"] as? String,
                icon: UIApplicationShortcutIcon(templateImageName: "quick_action_last_bookmark"),
                userInfo: userData
            )
            // either replace the item if it already exists or add it if the array of items is empty
            if dynamicShortcutItems.isEmpty {
                dynamicShortcutItems.append(openLastBookmarkShortcut)
            } else {
                dynamicShortcutItems[0] = openLastBookmarkShortcut
            }
        default:
            log.warning("Cannot add static shortcut item of type \(type)")
            return false
        }
        application.shortcutItems = dynamicShortcutItems
        return true
    }

    mutating func removeDynamicApplicationShortcutItemOfType(type: ShortcutType, fromApplication application: UIApplication) {
        guard var dynamicShortcutItems = application.shortcutItems,
            let index = (dynamicShortcutItems.indexOf{ $0.type == type.type }) else { return }

        dynamicShortcutItems.removeAtIndex(index)
        application.shortcutItems = dynamicShortcutItems
    }
}
