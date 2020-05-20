/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

enum NavigationItemLocation {
    case Left
    case Right
}

enum NavigationItemText {
    case Done
    case Close

    func localizedString() -> String {
        switch self {
        case .Done:
            return Strings.SettingsSearchDoneButton
        case .Close:
            return Strings.CloseButtonTitle
        }
    }
}

extension UIViewController {
    /// This presents a View Controller with a bar button item that can be used to dismiss the VC
    /// - Parameters:
    ///     - navItemLocation: Define whether dismiss bar button item should be on the right or left of the navigation bar
    ///     - navItemText: Define whether bar button item text should be "Done" or "Close"
    ///     - vcBeingPresented: ViewController to present with this bar button item
    ///     - topTabsVisible: If tabs of browser should still be visible. iPad only.
    func presentThemedViewController(navItemLocation: NavigationItemLocation, navItemText: NavigationItemText, vcBeingPresented: UIViewController, topTabsVisible: Bool) {
        let vcToPresent = vcBeingPresented
        let buttonItem = UIBarButtonItem(title: navItemText.localizedString(), style: .plain, target: self, action: #selector(dismissVC))
        switch navItemLocation {
        case .Left:
            vcToPresent.navigationItem.leftBarButtonItem = buttonItem
        case .Right:
            vcToPresent.navigationItem.rightBarButtonItem = buttonItem
        }
        let themedNavigationController = ThemedNavigationController(rootViewController: vcToPresent)
        themedNavigationController.navigationBar.isTranslucent = false
        if topTabsVisible {
            themedNavigationController.preferredContentSize = CGSize(width: ViewControllerConsts.PreferredSize.IntroViewController.width, height: ViewControllerConsts.PreferredSize.IntroViewController.height)
            themedNavigationController.modalPresentationStyle = .formSheet
        } else {
            themedNavigationController.modalPresentationStyle = .fullScreen
        }
        self.present(themedNavigationController, animated: true, completion: nil)
    }
    
    @objc func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }
}
 

