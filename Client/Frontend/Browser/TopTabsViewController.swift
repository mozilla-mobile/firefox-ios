/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TopTabsUX {
    static let TopTabsViewHeight: CGFloat = 40
}

protocol TopTabsDelegate: class {
    func topTabsPressTabs()
}

class TopTabsViewController: UIViewController {
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate!
    
    private lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton()
        tabsButton.titleLabel.text = "0"
        tabsButton.addTarget(self, action: #selector(TopTabsViewController.tabsClicked), forControlEvents: UIControlEvents.TouchUpInside)
        tabsButton.accessibilityIdentifier = "TopTabsView.tabsButton"
        tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the tab toolbar")
        return tabsButton
    }()
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tabsButton)
        tabsButton.snp_makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(view)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }
        view.backgroundColor = UIColor.blackColor() // Temporary color
    }
    
    func updateTabCount(count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }
    
    func tabsClicked() {
        delegate.topTabsPressTabs()
    }
}

extension TopTabsViewController: Themeable {
    
    func applyTheme(themeName: String) {
        tabsButton.applyTheme(themeName)
    }
}
