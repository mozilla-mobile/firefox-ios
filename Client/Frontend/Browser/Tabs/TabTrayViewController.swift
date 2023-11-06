// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage

protocol TabTrayController: UIViewController,
                            UIAdaptivePresentationControllerDelegate,
                            UIPopoverPresentationControllerDelegate,
                            Themeable,
                            RemotePanelDelegate {
    var openInNewTab: ((_ url: URL, _ isPrivate: Bool) -> Void)? { get set }
    var didSelectUrl: ((_ url: URL, _ visitType: VisitType) -> Void)? { get set }
}

protocol TabTrayViewControllerDelegate: AnyObject {
    func didFinish()
}

class TabTrayViewController: UIViewController,
                             TabTrayController,
                             UIToolbarDelegate {
    struct UX {
        struct NavigationMenu {
            static let width: CGFloat = 343
        }

        static let fixedSpaceWidth: CGFloat = 32
    }

    // MARK: Theme
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    // MARK: Child panel and navigation
    var childPanelControllers = [UINavigationController]()
    weak var  delegate: TabTrayViewControllerDelegate?
    weak var navigationHandler: TabTrayNavigationHandler?

    var openInNewTab: ((URL, Bool) -> Void)?
    var didSelectUrl: ((URL, Storage.VisitType) -> Void)?

    // MARK: - Redux state
    var state: TabTrayState
    lazy var layout: TabTrayLayoutType = {
        return shouldUseiPadSetup() ? .regular : .compact
    }()

    // iPad Layout
    var isRegularLayout: Bool {
        return layout == .regular
    }

    var hasSyncableAccount: Bool {
        // Temporary. Added for early testing.
        // Eventually we will update this to use Redux state. -mr
        guard let profile = (UIApplication.shared.delegate as? AppDelegate)?.profile else { return false }
        return profile.hasSyncableAccount()
    }

    var currentPanel: UINavigationController? {
        guard let index = state.selectedPanel?.rawValue else { return nil }

        return childPanelControllers[index]
    }

    // MARK: - UI
    private var titleWidthConstraint: NSLayoutConstraint?
    private var containerView: UIView = .build()
    private lazy var navigationToolbar: UIToolbar = .build { [self] toolbar in
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: segmentedControl)], animated: false)
        toolbar.isTranslucent = false
    }

    private lazy var segmentedControl: UISegmentedControl = {
        return createSegmentedControl(action: #selector(segmentChanged),
                                      a11yId: AccessibilityIdentifiers.TabTray.navBarSegmentedControl)
    }()

    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButton.UX.titleFont
        label.layer.cornerRadius = TabsButton.UX.cornerRadius
        label.textAlignment = .center
        label.text = self.state.normalTabsCount
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var segmentControlItems: [Any] {
        let iPhoneItems = [
            TabTrayPanelType.tabs.image!.overlayWith(image: countLabel),
            TabTrayPanelType.privateTabs.image!,
            TabTrayPanelType.syncedTabs.image!]
        return isRegularLayout ? TabTrayPanelType.allCases.map { $0.label } : iPhoneItems
    }

    private lazy var deleteButton: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.delete,
                                action: #selector(deleteTabsButtonTapped),
                                a11yId: AccessibilityIdentifiers.TabTray.closeAllTabsButton,
                                a11yLabel: .AppMenu.Toolbar.TabTrayDeleteMenuButtonAccessibilityLabel)
    }()

    private lazy var newTabButton: UIBarButtonItem = {
        return createButtonItem(imageName: StandardImageIdentifiers.Large.plus,
                                action: #selector(newTabButtonTapped),
                                a11yId: AccessibilityIdentifiers.TabTray.newTabButton,
                                a11yLabel: .TabTrayAddTabAccessibilityLabel)
    }()

    private lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                               target: nil,
                               action: nil)
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done,
                                     target: self,
                                     action: #selector(doneButtonTapped))
        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.doneButton
        return button
    }()

    private lazy var syncTabButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .TabsTray.Sync.SyncTabs,
                                     style: .plain,
                                     target: self,
                                     action: #selector(syncTabsTapped))

        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.syncTabsButton
        return button
    }()

    private lazy var syncLoadingView: UIStackView = .build { [self] stackView in
        let syncingLabel = UILabel()
        syncingLabel.text = .SyncingMessageWithEllipsis
        syncingLabel.textColor = themeManager.currentTheme.colors.textPrimary

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = themeManager.currentTheme.colors.textPrimary
        activityIndicator.startAnimating()

        stackView.addArrangedSubview(syncingLabel)
        stackView.addArrangedSubview(activityIndicator)
        stackView.spacing = 12
    }

    private lazy var fixedSpace: UIBarButtonItem = {
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace,
                                         target: nil,
                                         action: nil)
        fixedSpace.width = CGFloat(UX.fixedSpaceWidth)
        return fixedSpace
    }()

    private lazy var bottomToolbarItems: [UIBarButtonItem] = {
        return [deleteButton, flexibleSpace, newTabButton]
    }()

    private lazy var bottomToolbarItemsForSync: [UIBarButtonItem] = {
        guard hasSyncableAccount else { return [] }

        return [flexibleSpace, syncTabButton]
    }()

    private var rightBarButtonItemsForSync: [UIBarButtonItem] {
        if hasSyncableAccount {
            return [doneButton, fixedSpace, syncTabButton]
        } else {
            return [doneButton]
        }
    }

    init(delegate: TabTrayViewControllerDelegate,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         and notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.state = TabTrayState.getMockState(isPrivateMode: false)
        self.delegate = delegate
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
        self.applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        listenForThemeChange(view)
        updateToolbarItems()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateToolbarItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            updateLayout()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didFinish()
    }

    private func updateLayout() {
        navigationController?.isToolbarHidden = isRegularLayout
        titleWidthConstraint?.isActive = isRegularLayout

        switch layout {
        case .compact:
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = [doneButton]
            navigationItem.titleView = nil
        case .regular:
            navigationItem.titleView = segmentedControl
        }
        updateToolbarItems()
    }

    // MARK: Themeable
    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
        navigationToolbar.barTintColor = themeManager.currentTheme.colors.layer1
        deleteButton.tintColor = themeManager.currentTheme.colors.iconPrimary
        newTabButton.tintColor = themeManager.currentTheme.colors.iconPrimary
        doneButton.tintColor = themeManager.currentTheme.colors.iconPrimary
        syncTabButton.tintColor = themeManager.currentTheme.colors.iconPrimary
    }

    // MARK: Private
    private func setupView() {
        // Should use Regular layout used for iPad
        guard isRegularLayout else {
            setupForiPhone()
            return
        }
        setupForiPad()
    }

    private func setupForiPhone() {
        navigationItem.titleView = nil
        updateTitle()
        view.addSubview(navigationToolbar)
        view.addSubviews(containerView)
        navigationToolbar.setItems([UIBarButtonItem(customView: segmentedControl)], animated: false)

        NSLayoutConstraint.activate([
            navigationToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // TODO: FXIOS-6926 Remove priority once collection view layout is configured
            navigationToolbar.bottomAnchor.constraint(equalTo: containerView.topAnchor).priority(.defaultLow),

            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func updateTitle() {
        guard let panel = state.selectedPanel else { return }

        navigationItem.title = panel.navTitle
    }

    private func setupForiPad() {
        navigationItem.titleView = segmentedControl
        view.addSubviews(containerView)

        if let titleView = navigationItem.titleView {
            titleWidthConstraint = titleView.widthAnchor.constraint(equalToConstant: UX.NavigationMenu.width)
            titleWidthConstraint?.isActive = true
        }

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func updateToolbarItems() {
        // iPad configuration
        guard !isRegularLayout else {
            setupToolbarForIpad()
            return
        }

        let toolbarItems = state.isSyncTabsPanel ? bottomToolbarItemsForSync : bottomToolbarItems
        setToolbarItems(toolbarItems, animated: true)
    }

    private func setupToolbarForIpad() {
        if state.isSyncTabsPanel {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = rightBarButtonItemsForSync
        } else {
            navigationItem.leftBarButtonItem = deleteButton
            navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButton]
        }

        navigationController?.isToolbarHidden = true
        let toolbarItems = state.isSyncTabsPanel ? bottomToolbarItemsForSync : bottomToolbarItems
        setToolbarItems(toolbarItems, animated: true)
    }

    private func createSegmentedControl(
        action: Selector,
        a11yId: String
    ) -> UISegmentedControl {
        let segmentedControl = UISegmentedControl(items: segmentControlItems)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = true
        segmentedControl.accessibilityIdentifier = a11yId

        let segmentToFocus = TabTrayPanelType.tabs
        segmentedControl.selectedSegmentIndex = segmentToFocus.rawValue
        segmentedControl.addTarget(self, action: action, for: .valueChanged)
        return segmentedControl
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

    // MARK: Child panels
    func setupOpenPanel(panelType: TabTrayPanelType) {
        // TODO: Move to Reducer
        state.selectedPanel = panelType

        guard let currentPanel = currentPanel else { return }

        updateTitle()
        updateLayout()
        hideCurrentPanel()
        showPanel(currentPanel)
        navigationHandler?.start(panelType: panelType, navigationController: currentPanel)
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
            panel.view.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
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

    @objc
    private func segmentChanged() {
        guard let panelType = TabTrayPanelType(rawValue: segmentedControl.selectedSegmentIndex),
              state.selectedPanel != panelType else { return }

        setupOpenPanel(panelType: panelType)
    }

    @objc
    private func deleteTabsButtonTapped() {}

    @objc
    private func newTabButtonTapped() {}

    @objc
    private func doneButtonTapped() {
        notificationCenter.post(name: .TabsTrayDidClose)
        // TODO: FXIOS-6928 Update mode when closing tabTray
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func syncTabsTapped() {}

    // MARK: - RemotePanelDelegate

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
        // TODO: [FXIOS-6928] Provide handler for didSelectURL.
        self.didSelectUrl?(url, visitType)
        self.dismissVC()
    }

    // Sign In and Create Account Helper
    func fxaSignInOrCreateAccountHelper() {
        // TODO: Present Firefox account sign-in. Forthcoming.
    }
}
