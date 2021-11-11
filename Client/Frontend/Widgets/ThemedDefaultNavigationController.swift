// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class ThemedDefaultNavigationController: DismissableNavigationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }
}

extension ThemedDefaultNavigationController: NotificationThemeable {
    
    private func setupNavigationBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = UIColor.theme.tabTray.toolbar
        standardAppearance.shadowColor = nil
        standardAppearance.shadowImage = UIImage()
        
        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = standardAppearance
        }
        navigationBar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
    }
    
    private func setupToolBarAppearance() {
        let standardAppearance = UIToolbarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = UIColor.theme.tabTray.toolbar
        standardAppearance.shadowColor = nil
        standardAppearance.shadowImage = UIImage()
        
        toolbar.standardAppearance = standardAppearance
        toolbar.compactAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            toolbar.scrollEdgeAppearance = standardAppearance
            toolbar.compactScrollEdgeAppearance = standardAppearance
        }
        toolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
    }
    
    func applyTheme() {
        setupNavigationBarAppearance()
        setupToolBarAppearance()
        
        setNeedsStatusBarAppearanceUpdate()
        viewControllers.forEach { ($0 as? NotificationThemeable)?.applyTheme() }
    }
}
