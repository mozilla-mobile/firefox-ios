//
//  ThemedDefaultNavigationController.swift
//  Client
//
//  Created by MUSTAFA HASTURK on 15.10.2021.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit

class ThemedDefaultNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }
}

extension ThemedDefaultNavigationController: Themeable {
    
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
        viewControllers.forEach { ($0 as? Themeable)?.applyTheme() }
    }
}
