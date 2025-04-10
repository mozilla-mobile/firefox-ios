// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared

import enum MozillaAppServices.VisitType

protocol TabTrayController: UIViewController,
                            UIAdaptivePresentationControllerDelegate,
                            UIPopoverPresentationControllerDelegate,
                            Themeable {
    var openInNewTab: ((_ url: URL, _ isPrivate: Bool) -> Void)? { get set }
    var didSelectUrl: ((_ url: URL, _ visitType: VisitType) -> Void)? { get set }
}

protocol TabTrayViewControllerDelegate: AnyObject {
    func didFinish()
}

class TabTrayViewController: UIViewController,
                             TabTrayController,
                             UIToolbarDelegate,
                             StoreSubscriber,
                             FeatureFlaggable,
                             TabTraySelectorDelegate {
    typealias SubscriberStateType = TabTrayState
    struct UX {
        struct NavigationMenu {
            static let width: CGFloat = 343
        }

        struct Toast {
            static let undoDelay = DispatchTimeInterval.seconds(0)
            static let undoDuration = DispatchTimeInterval.seconds(3)
        }
        static let fixedSpaceWidth: CGFloat = 32
        static let segmentedControlTopSpacing: CGFloat = 8
        static let segmentedControlHorizontalSpacing: CGFloat = 16
        static let segmentedControlMinHeight: CGFloat = 45
    }

    // MARK: Theme
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    // MARK: Child panel and navigation
    var childPanelControllers = [UINavigationController]()
    weak var delegate: TabTrayViewControllerDelegate?
    weak var navigationHandler: TabTrayNavigationHandler?

    var openInNewTab: ((URL, Bool) -> Void)?
    var didSelectUrl: ((URL, VisitType) -> Void)?

    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
    }

    // MARK: - Redux state
    var tabTrayState: TabTrayState
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
        guard !childPanelControllers.isEmpty else { return nil }
        let index = tabTrayState.selectedPanel.rawValue
        return childPanelControllers[index]
    }

    var toolbarHeight: CGFloat {
        return !shouldUseiPadSetup() ? view.safeAreaInsets.bottom : 0
    }

    var shownToast: Toast?
    var logger: Logger

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

    private lazy var experimentSegmentControl: TabTraySelectorView = {
        // Temporary offset of numbers to account for the different order in the experiment
        // Order can be updated in TabTrayPanelType once the experiment is done
        var selectedIndex = 0
        switch tabTrayState.selectedPanel {
        case .privateTabs:
            selectedIndex = 0
        case .tabs:
            selectedIndex = 1
        case .syncedTabs:
            selectedIndex = 2
        }

        let selector = TabTraySelectorView(selectedIndex: selectedIndex, windowUUID: windowUUID)
        selector.delegate = self
        selector.items = [TabTrayPanelType.privateTabs.label,
                          TabTrayPanelType.tabs.label,
                          TabTrayPanelType.syncedTabs.label]

        didSelectSection(panelType: tabTrayState.selectedPanel)
        return selector
    }()

    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButton.UX.titleFont
        label.layer.cornerRadius = TabsButton.UX.cornerRadius
        label.textAlignment = .center
        label.text = "0"
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
                                a11yLabel: .LegacyAppMenu.Toolbar.TabTrayDeleteMenuButtonAccessibilityLabel)
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
        syncingLabel.textColor = themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary
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

    private lazy var experimentBottomToolbarItems: [UIBarButtonItem] = {
        return [deleteButton, flexibleSpace, newTabButton, flexibleSpace, doneButton]
    }()

    private lazy var bottomToolbarItemsForSync: [UIBarButtonItem] = {
        guard hasSyncableAccount else { return [] }

        return [flexibleSpace, syncTabButton]
    }()

    private lazy var experimentBottomToolbarItemsForSync: [UIBarButtonItem] = {
        guard hasSyncableAccount else { return [flexibleSpace, doneButton] }

        return [syncTabButton, flexibleSpace, doneButton]
    }()

    private var rightBarButtonItemsForSync: [UIBarButtonItem] {
        if hasSyncableAccount {
            return [doneButton, fixedSpace, syncTabButton]
        } else {
            return [doneButton]
        }
    }

    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    init(panelType: TabTrayPanelType,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.tabTrayState = TabTrayState(windowUUID: windowUUID, panelType: panelType)
        self.themeManager = themeManager
        self.logger = logger
        self.notificationCenter = notificationCenter
        self.windowUUID = windowUUID

        super.init(nibName: nil, bundle: nil)
        self.applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        subscribeToRedux()
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

        unsubscribeFromRedux()
    }

    private func updateLayout() {
        navigationController?.isToolbarHidden = isRegularLayout
        titleWidthConstraint?.isActive = isRegularLayout

        switch layout {
        case .compact:
            navigationItem.leftBarButtonItem = nil
            navigationItem.titleView = nil
            if isTabTrayUIExperimentsEnabled {
                navigationController?.setNavigationBarHidden(true, animated: false)
                navigationItem.rightBarButtonItems = nil
            } else {
                navigationItem.rightBarButtonItems = [doneButton]
            }
        case .regular:
            navigationItem.titleView = segmentedControl
        }
        updateToolbarItems()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        let initialSelectedPanel = tabTrayState.selectedPanel
        let screenAction = ScreenAction(windowUUID: windowUUID,
                                        actionType: ScreenActionType.showScreen,
                                        screen: .tabsTray)
        store.dispatch(screenAction)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return TabTrayState(appState: appState, uuid: uuid)
            })
        })
        let action = TabTrayAction(
            panelType: initialSelectedPanel,
            windowUUID: windowUUID,
            actionType: TabTrayActionType.tabTrayDidLoad)
        store.dispatch(action)
    }

    func unsubscribeFromRedux() {
        let screenAction = ScreenAction(windowUUID: windowUUID,
                                        actionType: ScreenActionType.closeScreen,
                                        screen: .tabsTray)
        store.dispatch(screenAction)
    }

    func newState(state: TabTrayState) {
        guard state != tabTrayState else { return }

        tabTrayState = state

        updateTabCountImage(count: tabTrayState.normalTabsCount)
        segmentedControl.selectedSegmentIndex = tabTrayState.selectedPanel.rawValue
        if tabTrayState.shouldDismiss {
            delegate?.didFinish()
        }

        if tabTrayState.showCloseConfirmation {
            showCloseAllConfirmation()
            tabTrayState.showCloseConfirmation = false
        }

        if let toastType = tabTrayState.toastType {
            presentToast(toastType: toastType) { [weak self] undoClose in
                guard let self else { return }

                // Undo the action described by the toast
                if let action = toastType.reduxAction(for: self.windowUUID), undoClose {
                    store.dispatch(action)
                }
                self.shownToast = nil
            }
        }
    }

    func updateTabCountImage(count: String) {
        countLabel.text = count
        segmentedControl.setImage(TabTrayPanelType.tabs.image!.overlayWith(image: countLabel),
                                  forSegmentAt: 0)
    }

    // MARK: Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        navigationToolbar.barTintColor = theme.colors.layer1
        deleteButton.tintColor = theme.colors.iconPrimary
        newTabButton.tintColor = theme.colors.iconPrimary
        doneButton.tintColor = theme.colors.iconPrimary
        syncTabButton.tintColor = theme.colors.iconPrimary
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
        view.addSubviews(containerView)
        if isTabTrayUIExperimentsEnabled {
            containerView.addSubview(segmentedControl)
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            // Out of simplicity for the experiment, turn off a11y for the old segmented control
            segmentedControl.isAccessibilityElement = false
            segmentedControl.isHidden = true

            containerView.addSubview(experimentSegmentControl)
            experimentSegmentControl.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: view.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

                segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                          constant: UX.segmentedControlHorizontalSpacing),
                segmentedControl.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
                segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                           constant: -UX.segmentedControlHorizontalSpacing),

                experimentSegmentControl.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
                experimentSegmentControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                                  constant: UX.segmentedControlHorizontalSpacing),
                experimentSegmentControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                                   constant: -UX.segmentedControlHorizontalSpacing),
                experimentSegmentControl.heightAnchor.constraint(equalToConstant: UX.segmentedControlMinHeight)
            ])
        } else {
            view.addSubview(navigationToolbar)
            navigationToolbar.setItems([UIBarButtonItem(customView: segmentedControl)], animated: false)

            NSLayoutConstraint.activate([
                navigationToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                navigationToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigationToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                navigationToolbar.bottomAnchor.constraint(equalTo: containerView.topAnchor).priority(.defaultLow),

                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
    }

    private func updateTitle() {
        if !isTabTrayUIExperimentsEnabled, !self.isRegularLayout {
            navigationItem.title = tabTrayState.navigationTitle
        }
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

        let isSyncTabsPanel = tabTrayState.isSyncTabsPanel
        var toolbarItems: [UIBarButtonItem]
        if isTabTrayUIExperimentsEnabled {
            toolbarItems = isSyncTabsPanel ? experimentBottomToolbarItemsForSync : experimentBottomToolbarItems
        } else {
            toolbarItems = isSyncTabsPanel ? bottomToolbarItemsForSync : bottomToolbarItems
        }

        setToolbarItems(toolbarItems, animated: true)
    }

    private func setupToolbarForIpad() {
        if tabTrayState.isSyncTabsPanel {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = rightBarButtonItemsForSync
        } else {
            navigationItem.leftBarButtonItem = deleteButton
            navigationItem.rightBarButtonItems = [doneButton, fixedSpace, newTabButton]
        }

        navigationController?.isToolbarHidden = true
        let toolbarItems = tabTrayState.isSyncTabsPanel ? bottomToolbarItemsForSync : bottomToolbarItems
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

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    private func presentToast(toastType: ToastType, completion: @escaping (Bool) -> Void) {
        if let currentToast = shownToast {
            currentToast.dismiss(false)
        }

        if toastType.reduxAction(for: windowUUID) != nil {
            let viewModel = ButtonToastViewModel(labelText: toastType.title, buttonText: toastType.buttonText)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: currentTheme(),
                                    completion: { buttonPressed in
                                        completion(buttonPressed)
            })
            toast.showToast(viewController: self,
                            delay: UX.Toast.undoDelay,
                            duration: UX.Toast.undoDuration) { toast in
                if self.isTabTrayUIExperimentsEnabled, !self.isRegularLayout {
                    [
                        toast.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                                                       constant: Toast.UX.toastSidePadding),
                        toast.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                                                        constant: -Toast.UX.toastSidePadding),
                        toast.bottomAnchor.constraint(equalTo: self.segmentedControl.topAnchor,
                                                      constant: -UX.segmentedControlTopSpacing)
                    ]
                } else {
                    [
                        toast.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                                                       constant: Toast.UX.toastSidePadding),
                        toast.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                                                        constant: -Toast.UX.toastSidePadding),
                        toast.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
                    ]
                }
            }
            shownToast = toast
        } else {
            let toast = SimpleToast()
            toast.showAlertWithText(toastType.title,
                                    bottomContainer: view,
                                    theme: currentTheme(),
                                    bottomConstraintPadding: -toolbarHeight)
        }
    }

    // MARK: Child panels
    func setupOpenPanel(panelType: TabTrayPanelType) {
        tabTrayState.selectedPanel = panelType

        guard let currentPanel = currentPanel else { return }

        segmentedControl.selectedSegmentIndex = panelType.rawValue
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

        if isTabTrayUIExperimentsEnabled, !isRegularLayout {
            NSLayoutConstraint.activate([
                panel.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                panel.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                panel.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                panel.view.bottomAnchor.constraint(equalTo: experimentSegmentControl.topAnchor,
                                                   constant: -UX.segmentedControlTopSpacing),
            ])
        } else {
            NSLayoutConstraint.activate([
                panel.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                panel.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                panel.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                panel.view.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            ])
        }

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
              tabTrayState.selectedPanel != panelType else { return }

        setupOpenPanel(panelType: panelType)

        let action = TabTrayAction(panelType: panelType,
                                   windowUUID: windowUUID,
                                   actionType: TabTrayActionType.changePanel)
        store.dispatch(action)
    }

    @objc
    private func deleteTabsButtonTapped() {
        let action = TabPanelViewAction(panelType: tabTrayState.selectedPanel,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.closeAllTabs)
        store.dispatch(action)
    }

    private func showCloseAllConfirmation() {
        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: .LegacyAppMenu.AppMenuCloseAllTabsTitleString,
                                           style: .default,
                                           handler: { _ in self.confirmCloseAll() }),
                             accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCloseAllButton)
        controller.addAction(UIAlertAction(title: .TabTrayCloseAllTabsPromptCancel,
                                           style: .cancel,
                                           handler: nil),
                             accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCancelButton)
        controller.popoverPresentationController?.barButtonItem = deleteButton
        present(controller, animated: true, completion: nil)
    }

    private func confirmCloseAll() {
        let action = TabPanelViewAction(panelType: tabTrayState.selectedPanel,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.confirmCloseAllTabs)
        store.dispatch(action)
    }

    @objc
    private func newTabButtonTapped() {
        let action = TabPanelViewAction(panelType: tabTrayState.selectedPanel,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.addNewTab)
        store.dispatch(action)
    }

    @objc
    private func doneButtonTapped() {
        notificationCenter.post(name: .TabsTrayDidClose, withUserInfo: windowUUID.userInfo)
        store.dispatch(
            TabTrayAction(
                windowUUID: windowUUID,
                actionType: TabTrayActionType.doneButtonTapped
            )
        )
        delegate?.didFinish()
    }

    @objc
    private func syncTabsTapped() {
        let action = RemoteTabsPanelAction(windowUUID: windowUUID,
                                           actionType: RemoteTabsPanelActionType.refreshTabs)
        store.dispatch(action)
    }

    // MARK: - TabTraySelectorDelegate

    func didSelectSection(panelType: TabTrayPanelType) {
        guard tabTrayState.selectedPanel != panelType else { return }

        setupOpenPanel(panelType: panelType)

        let action = TabTrayAction(panelType: panelType,
                                   windowUUID: windowUUID,
                                   actionType: TabTrayActionType.changePanel)
        store.dispatch(action)
    }
}
