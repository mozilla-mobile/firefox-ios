//
//  QuickActions.swift
//  Client
//
//  Created by Emily Toop on 11/20/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import Foundation

@available(iOS 9, *)
enum ShortcutType: String {
    case NewTab
    case NewPrivateTab

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

    var launchedShortcutItem: UIApplicationShortcutItem?

    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem, completionBlock: (type: ShortcutType, userData: [String: NSSecureCoding]?)->Void ) -> Bool {

        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
        guard let shortCutType = ShortcutType(fullType: shortcutItem.type) else { return false }

        dispatch_async(dispatch_get_main_queue()) {
            completionBlock(type: shortCutType, userData: shortcutItem.userInfo)
        }

        return true
    }
}
