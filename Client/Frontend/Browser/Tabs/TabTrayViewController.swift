/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit

protocol TabTrayViewDelegate: UIViewController {
    func didTogglePrivateMode(_ togglePrivateModeOn: Bool)
}

class TabTrayViewController: UIViewController {
    let profile: Profile
    fileprivate let tabManager: TabManager

    let tabTrayView: TabTrayViewDelegate

    // Toolbars
    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = .center
        label.text = String(tabManager.normalTabs.count)
        return label
    }()
    lazy var navigationMenu: UISegmentedControl = {
        let navigationMenu = UISegmentedControl(items: [UIImage(named: "nav-tabcounter")!.overlayWith(image: countLabel), UIImage(named: "smallPrivateMask")!, UIImage(named: "synced_devices")!])
        navigationMenu.accessibilityIdentifier = "navBarTabTray"
        navigationMenu.selectedSegmentIndex = tabManager.selectedTab?.isPrivate ?? false ? 1 : 0
        navigationMenu.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        return navigationMenu
    }()

    lazy var navigationToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: navigationMenu)], animated: false)
        return toolbar
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    init(tabTrayDelegate: TabTrayDelegate? = nil, profile: Profile, showChronTabs: Bool = false) {
        self.profile = profile
        self.tabManager = BrowserViewController.foregroundBVC().tabManager

        if showChronTabs {
            self.tabTrayView = TabTrayV2ViewController(tabTrayDelegate: tabTrayDelegate, profile: profile)
        } else {
            self.tabTrayView = TabTrayControllerV1(tabManager: self.tabManager, profile: profile, tabTrayDelegate: tabTrayDelegate)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        applyTheme()
    }

    private func viewSetup() {
        if let window = (UIApplication.shared.delegate?.window)! as UIWindow? {
            window.backgroundColor = .black
        }

        navigationController?.navigationBar.shadowImage = UIImage()

        // Add Subviews
        view.addSubview(navigationToolbar)

        navigationToolbar.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.equalTo(view.safeArea.top)
        }

        navigationMenu.snp.makeConstraints { make in
            make.height.equalTo(TabTrayV2ControllerUX.navigationMenuHeight)
        }

        showPanel(tabTrayView)
    }

    @objc func panelChanged() {
        switch navigationMenu.selectedSegmentIndex {
        case 0:
            if children.first != tabTrayView {
                hideCurrentPanel()
                showPanel(tabTrayView)
            }
            tabTrayView.didTogglePrivateMode(false)
        case 1:
            if children.first != tabTrayView {
                hideCurrentPanel()
                showPanel(tabTrayView)
            }
            tabTrayView.didTogglePrivateMode(true)
        case 2:
            if children.first == tabTrayView {
                hideCurrentPanel()
                let syncedTabsController = RemoteTabsPanel(profile: self.profile)
                showPanel(syncedTabsController)
            }
        default:
            return
        }
    }

    fileprivate func showPanel(_ panel: UIViewController) {
        addChild(panel)
        panel.beginAppearanceTransition(true, animated: true)
        view.addSubview(panel.view)
        view.bringSubviewToFront(navigationToolbar)
        panel.additionalSafeAreaInsets = UIEdgeInsets(top: TabTrayControllerUX.NavigationToolbarHeight, left: 0, bottom: 0, right: 0)
        panel.endAppearanceTransition()
        panel.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.didMove(toParent: self)
    }

    fileprivate func hideCurrentPanel() {
        if let panel = children.first {
            panel.willMove(toParent: nil)
            panel.beginAppearanceTransition(false, animated: true)
            panel.view.removeFromSuperview()
            panel.endAppearanceTransition()
            panel.removeFromParent()
        }
    }
}

extension TabTrayViewController: Themeable {
    func applyTheme() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = ThemeManager.instance.userInterfaceStyle
            view.backgroundColor = UIColor.systemGroupedBackground
            navigationController?.navigationBar.tintColor = UIColor.label
            navigationController?.toolbar.tintColor = UIColor.label
            navigationItem.rightBarButtonItem?.tintColor = UIColor.label
        } else {
            view.backgroundColor = UIColor.theme.tableView.headerBackground
            navigationController?.navigationBar.barTintColor = UIColor.theme.tabTray.toolbar
            navigationController?.navigationBar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
            navigationController?.toolbar.barTintColor = UIColor.theme.tabTray.toolbar
            navigationController?.toolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
            navigationItem.rightBarButtonItem?.tintColor = UIColor.theme.tabTray.toolbarButtonTint
            navigationToolbar.barTintColor = UIColor.theme.tabTray.toolbar
            navigationToolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
        }
        setNeedsStatusBarAppearanceUpdate()
    }
}

extension TabTrayViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension TabTrayViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
    }
}
