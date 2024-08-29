// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import Foundation
import UIKit
import Common

import enum MozillaAppServices.VisitType

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

class LegacyTabTrayViewController: UIViewController, Themeable, TabTrayController {
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
    weak var qrCodeNavigationHandler: QRCodeNavigationHandler?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    // MARK: - UI Elements
    private var titleWidthConstraint: NSLayoutConstraint?
    private var compactContainerTopConstraint: NSLayoutConstraint!
    private var regularContainerTopConstraint: NSLayoutConstraint!
    private var containerView: UIView = .build { view in }

    // Buttons & Menus
    private lazy var deleteButtonIpad: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.delete,
                                action: #selector(didTapDeleteTabs(_:)),
                                a11yId: AccessibilityIdentifiers.TabTray.closeAllTabsButton,
                                a11yLabel: .LegacyAppMenu.Toolbar.TabTrayDeleteMenuButtonAccessibilityLabel)
    }()

    private lazy var newTabButtonIpad: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.plus,
                                action: #selector(didTapAddTab(_:)),
                                a11yId: AccessibilityIdentifiers.TabTray.newTabButton,
                                a11yLabel: .TabTrayAddTabAccessibilityLabel)
    }()

    private lazy var deleteButtonIphone: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.delete,
                                action: #selector(didTapDeleteTabs(_:)),
                                a11yId: AccessibilityIdentifiers.TabTray.closeAllTabsButton,
                                a11yLabel: .LegacyAppMenu.Toolbar.TabTrayDeleteMenuButtonAccessibilityLabel)
    }()

    private lazy var newTabButtonIphone: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.plus,
                                action: #selector(didTapAddTab(_:)),
                                a11yId: AccessibilityIdentifiers.TabTray.newTabButton,
                                a11yLabel: .TabTrayAddTabAccessibilityLabel)
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDone))
        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.doneButton
        return button
    }()

    private lazy var syncTabButtonIpad: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .TabsTray.Sync.SyncTabs,
                                     style: .plain,
                                     target: self,
                                     action: #selector(didTapSyncTabs))

        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.syncTabsButton
        return button
    }()

    private lazy var syncTabButtonIphone: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .TabsTray.Sync.SyncTabs,
                                     style: .plain,
                                     target: self,
                                     action: #selector(didTapSyncTabs))

        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.syncTabsButton
        return button
    }()

    private func syncLoadingView() -> UIStackView {
        let syncingLabel = UILabel()
        syncingLabel.text = .SyncingMessageWithEllipsis
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        syncingLabel.textColor = theme.colors.textPrimary

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = theme.colors.textPrimary
        activityIndicator.startAnimating()

        let stackView = UIStackView(arrangedSubviews: [syncingLabel, activityIndicator])
        stackView.spacing = 12

        return stackView
    }

    private lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                               target: nil,
                               action: nil)
    }()

    private lazy var fixedSpace: UIBarButtonItem = {
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
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var bottomToolbarItems: [UIBarButtonItem] = {
        return [deleteButtonIphone, flexibleSpace, newTabButtonIphone]
    }()

    private lazy var bottomToolbarItemsForSync: [UIBarButtonItem] = {
        return [flexibleSpace, syncTabButtonIphone]
    }()

    private lazy var segmentedControlIpad: UISegmentedControl = {
        let items = TabTrayPanelType.allCases.map { $0.label }
        return createSegmentedControl(items: items,
                                      action: #selector(segmentIpadChanged),
                                      a11yId: AccessibilityIdentifiers.TabTray.navBarSegmentedControl)
    }()

    private lazy var segmentedControlIphone: UISegmentedControl = {
        let items = [
            TabTrayPanelType.tabs.image!.overlayWith(image: countLabel),
            TabTrayPanelType.privateTabs.image!,
            TabTrayPanelType.syncedTabs.image!]
        return createSegmentedControl(items: items,
                                      action: #selector(segmentIphoneChanged),
                                      a11yId: AccessibilityIdentifiers.TabTray.navBarSegmentedControl)
    }()

    // Toolbars
    private lazy var navigationToolbar: UIToolbar = .build { [self] toolbar in
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: segmentedControlIphone)], animated: false)
        toolbar.isTranslucent = false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Initializers
    init(tabTrayDelegate: TabTrayDelegate? = nil,
         profile: Profile,
         tabToFocus: Tab? = nil,
         tabManager: TabManager,
         overlayManager: OverlayModeManager,
         focusedSegment: TabTrayPanelType? = nil,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         and notificationCenter: NotificationProtocol = NotificationCenter.default,
         with nimbus: FxNimbus = FxNimbus.shared
    ) {
        self.nimbus = nimbus
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.windowUUID = tabManager.windowUUID
        self.viewModel = LegacyTabTrayViewModel(tabTrayDelegate: tabTrayDelegate,
                                                profile: profile,
                                                tabToFocus: tabToFocus,
                                                tabManager: tabManager,
                                                overlayManager: overlayManager,
                                                segmentToFocus: focusedSegment)

        super.init(nibName: nil, bundle: nil)

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
        updatePrivateUIState()
        applyTheme()
        changePanel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // We expose the tab tray feature whenever it's going to be seen by the user
        nimbus.features.tabTrayFeature.recordExposure()

        viewModel.layout = shouldUseiPadSetup() ? .regular : .compact

        updateLayout()
    }

    private func viewSetup() {
        viewModel.syncedTabsController.remotePanelDelegate = self

        // iPad setup
        navigationItem.titleView = segmentedControlIpad

        if let titleView = navigationItem.titleView {
            titleWidthConstraint = titleView.widthAnchor.constraint(equalToConstant: UX.NavigationMenu.width)
            titleWidthConstraint?.isActive = true
        }

        // iPhone setup
        view.addSubview(navigationToolbar)
        navigationToolbar.setItems([UIBarButtonItem(customView: segmentedControlIphone)], animated: false)

        view.addSubviews(containerView)

        compactContainerTopConstraint = containerView.topAnchor.constraint(equalTo: navigationToolbar.bottomAnchor)
        regularContainerTopConstraint = containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)

        NSLayoutConstraint.activate([
            navigationToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            compactContainerTopConstraint,
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        showPanel(viewModel.tabTrayView)
    }

    func updatePrivateUIState() {
        UserDefaults.standard.set(
            viewModel.tabManager.selectedTab?.isPrivate ?? false,
            forKey: PrefsKeys.LastSessionWasPrivate
        )
    }

    private func updateTitle() {
        if let newTitle = viewModel.navTitle(for: segmentedControlIphone.selectedSegmentIndex) {
            // iPhone
            navigationItem.titleView = nil
            navigationItem.title = newTitle
            updateContainerConstraints(isCompact: true)
        } else {
            // iPad in compact or regular
            navigationItem.titleView = viewModel.layout == .compact ? segmentedControlIphone : segmentedControlIpad
            navigationItem.title = nil
            updateContainerConstraints(isCompact: viewModel.layout == .compact)
        }
    }

    func updateContainerConstraints(isCompact: Bool) {
        compactContainerTopConstraint.isActive = isCompact
        regularContainerTopConstraint.isActive = !isCompact
    }

    @objc
    func segmentIphoneChanged() {
        segmentedControlIpad.selectedSegmentIndex = segmentedControlIphone.selectedSegmentIndex
        changePanel()
    }

    @objc
    func segmentIpadChanged() {
        segmentedControlIphone.selectedSegmentIndex = segmentedControlIpad.selectedSegmentIndex
        changePanel()
    }

    private func changePanel() {
        let segment = TabTrayPanelType(rawValue: segmentedControlIphone.selectedSegmentIndex)
        viewModel.segmentToFocus = segment
        switch segment {
        case .tabs:
            switchBetweenLocalPanels(withPrivateMode: false)
        case .privateTabs:
            switchBetweenLocalPanels(withPrivateMode: true)
        case .syncedTabs:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .libraryPanel,
                                         value: .syncPanel,
                                         extras: nil)
            if children.first == viewModel.tabTrayView {
                hideCurrentPanel()
                updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
                showPanel(viewModel.syncedTabsController)
            }
        default:
            return
        }
    }

    private func switchBetweenLocalPanels(withPrivateMode privateMode: Bool) {
        if children.first != viewModel.tabTrayView {
            hideCurrentPanel()
            showPanel(viewModel.tabTrayView)
        }
        updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
        viewModel.tabTrayView.didTogglePrivateMode(privateMode)
        updatePrivateUIState()
        updateTitle()
    }

    private func showPanel(_ panel: UIViewController) {
        addChild(panel)
        panel.beginAppearanceTransition(true, animated: true)
        containerView.addSubview(panel.view)
        containerView.bringSubviewToFront(navigationToolbar)
        panel.endAppearanceTransition()
        panel.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            panel.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            panel.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            panel.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            panel.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        panel.didMove(toParent: self)
        updateTitle()
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
        // The "Synced" panel has different toolbar items so we handle them separately.
        guard segmentedControlIphone.selectedSegmentIndex != TabTrayPanelType.syncedTabs.rawValue else {
            updateSyncedToolbarItems(forSyncTabs: showSyncItems)
            return
        }

        switch viewModel.layout {
        case .compact:
            setToolbarItems(bottomToolbarItems, animated: true)
        case .regular:
            navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButtonIpad]
            navigationItem.leftBarButtonItem = deleteButtonIpad
        }
    }

    private func updateSyncedToolbarItems(forSyncTabs showSyncItems: Bool = false) {
        guard segmentedControlIphone.selectedSegmentIndex == TabTrayPanelType.syncedTabs.rawValue
        else { return }

        switch viewModel.layout {
        case .compact:
            let newToolbarItems = showSyncItems ? bottomToolbarItemsForSync : nil
            setToolbarItems(newToolbarItems, animated: true)
        case .regular:
            navigationItem.rightBarButtonItems = showSyncItems ? [doneButton, fixedSpace, syncTabButtonIpad] : [doneButton]
            navigationItem.leftBarButtonItem = nil
        }
    }

    private func updateButtonTitle(_ notification: Notification) {
        switch notification.name {
        case .ProfileDidStartSyncing:
            // Update Sync Tab button
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.syncTabButtonIpad.isEnabled = false
                self.syncTabButtonIpad.customView = self.syncLoadingView()

                self.syncTabButtonIphone.isEnabled = false
                self.syncTabButtonIphone.customView = self.syncLoadingView()
            }
        case .ProfileDidFinishSyncing:
            // Update Sync Tab button
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.syncTabButtonIpad.customView = nil
                self.syncTabButtonIpad.title = .TabsTray.Sync.SyncTabs
                self.syncTabButtonIpad.isEnabled = true

                self.syncTabButtonIphone.customView = nil
                self.syncTabButtonIphone.title = .TabsTray.Sync.SyncTabs
                self.syncTabButtonIphone.isEnabled = true
            }
        default:
            break
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if UIDevice.current.userInterfaceIdiom == .pad {
            viewModel.layout = shouldUseiPadSetup() ? .regular : .compact
            updateLayout()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            viewModel.layout = shouldUseiPadSetup() ? .regular : .compact
            updateLayout()
        }
    }

    /// On iPhone, we call updateLayout when the trait collection has changed, to ensure calculation
    /// is done with the new trait. On iPad, trait collection doesn't change from portrait to landscape (and vice-versa)
    /// since it's `.regular` on both. We updateLayout from viewWillTransition in that case.
    private func updateLayout() {
        let shouldUseiPadSetup = viewModel.layout == .regular
        navigationController?.isToolbarHidden = shouldUseiPadSetup
        titleWidthConstraint?.isActive = shouldUseiPadSetup

        switch viewModel.layout {
        case .compact:
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = [doneButton]
        case .regular:
            navigationItem.leftBarButtonItem = deleteButtonIpad
            navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButtonIpad]
        }

        segmentedControlIpad.isHidden = !shouldUseiPadSetup
        navigationToolbar.isHidden = shouldUseiPadSetup

        updateToolbarItems(forSyncTabs: viewModel.profile.hasSyncableAccount())
        updateTitle()
    }

    private func createButtonItem(imageName: String,
                                  action: Selector,
                                  a11yId: String,
                                  a11yLabel: String) -> UIBarButtonItem {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed(imageName),
                                     style: .plain,
                                     target: self,
                                     action: action)
        button.accessibilityIdentifier = a11yId
        button.accessibilityLabel = a11yLabel
        return button
    }

    private func createSegmentedControl(
        items: [Any],
        action: Selector,
        a11yId: String
    ) -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = true
        segmentedControl.accessibilityIdentifier = a11yId

        var segmentToFocus = viewModel.segmentToFocus
        if segmentToFocus == nil {
            segmentToFocus = viewModel.tabManager.selectedTab?.isPrivate ?? false ? .privateTabs : .tabs
        }
        segmentedControl.selectedSegmentIndex = segmentToFocus?.rawValue ?? TabTrayPanelType.tabs.rawValue
        segmentedControl.addTarget(self, action: action, for: .valueChanged)
        return segmentedControl
    }

    // MARK: - Themable

    func applyTheme() {
        view.backgroundColor = themeManager.getCurrentTheme(for: windowUUID).colors.layer4
        navigationToolbar.barTintColor = themeManager.getCurrentTheme(for: windowUUID).colors.layer1
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
                guard let label = self?.countLabel,
                      notification.windowUUID == self?.windowUUID
                else { return }
                self?.countLabel.text = self?.viewModel.normalTabsCount
                if let image = UIImage(named: StandardImageIdentifiers.Large.tab) {
                    self?.segmentedControlIphone.setImage(image.overlayWith(image: label), forSegmentAt: 0)
                }
            default: break
            }
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
extension LegacyTabTrayViewController: UIAdaptivePresentationControllerDelegate,
                                       UIPopoverPresentationControllerDelegate {
    // Returning None here, for the iPhone makes sure that the Popover is actually presented as a
    // Popover and not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        if shouldUseiPadSetup(traitCollection: traitCollection) {
            return .overFullScreen
        }
        return .none
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        notificationCenter.post(name: .TabsTrayDidClose, withUserInfo: windowUUID.userInfo)
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
    }
}

// MARK: - Button actions
extension LegacyTabTrayViewController {
    @objc
    func didTapAddTab(_ sender: UIBarButtonItem) {
        notificationCenter.post(name: .TabsTrayDidClose, withUserInfo: windowUUID.userInfo)
        viewModel.didTapAddTab(sender)
        self.dismiss(animated: true) {
            self.viewModel.didDismiss()
        }
    }

    @objc
    func didTapDeleteTabs(_ sender: UIBarButtonItem) {
        viewModel.didTapDeleteTab(sender)
    }

    @objc
    func didTapSyncTabs(_ sender: UIBarButtonItem) {
        viewModel.didTapSyncTabs(sender)
    }

    @objc
    func didTapDone() {
        notificationCenter.post(name: .TabsTrayDidClose, withUserInfo: windowUUID.userInfo)
        // Update Private mode when closing TabTray, if the mode toggle but
        // no tab is pressed with return to previous state
        updatePrivateUIState()
        viewModel.tabTrayView.didTogglePrivateMode(viewModel.tabManager.selectedTab?.isPrivate ?? false)
        if viewModel.segmentToFocus == .privateTabs {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .privateBrowsingIcon,
                                         value: .tabTray,
                                         extras: [TelemetryWrapper.EventExtraKey.action.rawValue: "done"] )
        }
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - RemoteTabsPanel : LibraryPanelDelegate
extension LegacyTabTrayViewController: RemotePanelDelegate {
    func remotePanelDidRequestToSignIn() {
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
        let fxaParams = FxALaunchParams(entrypoint: .homepanel, query: [:])
        let controller = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(fxaParams,
                                                                                     flowType: .emailLoginFlow,
                                                                                     referringPage: .tabTray,
                                                                                     profile: viewModel.profile,
                                                                                     windowUUID: windowUUID)
        (controller as? FirefoxAccountSignInViewController)?.qrCodeNavigationHandler = qrCodeNavigationHandler
        (controller as? FirefoxAccountSignInViewController)?.shouldReload = { [weak self] in
            self?.viewModel.reloadRemoteTabs()
        }
        presentThemedViewController(navItemLocation: .Left,
                                    navItemText: .Close,
                                    vcBeingPresented: controller,
                                    topTabsVisible: UIDevice.current.userInterfaceIdiom == .pad)
    }
}
