/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.browserLogger

struct HomePageConstants {
    static let HomePageURLPrefKey = "HomePageURLPref"
    static let DefaultHomePageURLPrefKey = "DefaultHomePageURLPref"
    static let HomePageButtonIsInMenuPrefKey = "HomePageButtonIsInMenuPrefKey"
}

class HomePageHelper {

    let prefs: Prefs

    var currentURL: NSURL? {
        get {
            let string = prefs.stringForKey(HomePageConstants.HomePageURLPrefKey) ?? prefs.stringForKey(HomePageConstants.DefaultHomePageURLPrefKey)
            guard let urlString = string else {
                return nil
            }
            return NSURL(string: urlString)
        }
        set {
            if let url = newValue {
                prefs.setString(url.absoluteString, forKey: HomePageConstants.HomePageURLPrefKey)
            } else {
                prefs.removeObjectForKey(HomePageConstants.HomePageURLPrefKey)
            }
        }
    }

    var isHomePageAvailable: Bool { return currentURL != nil }

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    func openHomePage(tab: Tab) {
        guard let url = currentURL else {
            // this should probably never happen.
            log.error("User requested a homepage that wasn't a valid URL")
            return
        }
        tab.loadRequest(NSURLRequest(URL: url))
    }

    func openHomePage(inTab tab: Tab, withNavigationController navigationController: UINavigationController?) {
        if isHomePageAvailable {
            openHomePage(tab)
        } else {
            setHomePage(toTab: tab, withNavigationController: navigationController)
        }
    }

    func setHomePage(toTab tab: Tab, withNavigationController navigationController: UINavigationController?) {
        let alertController = UIAlertController(
            title: Strings.SetHomePageDialogTitle,
            message: Strings.SetHomePageDialogMessage,
            preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(
            UIAlertAction(title: Strings.SetHomePageDialogNo, style: .Cancel) { (action) in
                // Do nothing.
            })
        alertController.addAction(
            UIAlertAction(title: Strings.SetHomePageDialogYes, style: .Default) { (action) in
                self.currentURL = tab.url
            })
        navigationController?.presentViewController(alertController, animated: true, completion: nil)
    }
}