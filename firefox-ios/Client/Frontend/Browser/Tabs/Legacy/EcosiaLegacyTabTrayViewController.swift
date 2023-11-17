// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import SnapKit
import Shared
import Storage
import Foundation
import Common

enum TabTrayViewAction {
    case addTab
    case deleteTab
}

// swiftlint:disable class_delegate_protocol
protocol TabTrayViewDelegate: UIViewController {
    func didTogglePrivateMode(_ togglePrivateModeOn: Bool)
    func performToolbarAction(_ action: TabTrayViewAction, sender: UIBarButtonItem)
}
// swiftlint:enable class_delegate_protocol

class LegacyTabTrayViewController: UIViewController, Themeable {

    struct UX {
        struct NavigationMenu {
            static let height: CGFloat = 32
            static let width: CGFloat = 343
        }
    }

    // MARK: - Variables
    var viewModel: LegacyTabTrayViewModel
    var openInNewTab: ((_ url: URL, _ isPrivate: Bool) -> Void)?
    var didSelectUrl: ((_ url: URL, _ visitType: VisitType) -> Void)?
    var notificationCenter: NotificationProtocol
    var nimbus: FxNimbus
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    // MARK: - UI Elements
    // Buttons & Menus
    lazy var deleteButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = "closeAllTabsButtonTabTray"
        button.setTitle(.localized(.closeAll), for: .normal)
        button.addTarget(self, action: #selector(didTapDeleteTabs), for: .primaryActionTriggered)
        button.accessibilityLabel = .AppMenu.Toolbar.TabTrayDeleteMenuButtonAccessibilityLabel
        return UIBarButtonItem(customView: button)
    }()

    lazy var addNewTabButton = CircleButton(config: .newTab, margin: 2)
    lazy var newTabButton: UIBarButtonItem = {
        addNewTabButton.translatesAutoresizingMaskIntoConstraints = false
        let height = addNewTabButton.heightAnchor.constraint(equalToConstant: 50)
        height.priority = .init(rawValue: 999)
        height.isActive = true

        let width = addNewTabButton.widthAnchor.constraint(equalToConstant: 50)
        width.priority = .init(rawValue: 999)
        width.isActive = true

        addNewTabButton.addTarget(self, action: #selector(didTapAddTab(_:)), for: .primaryActionTriggered)
        let buttonItem = UIBarButtonItem(customView: addNewTabButton)
        buttonItem.accessibilityIdentifier = "newTabButtonTabTray"
        return buttonItem
    }()

    lazy var maskButton = PrivateModeButton()
    lazy var maskButtonItem: UIBarButtonItem  = {
        maskButton.addTarget(self, action: #selector(togglePrivateMode), for: .primaryActionTriggered)
        let item = UIBarButtonItem(customView: maskButton)
        return item
    }()

    lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDone))
        button.accessibilityIdentifier = "doneButtonTabTray"
        return button
    }()

    lazy var syncTabButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .FxASyncNow,
                                     style: .plain,
                                     target: self,
                                     action: #selector(didTapSyncTabs))

        button.accessibilityIdentifier = "syncTabsButtonTabTray"
        return button
    }()

    lazy var syncLoadingView: UIStackView = {
        let syncingLabel = UILabel()
        syncingLabel.text = .SyncingMessageWithEllipsis

        let activityIndicator = UIActivityIndicatorView(style: .medium)
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
        fixedSpace.width = CGFloat(UX.NavigationMenu.height)
        return fixedSpace
    }()

    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButton.UX.titleFont
        label.layer.cornerRadius = TabsButton.UX.cornerRadius
        label.textAlignment = .center
        label.text = viewModel.normalTabsCount
        return label
    }()

    lazy var bottomToolbarItems: [UIBarButtonItem] = {
        return [maskButtonItem, flexibleSpace, newTabButton, flexibleSpace, deleteButton]
    }()

    lazy var bottomToolbarItemsForSync: [UIBarButtonItem] = {
        return [flexibleSpace, syncTabButton]
    }()

    lazy var navigationMenu: UISegmentedControl = {
        var navigationMenu: UISegmentedControl
        if shouldUseiPadSetup() {
            navigationMenu = iPadNavigationMenuIdentifiers
        } else {
            navigationMenu = iPhoneNavigationMenuIdentifiers
        }

        navigationMenu.accessibilityIdentifier = "navBarTabTray"

        var segmentToFocus = viewModel.segmentToFocus
        if segmentToFocus == nil {
            segmentToFocus = viewModel.tabManager.selectedTab?.isPrivate ?? false ? .privateTabs : .tabs
        }
        navigationMenu.selectedSegmentIndex = segmentToFocus?.rawValue ?? LegacyTabTrayViewModel.Segment.tabs.rawValue
        navigationMenu.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        return navigationMenu
    }()

    lazy var iPadNavigationMenuIdentifiers: UISegmentedControl = {
        return UISegmentedControl(items: LegacyTabTrayViewModel.Segment.allCases.map { $0.label })
    }()

    lazy var iPhoneNavigationMenuIdentifiers: UISegmentedControl = {
        return UISegmentedControl(items: [
            LegacyTabTrayViewModel.Segment.tabs.image!.overlayWith(image: countLabel),
            LegacyTabTrayViewModel.Segment.privateTabs.image!])
            // Ecosia: remove sync: LegacyTabTrayViewModel.Segment.syncedTabs.image!])
    }()

    /* Ecosia: hide navigation Toolbar
    // Toolbars
    lazy var navigationToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: navigationMenu)], animated: false)
        toolbar.isTranslucent = false
        return toolbar
    }()
    */

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Initializers
    init(tabTrayDelegate: TabTrayDelegate? = nil,
         profile: Profile,
         tabToFocus: Tab? = nil,
         tabManager: TabManager,
         overlayManager: OverlayModeManager,
         focusedSegment: LegacyTabTrayViewModel.Segment? = nil,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         and notificationCenter: NotificationProtocol = NotificationCenter.default,
         with nimbus: FxNimbus = FxNimbus.shared
    ) {
        self.nimbus = nimbus
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.viewModel = LegacyTabTrayViewModel(tabTrayDelegate: tabTrayDelegate,
                                          profile: profile,
                                          tabToFocus: tabToFocus,
                                          tabManager: tabManager,
                                          overlayManager: overlayManager,
                                          segmentToFocus: focusedSegment)

        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true

        setupNotifications(forObserver: self,
                           observing: [.ProfileDidStartSyncing,
                                       .ProfileDidFinishSyncing,
                                       .UpdateLabelOnTabClosed])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        viewSetup()
        listenForThemeChange(view)
        applyTheme()
        updatePrivateUIState()
        panelChanged()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // We expose the tab tray feature whenever it's going to be seen by the user
        // Ecosia // nimbus.features.tabTrayFeature.recordExposure()

        if shouldUseiPadSetup() {
            navigationController?.isToolbarHidden = true
        } else {
            navigationController?.isToolbarHidden = false
            updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
        }
    }

    private func viewSetup() {
        // viewModel.syncedTabsController.remotePanelDelegate = self

        /* Ecosia
        if let appWindow = (UIApplication.shared.delegate?.window),
           let window = appWindow as UIWindow? {
            window.backgroundColor = .black
        }
         */

        if shouldUseiPadSetup() {
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
        navigationItem.rightBarButtonItem = doneButton

        /* Ecosia: hide navigationToolbar
        view.addSubview(navigationToolbar)

        navigationToolbar.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.equalTo(view.safeArea.top)
        }
        */
        navigationItem.rightBarButtonItem = doneButton

        navigationMenu.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(UX.NavigationMenu.width)
            make.height.equalTo(UX.NavigationMenu.height)
        }
    }

    fileprivate func updateTitle() {
        guard !shouldUseiPadSetup(), let grid = viewModel.tabTrayView as? LegacyGridTabViewController else { return }
        navigationItem.title = grid.tabDisplayManager.isPrivate ?
        LegacyTabTrayViewModel.Segment.privateTabs.navTitle :
        LegacyTabTrayViewModel.Segment.tabs.navTitle
    }

    @objc func panelChanged() {
        let segment = LegacyTabTrayViewModel.Segment(rawValue: navigationMenu.selectedSegmentIndex)
        switch segment {
        case .tabs:
            switchBetweenLocalPanels(withPrivateMode: false, animated: false)
        case .privateTabs:
            switchBetweenLocalPanels(withPrivateMode: true, animated: false)
            /*
        case .syncedTabs:
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .libraryPanel, value: .syncPanel, extras: nil)
            if children.first == viewModel.tabTrayView {
                hideCurrentPanel()
                updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
                showPanel(viewModel.syncedTabsController)
            }
             */
        default:
            return
        }
    }

    // Ecosia: custom private mode UI
    @objc func togglePrivateMode() {
        guard let grid = viewModel.tabTrayView as? LegacyGridTabViewController else { return }
        switchBetweenLocalPanels(withPrivateMode: !grid.tabDisplayManager.isPrivate, animated: true)
    }

    fileprivate func updateMaskButton() {
        guard let grid = viewModel.tabTrayView as? LegacyGridTabViewController else { return }
        maskButton.isSelected = grid.tabDisplayManager.isPrivate
        maskButton.applyUIMode(isPrivate: grid.tabDisplayManager.isPrivate, theme: themeManager.currentTheme)
    }

    private func switchBetweenLocalPanels(withPrivateMode privateMode: Bool, animated: Bool) {
        if children.first != viewModel.tabTrayView {
            hideCurrentPanel()
            showPanel(viewModel.tabTrayView)
        }
        updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
        viewModel.tabTrayView.didTogglePrivateMode(privateMode)
        updatePrivateUIState()
        updateTitle()

        // Ecosia: update private button
        maskButton.setSelected(privateMode, animated: animated)
        maskButton.applyUIMode(isPrivate: privateMode, theme: themeManager.currentTheme)
    }

    private func showPanel(_ panel: UIViewController) {
        addChild(panel)
        panel.beginAppearanceTransition(true, animated: true)
        view.addSubview(panel.view)
        //Ecosia: view.bringSubviewToFront(navigationToolbar)
        // Ecosia: hide Toolbar
        // let topEdgeInset = shouldUseiPadSetup() ? 0 : GridTabTrayControllerUX.NavigationToolbarHeight
        let topEdgeInset: CGFloat = 0
        panel.additionalSafeAreaInsets = UIEdgeInsets(top: topEdgeInset, left: 0, bottom: 0, right: 0)
        panel.endAppearanceTransition()
        panel.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        panel.didMove(toParent: self)
        updateTitle()
        updateMaskButton()
    }

    private func hideCurrentPanel() {
        if let panel = children.first {
            panel.willMove(toParent: nil)
            panel.beginAppearanceTransition(false, animated: true)
            panel.view.removeFromSuperview()
            panel.endAppearanceTransition()
            panel.removeFromParent()
        }
    }

    private func updateToolbarItems(forSyncTabs showSyncItems: Bool = false) {
        if shouldUseiPadSetup() {
            navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButton]
            navigationItem.leftBarButtonItem = deleteButton
        } else {
            let newToolbarItems: [UIBarButtonItem]? = bottomToolbarItems
            setToolbarItems(newToolbarItems, animated: true)
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
                self.syncTabButton.title = .FxASyncNow
                self.syncTabButton.isEnabled = true
            }
        default:
            break
        }
    }
}

extension LegacyTabTrayViewController: TabTrayController {
    
    func remotePanelDidRequestToSignIn() {
        
    }
    
    func remotePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        self.openInNewTab?(url, isPrivate)
        self.dismissVC()
    }
    
    func remotePanel(didSelectURL url: URL, visitType: VisitType) {
        self.didSelectUrl?(url, visitType)
        self.dismissVC()
    }

}

// MARK: - Notifiable protocol
extension LegacyTabTrayViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .ProfileDidStartSyncing, .ProfileDidFinishSyncing:
                self?.updateButtonTitle(notification)
            case .UpdateLabelOnTabClosed:
                guard let label = self?.countLabel else { return }
                self?.countLabel.text = self?.viewModel.normalTabsCount
                self?.iPhoneNavigationMenuIdentifiers.setImage(UIImage(named: ImageIdentifiers.navTabCounter)!.overlayWith(image: label), forSegmentAt: 0)
            default: break
            }
        }
    }
}

// MARK: - Theme protocol
extension LegacyTabTrayViewController {
    
     @objc func applyTheme() {
         view.backgroundColor = UIColor.legacyTheme.tabTray.background
         //Ecosia: navigationToolbar.barTintColor = UIColor.theme.tabTray.toolbar
         //Ecosia: navigationToolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
         navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.ecosia.primaryText]
         // viewModel.syncedTabsController.applyTheme()

         // Ecosia
         if traitCollection.userInterfaceIdiom == .phone {
             navigationController?.navigationBar.tintColor = UIColor.legacyTheme.ecosia.primaryButton
         }
         maskButton.applyUIMode(isPrivate: maskButton.isSelected, theme: themeManager.currentTheme)
         // Ecosia: Update `addNewTabButton.applyTheme`
         // addNewTabButton.applyTheme()
         addNewTabButton.applyTheme(theme: themeManager.currentTheme)
         // Ecosia: Change close all button title color
         (deleteButton.customView as? UIButton)?.setTitleColor(.legacyTheme.ecosia.warning, for: .normal)
         
         if shouldUseiPadSetup() {
             navigationItem.leftBarButtonItem?.tintColor = UIColor.legacyTheme.ecosia.primaryButton
             navigationItem.rightBarButtonItem?.tintColor = UIColor.legacyTheme.ecosia.primaryButton
             navigationMenu.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.ecosia.primaryText], for: .normal)
             navigationMenu.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.legacyTheme.ecosia.segmentSelectedText], for: .selected)
         }
     }
 }

// MARK: - UIToolbarDelegate
extension LegacyTabTrayViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

// MARK: - Adaptive & Popover Presentation Delegates
extension LegacyTabTrayViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    // Returning None here, for the iPhone makes sure that the Popover is actually presented as a
    // Popover and not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {

        if shouldUseiPadSetup() {
            return .overFullScreen
        }

        return .none
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        notificationCenter.post(name: .TabsTrayDidClose)
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
    }
}

// MARK: - Button actions
extension LegacyTabTrayViewController {
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
        notificationCenter.post(name: .TabsTrayDidClose)
        self.dismiss(animated: true, completion: nil)
    }
}

/*
// MARK: - RemoteTabsPanel : LibraryPanelDelegate
extension LegacyTabTrayViewController: RemotePanelDelegate {
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
 */
