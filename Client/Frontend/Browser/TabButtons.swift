//
//  TabButtons.swift
//  Client
//
//  Created by Tyler Lacroix on 6/27/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

extension UIButton {
    static func privateModeButton() -> UIButton {
        let privateTab = UIButton()
        privateTab.setImage(UIImage.templateImageNamed("menu-NewPrivateTab-pbm"), forState: .Normal)
        privateTab.tintColor = UIColor(white: 0.9, alpha: 1)
        privateTab.setImage(UIImage(named: "menu-NewPrivateTab-pbm"), forState: .Highlighted)
        privateTab.accessibilityLabel = NSLocalizedString("Private Tab", comment: "Accessibility label for the Private Tab button in the tab toolbar.")
        return privateTab
    }
    
    static func newTabButton() -> UIButton {
        let newTab = UIButton()
        newTab.setImage(UIImage.templateImageNamed("menu-NewTab-pbm"), forState: .Normal)
        newTab.tintColor = UIColor(white: 0.9, alpha: 1)
        newTab.setImage(UIImage(named: "menu-NewTab-pbm"), forState: .Highlighted)
        newTab.accessibilityLabel = NSLocalizedString("New Tab", comment: "Accessibility label for the New Tab button in the tab toolbar.")
        return newTab
    }
}

extension TabsButton {
    static func tabTrayButton() -> TabsButton {
        let tabsButton = TabsButton()
        tabsButton.titleLabel.text = "0"
        tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the tab toolbar")
        return tabsButton
    }
}
