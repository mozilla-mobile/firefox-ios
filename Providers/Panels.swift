/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

let documentsFolder = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
let path = documentsFolder.stringByAppendingPathComponent("test.sqlite")

/*
 * This protocol is used for instantiating new tab panels. It ensures...
 */
protocol ToolbarViewProtocol {
    var profile: Profile! { get set }
}

/*
 * This struct holds basic data about the tabs shown in our UI.
 */
struct ToolbarItem {
    let title: String    // We use title all over the place as a unique identifier. Be careful not to have duplicates.
    let imageName: String
    let generator: (profile: Profile) -> UIViewController;
    var enabled : Bool;
}

/*
 * A list of tabs to show. Order is important here. The order (and enabled state) listed here represent the defaults for the app.
 * This will be rearranged on startup to make the order stored/enabled-states set in NSUserDefaults.
 */
private var Controllers: Protector<[ToolbarItem]> = Protector(name: "Controllers", item: [
    ToolbarItem(title: "Tabs", imageName: "tabs", generator: { (profile: Profile) -> UIViewController in
        let controller = TabsViewController(nibName: nil, bundle: nil)
        controller.profile = profile
        return controller
    }, enabled: true),
    ToolbarItem(title: "Bookmarks", imageName: "bookmarks", generator: { (profile: Profile) -> UIViewController in
        let controller = BookmarksViewController(nibName: nil, bundle: nil)
        controller.profile = profile
        return controller
    }, enabled: true),
    ToolbarItem(title: "History", imageName: "history", generator: { (profile: Profile) -> UIViewController in
        var controller = HistoryViewController(nibName: nil, bundle: nil)
        controller.profile = profile
        return controller
    }, enabled: true),
    ToolbarItem(title: "Reader", imageName: "reader", generator: { (profile: Profile) -> UIViewController in
        let controller = SiteTableViewController(nibName: nil, bundle: nil)
        controller.profile = profile
        return controller
    }, enabled: true),
    ToolbarItem(title: "Settings", imageName: "settings",  generator: { (profile: Profile) -> UIViewController in
        let controller = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        controller.profile = profile
        return controller
    }, enabled: true),
])

private var setup: Bool = false // True if we've already loaded the order/enabled prefs once and the Controllers array has been updated
let PanelsNotificationName = "PANELS_NOTIFICATION_NAME" // A constant to use for Notifications of changes to the panel dataset

// A helper function for finding the index of a ToolbarItem with a particular title in Controllers. This isn't going to be fast, but assuming
// controllers isn't ever huge, it shouldn't matter.
private func indexOf(items: [ToolbarItem], val: String) -> Int {
    var i = 0
    for controller in items {
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
    private var profile: Profile
    private var PanelsOrderKey : String = "PANELS_ORDER"
    private var PanelsEnabledKey : String = "PANELS_ENABLED"
    
    init(profile : Profile) {
        self.profile = profile;
        
        // Prefs are stored in a static cache, so we only want to do this setup
        // the first time a Panels object is created
        if (!setup) {
            let prefs = profile.prefs
            
            if var enabled = prefs.arrayForKey(PanelsEnabledKey) as? [Bool] {
                if var order = prefs.stringArrayForKey(PanelsOrderKey) as? [String] {
                    // Now we loop through the panels and sort them based on the order stored
                    // in PanelsOrderKey. We also disable them based on PanelsEnabledKey.
                    Controllers.withWriteLock { protected -> Void in
                        for (index:Int, title:String) in enumerate(order) {
                            var i = indexOf(protected, title)
                            if (i >= 0) {
                                var a = protected.removeAtIndex(i)
                                a.enabled = enabled[index]
                                protected.insert(a, atIndex: index)
                            }
                        }
                    }
                }
            }
            setup = true;
        }
    }
    
    /*
     * Returns a list of enabled items. This list isn't live. If you're using it,
     * you should also register for notifications of changes so that you can obtain a more
     * up-to-date dataset.
     */
    var enabledItems : [ToolbarItem] {
        var res : [ToolbarItem] = []
        Controllers.withReadLock { (protected) -> Void in
            for controller in protected {
                if (controller.enabled) {
                    res.append(controller)
                }
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

        return Controllers.withWriteLock { protected -> Void in
            let a = protected.removeAtIndex(from);
            protected.insert(a, atIndex: to)
            self.saveConfig() { self.notifyChange() }
        }
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
        return Controllers.withWriteLock { protected  -> Void in
            if (protected[position].enabled != enabled) {
                protected[position].enabled = enabled
            }
            self.saveConfig() { self.notifyChange() }
        }
    }

    /*
     * Saves an updated order and enabled dataset to UserDefaults
     */
    private func saveConfig(callback: () -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var order = [String]()
            var enabled = [Bool]()

            Controllers.withReadLock { protected -> Void in
                for controller in protected {
                    order.append(controller.title)
                    enabled.append(controller.enabled)
                }
            }

            let prefs = self.profile.prefs
            prefs.setObject(order, forKey: self.PanelsOrderKey)
            prefs.setObject(enabled, forKey: self.PanelsEnabledKey)

            dispatch_async(dispatch_get_main_queue()) {
                callback();
            }
        }
    }

    var count: Int {
        var count: Int = 0
        Controllers.withReadLock { protected in
            count = protected.count
        }
        return count
    }
    
    subscript(index: Int) -> ToolbarItem? {
        var item : ToolbarItem?
        Controllers.withReadLock { protected in
            item = protected[index]
        }
        return item;
    }

    func generate() -> GeneratorOf<ToolbarItem> {
        var nextIndex = 0;
        return GeneratorOf<ToolbarItem>() {
            var item: ToolbarItem?
            Controllers.withReadLock { protected in
                if (nextIndex >= protected.count) {
                    item = nil
                }
                item = protected[nextIndex++]
            }
            return item
        }
    }
}
