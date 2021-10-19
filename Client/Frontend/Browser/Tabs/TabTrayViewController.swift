/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SnapKit
import Shared
import Storage

enum TabTrayViewAction {
    case addTab
    case deleteTab
}

protocol TabTrayViewDelegate: UIViewController {
    func didTogglePrivateMode(_ togglePrivateModeOn: Bool)
    func performToolbarAction(_ action: TabTrayViewAction, sender: UIBarButtonItem)
}

class TabTrayViewController: UIViewController {
    var viewModel: TabTrayViewModel
    var openInNewTab: ((_ url: URL, _ isPrivate: Bool) -> Void)?
    var didSelectUrl: ((_ url: URL, _ visitType: VisitType) -> Void)?
    
    // Buttons & Menus
    lazy var deleteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed("action_delete"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(didTapDeleteTabs(_:)))
        button.accessibilityIdentifier = "closeAllTabsButtonTabTray"
        return button
    }()

    lazy var newTabButton: UIBarButtonItem = {
        let button = UIBarButtonItem(customView: NewTabButton(target: self, selector: #selector(didTapAddTab(_:))))
        button.accessibilityIdentifier = "newTabButtonTabTray"
        return button
    }()

    lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDone))
        button.accessibilityIdentifier = "doneButtonTabTray"
        return button
    }()

    lazy var syncTabButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: Strings.FxASyncNow,
                                     style: .plain,
                                     target: self,
                                     action: #selector(didTapSyncTabs))
        
        button.accessibilityIdentifier = "syncTabsButtonTabTray"
        return button
    }()
    
    lazy var syncLoadingView: UIStackView = {
        let syncingLabel = UILabel()
        syncingLabel.text = Strings.SyncingMessageWithEllipsis
        
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.color = .systemGray
        activityIndicator.startAnimating()
        
        let stackView = UIStackView(arrangedSubviews: [syncingLabel, activityIndicator])
        stackView.spacing = 12
        return stackView
    }()

    lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                               target: nil,
                               action: nil)
    }()

    lazy var fixedSpace: UIBarButtonItem = {
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace,
                               target: nil,
                               action: nil)
        fixedSpace.width = 32
        return fixedSpace
    }()

    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = .center
        label.text = viewModel.normalTabsCount
        return label
    }()

    lazy var bottomToolbarItems: [UIBarButtonItem] = {
        return [deleteButton, flexibleSpace, newTabButton]
    }()

    lazy var bottomToolbarItemsForSync: [UIBarButtonItem] = {
        return [flexibleSpace, syncTabButton]
    }()

    lazy var navigationMenu: UISegmentedControl = {
        var navigationMenu: UISegmentedControl
        if shouldUseiPadSetup {
            navigationMenu = iPadNavigationMenuIdentifiers
        } else {
            navigationMenu = iPhoneNavigationMenuIdentifiers
        }

        navigationMenu.accessibilityIdentifier = "navBarTabTray"
        navigationMenu.selectedSegmentIndex = viewModel.tabManager.selectedTab?.isPrivate ?? false ? 1 : 0
        navigationMenu.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        return navigationMenu
    }()

    lazy var iPadNavigationMenuIdentifiers: UISegmentedControl = {
        return UISegmentedControl(items: [Strings.TabTraySegmentedControlTitlesTabs,
                                          Strings.TabTraySegmentedControlTitlesPrivateTabs,
                                          Strings.TabTraySegmentedControlTitlesSyncedTabs])
    }()

    lazy var iPhoneNavigationMenuIdentifiers: UISegmentedControl = {
        return UISegmentedControl(items: [UIImage(named: "nav-tabcounter")!.overlayWith(image: countLabel),
                                          UIImage(named: "smallPrivateMask")!,
                                          UIImage(named: "synced_devices")!])
    }()

    // Toolbars
    lazy var navigationToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: navigationMenu)], animated: false)
        toolbar.isTranslucent = false
        return toolbar
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // Initializers
    init(tabTrayDelegate: TabTrayDelegate? = nil, profile: Profile, showChronTabs: Bool = false, tabToFocus: Tab? = nil) {
        self.viewModel = TabTrayViewModel(tabTrayDelegate: tabTrayDelegate, profile: profile, showChronTabs: showChronTabs, tabToFocus: tabToFocus)

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
        updatePrivateUIState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldUseiPadSetup {
            navigationController?.isToolbarHidden = true
        } else {
            navigationController?.isToolbarHidden = false
            updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
        }
    }

    private func viewSetup() {
        viewModel.syncedTabsController.remotePanelDelegate = self
        
        if let appWindow = (UIApplication.shared.delegate?.window),
           let window = appWindow as UIWindow? {
            window.backgroundColor = .black
        }
        
        if shouldUseiPadSetup {
            iPadViewSetup()
        } else {
            iPhoneViewSetup()
        }

        showPanel(viewModel.tabTrayView)
    }
    
    func updatePrivateUIState() {
        UserDefaults.standard.set(viewModel.tabManager.selectedTab?.isPrivate ?? false, forKey: "wasLastSessionPrivate")
    }

    fileprivate func iPadViewSetup() {
        navigationItem.leftBarButtonItem = deleteButton
        navigationItem.titleView = navigationMenu
        navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButton]

        navigationItem.titleView?.snp.makeConstraints { make in
            make.width.equalTo(343)
        }
    }

    fileprivate func iPhoneViewSetup() {
        view.addSubview(navigationToolbar)

        navigationToolbar.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.equalTo(view.safeArea.top)
        }

        navigationMenu.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(343)
            make.height.equalTo(ChronologicalTabsControllerUX.navigationMenuHeight)
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .ProfileDidStartSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .ProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .TabClosed, object: nil)
    }

    fileprivate func updateTitle() {
        if let newTitle = viewModel.navTitle(for: navigationMenu.selectedSegmentIndex,
                                             foriPhone: !shouldUseiPadSetup) {
            navigationItem.title  = newTitle
        }
    }

    @objc func panelChanged() {
        switch navigationMenu.selectedSegmentIndex {
        case 0:
            switchBetweenLocalPanels(withPrivateMode: false)
        case 1:
            switchBetweenLocalPanels(withPrivateMode: true)
        case 2:
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .libraryPanel, value: .syncPanel, extras: nil)
            if children.first == viewModel.tabTrayView {
                hideCurrentPanel()
                updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
                showPanel(viewModel.syncedTabsController)
            }
        default:
            return
        }
    }

    fileprivate func switchBetweenLocalPanels(withPrivateMode privateMode: Bool) {
        if children.first != viewModel.tabTrayView {
            hideCurrentPanel()
            showPanel(viewModel.tabTrayView)
        }
        updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
        viewModel.tabTrayView.didTogglePrivateMode(privateMode)
        updatePrivateUIState()
    }

    fileprivate func showPanel(_ panel: UIViewController) {
        addChild(panel)
        panel.beginAppearanceTransition(true, animated: true)
        view.addSubview(panel.view)
        view.bringSubviewToFront(navigationToolbar)
        let topEdgeInset = shouldUseiPadSetup ? 0 : GridTabTrayControllerUX.NavigationToolbarHeight
        panel.additionalSafeAreaInsets = UIEdgeInsets(top: topEdgeInset, left: 0, bottom: 0, right: 0)
        panel.endAppearanceTransition()
        panel.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.didMove(toParent: self)
        updateTitle()
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

    fileprivate func updateToolbarItems(forSyncTabs showSyncItems: Bool = false) {
        if shouldUseiPadSetup {
            if navigationMenu.selectedSegmentIndex == 2 {
                navigationItem.rightBarButtonItems = (showSyncItems ? [doneButton, fixedSpace, syncTabButton] : [doneButton])
                navigationItem.leftBarButtonItem = nil
            } else {
                navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButton]
                navigationItem.leftBarButtonItem = deleteButton
            }
        } else {
            var newToolbarItems: [UIBarButtonItem]? = bottomToolbarItems
            if navigationMenu.selectedSegmentIndex == 2 {
                newToolbarItems = showSyncItems ? bottomToolbarItemsForSync : nil
            }
            setToolbarItems(newToolbarItems, animated: true)
        }
    }
    
    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        case .ProfileDidStartSyncing, .ProfileDidFinishSyncing:
            updateButtonTitle(notification)
        case .TabClosed:
            countLabel.text = viewModel.normalTabsCount
            iPhoneNavigationMenuIdentifiers.setImage(UIImage(named: "nav-tabcounter")!.overlayWith(image: countLabel), forSegmentAt: 0)
        default:
            break
        }
    }
    
    private func updateButtonTitle(_ notification: Notification) {
        switch notification.name {
        case .ProfileDidStartSyncing:
            // Update Sync Tab button
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.syncTabButton.isEnabled = false
                self.syncTabButton.customView = self.syncLoadingView
            }
        case .ProfileDidFinishSyncing:
            // Update Sync Tab button
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.syncTabButton.customView = nil
                self.syncTabButton.title = Strings.FxASyncNow
                self.syncTabButton.isEnabled = true
            }
        default:
            break
        }
    }
}

extension TabTrayViewController: Themeable {
     @objc func applyTheme() {
         overrideUserInterfaceStyle =  ThemeManager.instance.userInterfaceStyle
         view.backgroundColor = UIColor.theme.tabTray.background
         navigationToolbar.barTintColor = UIColor.theme.tabTray.toolbar
         navigationToolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
         let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
         if theme == .dark {
             navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
         } else {
             navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
         }
         viewModel.syncedTabsController.applyTheme()
     }
 }

extension TabTrayViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension TabTrayViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    // Returning None here, for the iPhone makes sure that the Popover is actually presented as a
    // Popover and not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {

        if shouldUseiPadSetup {
            return .overFullScreen
        }

        return .none
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
    }
}

// MARK: - Button actions
extension TabTrayViewController {
    @objc func didTapAddTab(_ sender: UIBarButtonItem) {
        viewModel.didTapAddTab(sender)
    }

    @objc func didTapDeleteTabs(_ sender: UIBarButtonItem) {
        viewModel.didTapDeleteTab(sender)
    }

    @objc func didTapSyncTabs(_ sender: UIBarButtonItem) {
        viewModel.didTapSyncTabs(sender)
    }

    @objc func didTapDone() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - RemoteTabsPanel : LibraryPanelDelegate

extension TabTrayViewController: RemotePanelDelegate {
        func remotePanelDidRequestToSignIn() {
            fxaSignInOrCreateAccountHelper()
        }
        
        func remotePanelDidRequestToCreateAccount() {
            fxaSignInOrCreateAccountHelper()
        }
        
        func remotePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .syncTab)
            self.openInNewTab?(url, isPrivate)
            self.dismissVC()
        }
        
        func remotePanel(didSelectURL url: URL, visitType: VisitType) {
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .syncTab)
            self.didSelectUrl?(url, visitType)
            self.dismissVC()
        }
    
        // Sign In and Create Account Helper
        func fxaSignInOrCreateAccountHelper() {
            let fxaParams = FxALaunchParams(query: ["entrypoint": "homepanel"])
            let controller = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(fxaParams, flowType: .emailLoginFlow, referringPage: .tabTray, profile: viewModel.profile)
            (controller as? FirefoxAccountSignInViewController)?.shouldReload = { [weak self] in
                self?.viewModel.reloadRemoteTabs()
            }
            presentThemedViewController(navItemLocation: .Left, navItemText: .Close, vcBeingPresented: controller, topTabsVisible: UIDevice.current.userInterfaceIdiom == .pad)
        }
}
