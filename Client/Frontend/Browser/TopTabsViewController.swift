//
//  TopTabsViewController.swift
//  Client
//
//  Created by Tyler Lacroix on 6/7/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class TopTabsViewController: UIViewController {
    let tabManager: TabManager
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.redColor() // Temporary color
    }
}
