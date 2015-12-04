//
//  QuickActions.swift
//  Client
//
//  Created by Emily Toop on 11/20/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import Foundation
import Storage

import Shared
import XCGLogger

@available(iOS 9, *)
enum ShortcutType: String {
    case NewTab
    case NewPrivateTab
    case OpenLastBookmark
    case OpenLastTab

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

    static let TabURLKey = "url"
    static let TabTitleKey = "title"

    private let lastBookmarkTitle = NSLocalizedString("Open Last Bookmark", comment: "String describing the action of opening the last added bookmark from the home screen Quick Actions via 3D Touch")
    private let lastTabTitle = NSLocalizedString("Open Last Tab", comment: "String describing the action of opening the last tab sent to Firefox from the home screen Quick Actions via 3D Touch")

    static var sharedInstance = QuickActions()

    var launchedShortcutItem: UIApplicationShortcutItem?

    // MARK: Administering Quick Actions
    mutating func addDynamicApplicationShortcutItemOfType(type: ShortcutType, fromShareItem shareItem: ShareItem, toApplication application: UIApplication) {
            var userData = [QuickActions.TabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActions.TabTitleKey] = title
            }
            QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(type, withUserData: userData, toApplication: application)
    }

    mutating func addDynamicApplicationShortcutItemOfType(type: ShortcutType, var withUserData userData: [NSObject : AnyObject] = [NSObject : AnyObject](), toApplication application: UIApplication) -> Bool {
        // add the quick actions version so that it is always in the user info
        userData[QuickActions.QuickActionsVersionKey] = QuickActions.QuickActionsVersion
        var dynamicShortcutItems = application.shortcutItems ?? [UIApplicationShortcutItem]()
        switch(type) {
        case .OpenLastBookmark:
            let openLastBookmarkShortcut = UIMutableApplicationShortcutItem(type: ShortcutType.OpenLastBookmark.type,
                localizedTitle: lastBookmarkTitle,
                localizedSubtitle: userData[QuickActions.TabTitleKey] as? String,
                icon: UIApplicationShortcutIcon(templateImageName: "quick_action_last_bookmark"),
                userInfo: userData
            )
            if let index = (dynamicShortcutItems.indexOf { $0.type == ShortcutType.OpenLastBookmark.type }) {
                dynamicShortcutItems[index] = openLastBookmarkShortcut
            } else {
                dynamicShortcutItems.append(openLastBookmarkShortcut)
            }
        case .OpenLastTab:
            let openLastTabShortcut = UIMutableApplicationShortcutItem(type: ShortcutType.OpenLastTab.type,
                localizedTitle: lastTabTitle,
                localizedSubtitle: userData[QuickActions.TabTitleKey] as? String,
                icon: UIApplicationShortcutIcon(templateImageName: "quick_action_last_tab"),
                userInfo: userData
            )
            if dynamicShortcutItems.isEmpty {
                dynamicShortcutItems.append(openLastTabShortcut)
            } else if dynamicShortcutItems[0].type == ShortcutType.OpenLastTab.type {
                dynamicShortcutItems[0] = openLastTabShortcut
            } else {
                dynamicShortcutItems.insert(openLastTabShortcut, atIndex: 0)
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


    // MARK: Handling Quick Actions
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem, withBrowserViewController bvc: BrowserViewController ) -> Bool {

        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
        guard let shortCutType = ShortcutType(fullType: shortcutItem.type) else { return false }

        dispatch_async(dispatch_get_main_queue()) {
            self.handleShortCutItemOfType(shortCutType, userData: shortcutItem.userInfo, browserViewController: bvc)
        }

        return true
    }

    private func handleShortCutItemOfType(type: ShortcutType, userData: [String : NSSecureCoding]?, browserViewController: BrowserViewController) {
        switch(type) {
        case .NewTab:
            handleOpenNewTab(withBrowserViewController: browserViewController, isPrivate: false)
        case .NewPrivateTab:
            handleOpenNewTab(withBrowserViewController: browserViewController, isPrivate: true)
        case .OpenLastBookmark, .OpenLastTab:
            if let urlToOpen = (userData?[QuickActions.TabURLKey] as? String)?.asURL {
                handleOpenURL(withBrowserViewController: browserViewController, urlToOpen: urlToOpen)
            }
        }
    }

    private func handleOpenNewTab(withBrowserViewController bvc: BrowserViewController, isPrivate: Bool) {
        if isPrivate {
            bvc.applyPrivateModeTheme(force: true)
        } else {
            bvc.applyNormalModeTheme(force: true)
        }
        bvc.openBlankNewTabAndFocus(isPrivate: isPrivate)
    }

    private func handleOpenURL(withBrowserViewController bvc: BrowserViewController, urlToOpen: NSURL) {
        // open bookmark in a non-private browsing tab
        bvc.applyNormalModeTheme(force: true)

        // find out if bookmarked URL is currently open
        // if so, open to that tab,
        // otherwise, create a new tab with the bookmarked URL
        bvc.switchToTabForURLOrOpen(urlToOpen)
    }
}
