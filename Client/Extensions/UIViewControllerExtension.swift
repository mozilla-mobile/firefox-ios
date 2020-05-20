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
 

