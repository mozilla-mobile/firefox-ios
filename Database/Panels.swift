// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/*
 * This protocol is used for instantiating new tab panels. It ensures
 * they all have the same constructor which includes an AccountManager params
 */
protocol ToolbarViewProtocol {
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, accountManager: AccountManager);
}

/*
 * This is a stub implementation of the ToolbarViewProtocol for normal UIViewControllers
 */
class ToolbarViewController: UIViewController, ToolbarViewProtocol {
    let accountManager: AccountManager;
    
    required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, accountManager: AccountManager) {
        self.accountManager = accountManager;
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/*
 * This is a stub implementation of the ToolbarViewProtocol for normal UITableViewControllers
 */
class ToolbarTableViewController: UITableViewController, ToolbarViewProtocol {
    let accountManager: AccountManager!
    
    required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, accountManager: AccountManager) {
        self.accountManager = accountManager;
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/*
 * This struct holds basic data about the tabs shown in our UI.
 */
struct ToolbarItem {
    let title: String /* We use title all over the palce as a unique identifier. Be careful not to have duplicates */
    let imageName: String
    let generator: (accountManager: AccountManager) -> UIViewController
    var enabled : Bool
}

/*
 * A list of tabs to show. Order is important here. The order (and enabled state) listed here represent the defaults for the app.
 * This will be rearranged on startup to make the order stored/enabled-states set in NSUserDefaults.
 */
private var Controllers: [ToolbarItem] = [
    ToolbarItem(title: "Tabs", imageName: "tabs", generator: { (accountManager: AccountManager) -> UIViewController in
        return TabsViewController(nibName: nil, bundle: nil, accountManager: accountManager)
    }, enabled: true),
    ToolbarItem(title: "Bookmarks", imageName: "bookmarks", generator: { (accountManager: AccountManager) -> UIViewController in
        return BookmarksViewController(nibName: nil, bundle: nil, accountManager: accountManager)
    }, enabled: true),
    ToolbarItem(title: "History", imageName: "history", generator: { (accountManager: AccountManager) -> UIViewController in
        return HistoryViewController(nibName: "HistoryViewController", bundle: nil, accountManager: accountManager)
    }, enabled: true),
    ToolbarItem(title: "Reader", imageName: "reader", generator: { (accountManager: AccountManager) -> UIViewController in
        return SiteTableViewController(nibName: nil, bundle: nil, accountManager: accountManager)
    }, enabled: true),
    ToolbarItem(title: "Settings", imageName: "settings",  generator: { (accountManager: AccountManager) -> UIViewController in
        return SettingsViewController(nibName: "SettingsViewController", bundle: nil, accountManager: accountManager)
    }, enabled: true),
]

private var setup: Bool = false // True if we've already loaded the order/enabled prefs once and the Controllers array has been updated
let PanelsNotificationName = "PANELS_NOTIFICATION_NAME" // A constant to use for Notifications of changes to the panel dataset

// A helper function for finding the index of a ToolbarItem with a particular title in Controllers. This isn't going to be fast, but assuming
// controllers isn't ever huge, it shouldn't matter.
private func indexOf(val: String) -> Int {
    var i = 0;
    for controller in Controllers {
        if (controller.title == val) {
            return i
        }
        i++
    }
    return -1
}

/*
 * The main object people wanting to interact with panels should use.
 */
class Panels : SequenceType {
    // Keys for prefs where we store panel data
    private let PanelsOrderKey : String = "PANELS_ORDER"
    private let PanelsEnabledKey : String = "PANELS_ENABLED"

    private let accountManager : AccountManager

    /*
     * Returns a list of enabled items. This list isn't live. If you're using it,
     * you should also register for notifications of changes so that you can obtain a more
     * up-to-date dataset.
     */
    var enabledItems : [ToolbarItem] {
        var res : [ToolbarItem] = []
        for controller in Controllers {
            if (controller.enabled) {
                res.append(controller)
            }
        }

        return res
    }

    /* 
     * Moves an item in the list..
     */
    func moveItem(from: Int, to: Int) {
        if (from == to) {
            return
        }

        let a = Controllers.removeAtIndex(from);
        Controllers.insert(a, atIndex: to)

        saveConfig() { self.notifyChange() }
    }

    private func notifyChange() {
        let notif = NSNotification(name: PanelsNotificationName, object: nil);
        NSNotificationCenter.defaultCenter().postNotification(notif)
    }
    
    /*
     * Enables or disables the panel at an index
     * TODO: This would be nicer if just calling panel.enabled = X; did the same thing
     */
    func enablePanelAt(enabled: Bool, position: Int) {
        if (Controllers[position].enabled == enabled) {
            return
        }

        Controllers[position].enabled = enabled;
        saveConfig() { self.notifyChange() }
    }

    /*
     * Saves an updated order and enabled dataset to UserDefaults
     */
    private func saveConfig(callback: () -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var order = [String]()
            var enabled = [Bool]()

            for controller in Controllers {
                order.append(controller.title)
                enabled.append(controller.enabled)
            }

            let prefs = AccountPrefs(accountManager: self.accountManager)!
            prefs.setObject(order, forKey: self.PanelsOrderKey)
            prefs.setObject(enabled, forKey: self.PanelsEnabledKey)

            dispatch_async(dispatch_get_main_queue()) {
                callback();
            }
        }
    }

    init(accountManager : AccountManager) {
        self.accountManager = accountManager;

        if (!setup) {
            let prefs = AccountPrefs(accountManager: accountManager)!
            if let enabled = prefs.arrayForKey(PanelsEnabledKey) as? [Bool] {
                if let order = prefs.arrayForKey(PanelsOrderKey) as? [String] {
                    for (index:Int, title:String) in enumerate(order) {
                        var i = indexOf(title)
                        if (i >= 0) {
                            var a = Controllers.removeAtIndex(i)
                            a.enabled = enabled[index]
                            Controllers.insert(a, atIndex: index)
                        }
                    }
                }
            }
            setup = true;
        }
    }

    var count: Int {
        return Controllers.count;
    }
    
    subscript(index: Int) -> ToolbarItem {
        return Controllers[index]
    }

    func generate() -> GeneratorOf<ToolbarItem> {
        var nextIndex = 0;
        return GeneratorOf<ToolbarItem>() {
            if (nextIndex >= Controllers.count) {
                return nil
            }
            return Controllers[nextIndex++]
        }
    }
}
