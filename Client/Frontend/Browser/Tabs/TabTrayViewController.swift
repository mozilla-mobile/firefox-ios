/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit

enum TabTrayViewAction {
    case addTab
    case deleteTab
}

protocol TabTrayViewDelegate: UIViewController {
    func didTogglePrivateMode(_ togglePrivateModeOn: Bool)
    func performToolbarAction(_ action: TabTrayViewAction, sender: UIButton)
}

class TabTrayViewController: UIViewController {
    let profile: Profile
    fileprivate let tabManager: TabManager

    let tabTrayView: TabTrayViewDelegate

    // Buttons & Menus
    lazy var deleteButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage.templateImageNamed("action_delete"), style: .plain, target: self, action: #selector(didTapDeleteTab(_:)))
    }()

    lazy var newTabButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: NewTabButton(target: self, selector: #selector(didTapAddTab)))
    }()

    lazy var syncTabButton: UIBarButtonItem = {
        return UIBarButtonItem(title: Strings.FxASyncNow, style: .plain, target: self, action: #selector(didTapSyncTabs))
    }()

    lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }()

    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = .center
        label.text = String(tabManager.normalTabs.count)
        return label
    }()

    lazy var navigationMenu: UISegmentedControl = {
        var navigationMenu: UISegmentedControl
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationMenu = UISegmentedControl(items: [Strings.TabTraySegmentedControlTitlesTabs,
                                                        Strings.TabTraySegmentedControlTitlesPrivateTabs,
                                                        Strings.TabTraySegmentedControlTitlesSyncedTabs])
        } else {
            navigationMenu = UISegmentedControl(items: [UIImage(named: "nav-tabcounter")!.overlayWith(image: countLabel),
                                                        UIImage(named: "smallPrivateMask")!,
                                                        UIImage(named: "synced_devices")!])
        }

        navigationMenu.accessibilityIdentifier = "navBarTabTray"
        navigationMenu.selectedSegmentIndex = tabManager.selectedTab?.isPrivate ?? false ? 1 : 0
        navigationMenu.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        return navigationMenu
    }()

    // Toolbars
    lazy var navigationToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.delegate = self

        // Different designs based on iPhone or iPad will require different setups
        if UIDevice.current.userInterfaceIdiom == .pad {
            toolbar.setItems([deleteButton,
                              flexibleSpace,
                              UIBarButtonItem(customView: navigationMenu),
                              flexibleSpace,
                              newTabButton], animated: false)
        } else {
            toolbar.setItems([UIBarButtonItem(customView: navigationMenu)], animated: false)
        }

        return toolbar
    }()

    lazy var bottomToolbarItems: [UIBarButtonItem] = {
        return [deleteButton, flexibleSpace, newTabButton]
    }()

    lazy var bottomToolbarItemsForSync: [UIBarButtonItem] = {
        return [flexibleSpace, syncTabButton]
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    init(tabTrayDelegate: TabTrayDelegate? = nil, profile: Profile, showChronTabs: Bool = false) {
        self.profile = profile
        self.tabManager = BrowserViewController.foregroundBVC().tabManager

        if showChronTabs {
            self.tabTrayView = ChronologicalTabsViewController(tabTrayDelegate: tabTrayDelegate, profile: profile)
        } else {
            self.tabTrayView = GridTabViewController(tabManager: self.tabManager, profile: profile, tabTrayDelegate: tabTrayDelegate)
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        applyTheme()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController?.isToolbarHidden = false
            setToolbarItems(bottomToolbarItems, animated: animated)
        }
    }

    private func viewSetup() {
        if let appWindow = (UIApplication.shared.delegate?.window),
           let window = appWindow as UIWindow? {
            window.backgroundColor = .black
        }

        navigationController?.navigationBar.shadowImage = UIImage()

        view.addSubview(navigationToolbar)

        navigationToolbar.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.equalTo(view.safeArea.top)
        }

        navigationMenu.snp.makeConstraints { make in
            if UIDevice.current.userInterfaceIdiom == .pad {
                make.width.equalTo(343)
            } else {
                make.width.lessThanOrEqualTo(343)
            }
            make.height.equalTo(ChronologicalTabsControllerUX.navigationMenuHeight)
        }

        showPanel(tabTrayView)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .DisplayThemeChanged, object: nil)
    }

    @objc func panelChanged() {
        switch navigationMenu.selectedSegmentIndex {
        case 0:
            switchBetweenLocalPanels(withPrivateMode: false)
        case 1:
            switchBetweenLocalPanels(withPrivateMode: true)
        case 2:
            if children.first == tabTrayView {
                hideCurrentPanel()
                let syncedTabsController = RemoteTabsPanel(profile: self.profile)
                setToolbarItems(bottomToolbarItemsForSync, animated: true)
                showPanel(syncedTabsController)
            }
        default:
            return
        }
    }

    fileprivate func switchBetweenLocalPanels(withPrivateMode privateMode: Bool) {
        if children.first != tabTrayView {
            hideCurrentPanel()
            showPanel(tabTrayView)
        }
        setToolbarItems(bottomToolbarItems, animated: true)
        tabTrayView.didTogglePrivateMode(privateMode)
    }

    fileprivate func showPanel(_ panel: UIViewController) {
        addChild(panel)
        panel.beginAppearanceTransition(true, animated: true)
        view.addSubview(panel.view)
        view.bringSubviewToFront(navigationToolbar)
        panel.additionalSafeAreaInsets = UIEdgeInsets(top: GridTabTrayControllerUX.NavigationToolbarHeight, left: 0, bottom: 0, right: 0)
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

// MARK: - Actions
extension TabTrayViewController {
    @objc func didTapDeleteTab(_ sender: UIButton) {
        tabTrayView.performToolbarAction(.deleteTab, sender: sender)
    }

    @objc func didTapAddTab(_ sender: UIButton) {
        tabTrayView.performToolbarAction(.addTab, sender: sender)
    }

    @objc func didTapSyncTabs(_ sender: UIButton) {
        // TODO: Sync tabs implementation
        print("I'm a gonna sync dem tabs!")
    }
}

extension TabTrayViewController: Themeable {
    @objc func applyTheme() {
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

        if UIDevice.current.userInterfaceIdiom == .pad {
            return .overFullScreen
        }

        return .none
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
    }
}
