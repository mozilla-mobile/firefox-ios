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
    @MainActor
    var openInNewTab: ((_ url: URL, _ isPrivate: Bool) -> Void)? { get set }
    @MainActor
    var didSelectUrl: ((_ url: URL, _ visitType: VisitType) -> Void)? { get set }
}

protocol TabTrayViewControllerDelegate: AnyObject {
    @MainActor
    func didFinish()
}

final class TabTrayViewController: UIViewController,
                                   TabTrayController,
                                   UIToolbarDelegate,
                                   UIPageViewControllerDataSource,
                                   UIPageViewControllerDelegate,
                                   UIScrollViewDelegate,
                                   StoreSubscriber,
                                   FeatureFlaggable,
                                   TabTraySelectorDelegate,
                                   TabTrayAnimationDelegate,
                                   TabDisplayViewDragAndDropInteraction,
                                   Notifiable {
    typealias SubscriberStateType = TabTrayState
    private struct UX {
        struct NavigationMenu {
            static let width: CGFloat = 343
        }

        struct Toast {
            static let undoDelay = DispatchTimeInterval.seconds(0)
            static let undoDuration = DispatchTimeInterval.seconds(3)
        }
        static let fixedSpaceWidth: CGFloat = 32
        static let segmentedControlHorizontalSpacing: CGFloat = 16
        static let titleFont: UIFont = FXFontStyles.Bold.caption2.systemFont()
        static let cornerRadius: CGFloat = 2
    }

    // MARK: Theme
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    // MARK: Child panel and navigation
    var childPanelControllers = [UINavigationController]() {
        didSet {
            setupSlidingPanel()
        }
    }
    var childPanelThemes: [Theme]?
    weak var delegate: TabTrayViewControllerDelegate?
    weak var navigationHandler: TabTrayNavigationHandler?
    private var tabTrayUtils: TabTrayUtils

    private lazy var panelContainer: UIView = .build { _ in }
    private var pageViewController: UIPageViewController?
    private weak var pageScrollView: UIScrollView?
    private var swipeFromIndex: Int?
    private lazy var themeAnimator = TabTrayThemeAnimator()

    private let blurView: UIVisualEffectView = .build { view in
        view.effect = UIBlurEffect(style: .systemUltraThinMaterial)
    }

    var openInNewTab: ((URL, Bool) -> Void)?
    var didSelectUrl: ((URL, VisitType) -> Void)?

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

    var currentExperimentPanel: UINavigationController? {
        guard !childPanelControllers.isEmpty else { return nil }
        let index = experimentConvertSelectedIndex()
        return childPanelControllers[index]
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
        let selectedIndex = experimentConvertSelectedIndex()
        let titles = [TabTrayPanelType.privateTabs.label,
                     TabTrayPanelType.tabs.label,
                     TabTrayPanelType.syncedTabs.label]
        let selector = TabTraySelectorView(selectedIndex: selectedIndex,
                                           theme: retrieveTheme(),
                                           buttonTitles: titles)
        selector.delegate = self
        selector.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.navBarSegmentedControl

        didSelectSection(panelType: tabTrayState.selectedPanel)
        return selector
    }()

    private func experimentConvertSelectedIndex() -> Int {
        // Temporary offset of numbers to account for the different order in the experiment - tabTrayUIExperiments
        // Order can be updated in TabTrayPanelType once the experiment is done
        return TabTrayPanelType.getExperimentConvert(index: tabTrayState.selectedPanel.rawValue).rawValue
    }

    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = UX.titleFont
        label.layer.cornerRadius = UX.cornerRadius
        label.textAlignment = .center
        label.text = "0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var segmentControlItems: [Any] {
        let iPhoneItems = [
            TabTrayPanelType.tabs.image!.overlayWith(image: countLabel),
            TabTrayPanelType.privateTabs.image!,
            TabTrayPanelType.syncedTabs.image!
        ]

        let regularLayoutItems = [
            TabTrayPanelType.tabs.label,
            TabTrayPanelType.privateTabs.label,
            TabTrayPanelType.syncedTabs.label,
        ]

        return isRegularLayout ? regularLayoutItems : iPhoneItems
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
                                a11yLabel: .TabsTray.TabTrayAddTabAccessibilityLabel)
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
        syncingLabel.textColor = retrieveTheme().colors.textPrimary

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = retrieveTheme().colors.textPrimary
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

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    init(panelType: TabTrayPanelType,
         tabTrayUtils: TabTrayUtils = DefaultTabTrayUtils(),
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.tabTrayState = TabTrayState(windowUUID: windowUUID, panelType: panelType)
        self.tabTrayUtils = tabTrayUtils
        self.themeManager = themeManager
        self.logger = logger
        self.notificationCenter = notificationCenter
        self.windowUUID = windowUUID

        super.init(nibName: nil, bundle: nil)
        themeAnimator.delegate = self
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        subscribeToRedux()
        updateToolbarItems()

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIAccessibility.reduceTransparencyStatusDidChangeNotification]
        )

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
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
            if tabTrayUtils.shouldDisplayExperimentUI() {
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
        if state.normalTabsCount != tabTrayState.normalTabsCount {
            updateTabCountImage(count: state.normalTabsCount)
        }
        tabTrayState = state

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
                if let action = (toastType.reduxAction(for: self.windowUUID) as? TabPanelViewAction), undoClose {
                    store.dispatch(action)
                }
                self.shownToast = nil
            }
        }

        if let enableDeleteTabsButton = tabTrayState.enableDeleteTabsButton {
            deleteButton.isEnabled = enableDeleteTabsButton
        }

        // Only apply normal theme when there's no on going animations
        if !themeAnimator.isAnimating && swipeFromIndex == nil {
            applyTheme()
        }
    }

    func updateTabCountImage(count: String) {
        countLabel.text = count
        segmentedControl.setImage(TabTrayPanelType.tabs.image!.overlayWith(image: countLabel),
                                  forSegmentAt: 0)
    }

    // MARK: Themeable
    var shouldUsePrivateOverride: Bool {
        return featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly)
    }

    var shouldBeInPrivateTheme: Bool {
        let tabTrayState = store.state.screenState(TabTrayState.self, for: .tabsTray, window: windowUUID)
        return tabTrayState?.isPrivateMode ?? false
    }

    func applyTheme() {
        childPanelThemes = childPanelControllers.compactMap { panel in
            (panel.topViewController as? TabTrayThemeable)?.retrieveTheme()
        }

        let theme = retrieveTheme()
        view.backgroundColor = theme.colors.layer1
        navigationToolbar.barTintColor = theme.colors.layer1
        deleteButton.tintColor = theme.colors.iconPrimary
        newTabButton.tintColor = theme.colors.iconPrimary
        doneButton.tintColor = theme.colors.iconPrimary
        syncTabButton.tintColor = theme.colors.iconPrimary
        panelContainer.backgroundColor = theme.colors.layer3

        if shouldUsePrivateOverride {
            experimentSegmentControl.applyTheme(theme: theme)

            let userInterfaceStyle = tabTrayState.isPrivateMode ? .dark : theme.type.getInterfaceStyle()
            navigationController?.overrideUserInterfaceStyle = userInterfaceStyle
        }

        setupToolBarAppearance(theme: theme)
        setupNavigationBarAppearance(theme: theme)
    }

    func applyTheme(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        guard let fromTheme = childPanelThemes?[safe: fromIndex],
              let toTheme = childPanelThemes?[safe: toIndex] else { return }

        let swipeTheme = TabTrayPanelSwipeTheme(from: fromTheme, to: toTheme, progress: progress)
        childPanelControllers.forEach({ ($0.topViewController as? TabTrayThemeable)?.applyTheme(swipeTheme) })

        view.backgroundColor = swipeTheme.colors.layer1
        navigationToolbar.barTintColor = swipeTheme.colors.layer1
        deleteButton.tintColor = swipeTheme.colors.iconPrimary
        newTabButton.tintColor = swipeTheme.colors.iconPrimary
        doneButton.tintColor = swipeTheme.colors.iconPrimary
        syncTabButton.tintColor = swipeTheme.colors.iconPrimary
        panelContainer.backgroundColor = swipeTheme.colors.layer3

        experimentSegmentControl.applyTheme(theme: swipeTheme)
        setupToolBarAppearance(theme: swipeTheme)
        setupNavigationBarAppearance(theme: swipeTheme)
    }

    private func setupToolBarAppearance(theme: Theme) {
        guard tabTrayUtils.isTabTrayUIExperimentsEnabled else { return }

        if #available(iOS 26, *) { return }

        let backgroundAlpha = tabTrayUtils.backgroundAlpha()
        let color = theme.colors.layer1.withAlphaComponent(backgroundAlpha)

        let standardAppearance = UIToolbarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = color
        standardAppearance.backgroundEffect = nil
        standardAppearance.shadowColor = .clear
        navigationController?.toolbar.standardAppearance = standardAppearance
        navigationController?.toolbar.compactAppearance = standardAppearance
        navigationController?.toolbar.scrollEdgeAppearance = standardAppearance
        navigationController?.toolbar.compactScrollEdgeAppearance = standardAppearance
        navigationController?.toolbar.tintColor = theme.colors.actionPrimary
    }

    private func setupNavigationBarAppearance(theme: Theme) {
        guard tabTrayUtils.isTabTrayUIExperimentsEnabled else { return }

        let backgroundAlpha = tabTrayUtils.backgroundAlpha()
        let color = theme.colors.layer1.withAlphaComponent(backgroundAlpha)

        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.titleTextAttributes = [.foregroundColor: theme.colors.textPrimary]
        standardAppearance.backgroundColor = color
        standardAppearance.backgroundEffect = nil
        standardAppearance.shadowColor = .clear

        navigationController?.navigationBar.standardAppearance = standardAppearance
        navigationController?.navigationBar.compactAppearance = standardAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = standardAppearance
        navigationController?.navigationBar.compactScrollEdgeAppearance = standardAppearance
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
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
        if tabTrayUtils.shouldDisplayExperimentUI() {
            containerView.addSubview(panelContainer)
            containerView.addSubview(segmentedControl)
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            // Out of simplicity for the experiment, turn off a11y for the old segmented control
            segmentedControl.isAccessibilityElement = false
            segmentedControl.isHidden = true

            containerView.addSubview(experimentSegmentControl)
            experimentSegmentControl.translatesAutoresizingMaskIntoConstraints = false

            let segmentControlHeight = tabTrayUtils.segmentedControlHeight

            NSLayoutConstraint.activate([
                panelContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
                panelContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                panelContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                panelContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

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
                experimentSegmentControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                experimentSegmentControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                experimentSegmentControl.heightAnchor.constraint(equalToConstant: segmentControlHeight)
            ])

            setupBlurView()
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

    private func setupBlurView() {
        guard tabTrayUtils.isTabTrayUIExperimentsEnabled, tabTrayUtils.isTabTrayTranslucencyEnabled else { return }

        if #available(iOS 26, *) { return }

        // Should use Regular layout used for iPad
        if isRegularLayout {
            containerView.insertSubview(blurView, aboveSubview: containerView)

            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: view.topAnchor),
                blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            ])
        } else {
            containerView.insertSubview(blurView, belowSubview: experimentSegmentControl)

            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: experimentSegmentControl.topAnchor),
                blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }

        updateBlurView()
    }

    private func updateBlurView() {
        applyTheme()

        if #available(iOS 26, *) { return }
        blurView.isHidden = !tabTrayUtils.shouldBlur()
    }

    private func updateTitle() {
        if !tabTrayUtils.shouldDisplayExperimentUI(), !self.isRegularLayout {
            navigationItem.title = tabTrayState.navigationTitle
        }
    }

    private func setupForiPad() {
        navigationItem.titleView = segmentedControl
        view.addSubviews(containerView)
        setupBlurView()

        if let titleView = navigationItem.titleView {
            titleWidthConstraint = titleView.widthAnchor.constraint(equalToConstant: UX.NavigationMenu.width)
            titleWidthConstraint?.isActive = true
        }

        let isTabTrayEnabled = tabTrayUtils.isTabTrayUIExperimentsEnabled && tabTrayUtils.isTabTrayTranslucencyEnabled
        let topConstraintTo = isTabTrayEnabled ? view.topAnchor : view.safeAreaLayoutGuide.topAnchor

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topConstraintTo),
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
        if tabTrayUtils.shouldDisplayExperimentUI() {
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

    internal func retrieveTheme() -> Theme {
        if shouldUsePrivateOverride {
            return themeManager.resolvedTheme(with: tabTrayState.isPrivateMode)
        } else {
            return themeManager.getCurrentTheme(for: windowUUID)
        }
    }

    private func presentToast(toastType: ToastType, completion: @escaping @MainActor (Bool) -> Void) {
        if let currentToast = shownToast {
            currentToast.dismiss(false)
        }

        if toastType.reduxAction(for: windowUUID) is TabPanelViewAction {
            let viewModel = ButtonToastViewModel(labelText: toastType.title, buttonText: toastType.buttonText)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: retrieveTheme(),
                                    completion: { buttonPressed in
                                        completion(buttonPressed)
            })
            toast.showToast(viewController: self,
                            delay: UX.Toast.undoDelay,
                            duration: UX.Toast.undoDuration) { toast in
                if self.tabTrayUtils.shouldDisplayExperimentUI(), !self.isRegularLayout {
                    [
                        toast.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                                                       constant: Toast.UX.toastSidePadding),
                        toast.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                                                        constant: -Toast.UX.toastSidePadding),
                        toast.bottomAnchor.constraint(equalTo: self.segmentedControl.topAnchor)
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
                                    theme: retrieveTheme())
        }
    }

    // MARK: Child panels
    func setupOpenPanel(panelType: TabTrayPanelType) {
        tabTrayState.selectedPanel = panelType

        guard let currentPanel = currentPanel else { return }

        segmentedControl.selectedSegmentIndex = panelType.rawValue
        updateTitle()
        updateLayout()

        if !tabTrayUtils.shouldDisplayExperimentUI() {
            hideCurrentPanel()
            showPanel(currentPanel)
            navigationHandler?.start(panelType: panelType, navigationController: currentPanel)
        } else if let pageVC = pageViewController,
                  pageVC.viewControllers?.isEmpty ?? true {
            let initialIndex = TabTrayPanelType.getExperimentConvert(index: panelType.rawValue).rawValue
            if let initialVC = childPanelControllers[safe: initialIndex] {
                pageVC.setViewControllers([initialVC], direction: .forward, animated: false, completion: nil)

                let panelType = tabTrayState.selectedPanel
                navigationHandler?.start(panelType: panelType, navigationController: initialVC)
            }
        } else {
            navigationHandler?.start(panelType: panelType, navigationController: currentPanel)
        }
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

    func setupSlidingPanel() {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageVC.dataSource = self
        pageVC.delegate = self

        addChild(pageVC)
        panelContainer.addSubview(pageVC.view)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageVC.view.leadingAnchor.constraint(equalTo: panelContainer.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: panelContainer.trailingAnchor),
            pageVC.view.topAnchor.constraint(equalTo: panelContainer.topAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: panelContainer.bottomAnchor)
        ])
        pageVC.didMove(toParent: self)

        if let scrollView = pageVC.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.delegate = self
            scrollView.isScrollEnabled = false
        }

        self.pageViewController = pageVC
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
        let alert = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // We only show the potion to delete old tabs with normal tabs tray
        if tabTrayState.isNormalTabsPanel {
            alert.addAction(UIAlertAction(title: .TabsTray.TabTrayCloseOldTabsTitle,
                                          style: .default,
                                          handler: { _ in
                // Delay to allow current sheet to dismiss
                DispatchQueue.main.async {
                    self.showTabsDeletionPicker()
                }
            }), accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteOlderTabsButton
            )
        }

        let tabsCountString = tabTrayState.isNormalTabsPanel ? tabTrayState.normalTabsCount : tabTrayState.privateTabsCount
        alert.addAction(UIAlertAction(title: String(format: .TabsTray.TabTrayCloseTabsTitle, tabsCountString),
                                      style: .destructive,
                                      handler: { _ in
            self.confirmCloseAll()
        }), accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCloseAllButton
        )

        alert.addAction(
            UIAlertAction(
                title: .TabsTray.TabTrayCloseAllTabsPromptCancel,
                style: .cancel,
                handler: { _ in self.cancelCloseAll() }
            ),
            accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCancelButton
        )
        alert.popoverPresentationController?.barButtonItem = deleteButton
        present(alert, animated: true, completion: nil)
    }

    private func showTabsDeletionPicker() {
        let telemetry = TabsPanelTelemetry()
        telemetry.closeAllTabsSheetOptionSelected(option: .old, mode: .normal)

        let alert = AlertController(title: .TabsTray.TabTrayCloseTabsOlderThanTitle,
                                    message: nil,
                                    preferredStyle: .actionSheet)

        struct TabDeletionData {
            let period: TabsDeletionPeriod
            let title: String
            let accessibilityID: String
        }

        let options = [
            TabDeletionData(period: .oneDay,
                            title: .TabsTray.TabTrayOneDayAgoTitle,
                            accessibilityID: AccessibilityIdentifiers.TabTray.deleteTabsOlderThan1DayButton),
            TabDeletionData(period: .oneWeek,
                            title: .TabsTray.TabTrayOneWeekAgoTitle,
                            accessibilityID: AccessibilityIdentifiers.TabTray.deleteTabsOlderThan1WeekButton),
            TabDeletionData(period: .oneMonth,
                            title: .TabsTray.TabTrayOneMonthAgoTitle,
                            accessibilityID: AccessibilityIdentifiers.TabTray.deleteTabsOlderThan1MonthButton)
        ]

        for option in options {
            let action = UIAlertAction(title: option.title, style: .default) { _ in
                self.deleteTabsOlderThan(period: option.period)
            }
            alert.addAction(action, accessibilityIdentifier: option.accessibilityID)
        }

        alert.addAction(
            UIAlertAction(
                title: .TabsTray.TabTrayCloseAllTabsPromptCancel,
                style: .cancel,
                handler: { _ in self.cancelCloseAll() }
            ),
            accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCancelButton
        )

        alert.popoverPresentationController?.barButtonItem = deleteButton
        present(alert, animated: true, completion: nil)
    }

    private func cancelCloseAll() {
        let action = TabPanelViewAction(panelType: tabTrayState.selectedPanel,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.cancelCloseAllTabs)
        store.dispatch(action)
    }

    private func confirmCloseAll() {
        let action = TabPanelViewAction(panelType: tabTrayState.selectedPanel,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.confirmCloseAllTabs)
        store.dispatch(action)
    }

    private func deleteTabsOlderThan(period: TabsDeletionPeriod) {
        let action = TabPanelViewAction(panelType: tabTrayState.selectedPanel,
                                        deleteTabPeriod: period,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.deleteTabsOlderThan)
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
                panelType: tabTrayState.selectedPanel,
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

        if tabTrayUtils.shouldDisplayExperimentUI() {
            let targetIndex = TabTrayPanelType.getExperimentConvert(index: panelType.rawValue).rawValue
            guard let targetVC = childPanelControllers[safe: targetIndex],
                  let currentVC = pageViewController?.viewControllers?.first as? UINavigationController,
                  let currentIndex = childPanelControllers.firstIndex(of: currentVC)
            else { return }

            let reduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            if !reduceMotionEnabled {
                themeAnimator.animateThemeTransition(fromIndex: currentIndex, toIndex: targetIndex)
            }

            let direction: UIPageViewController.NavigationDirection = targetIndex > currentIndex ? .forward : .reverse
            pageViewController?.setViewControllers([targetVC],
                                                   direction: direction,
                                                   animated: !reduceMotionEnabled,
                                                   completion: nil)
        }

        setupOpenPanel(panelType: panelType)
        let action = TabTrayAction(panelType: panelType,
                                   windowUUID: windowUUID,
                                   actionType: TabTrayActionType.changePanel)
        store.dispatch(action)
    }

    // MARK: - UIPageViewControllerDataSource & UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? UINavigationController,
              let index = childPanelControllers.firstIndex(of: viewController),
              index > 0 else { return nil }
        return childPanelControllers[safe: index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? UINavigationController,
              let index = childPanelControllers.firstIndex(of: viewController),
              index < childPanelControllers.count - 1 else { return nil }
        return childPanelControllers[safe: index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? UINavigationController,
              let currentIndex = childPanelControllers.firstIndex(of: currentVC) else { return }

        let newPanelType = TabTrayPanelType.getExperimentConvert(index: currentIndex)
        if tabTrayState.selectedPanel != newPanelType {
            tabTrayState.selectedPanel = newPanelType
            let action = TabTrayAction(panelType: newPanelType,
                                       windowUUID: windowUUID,
                                       actionType: TabTrayActionType.changePanel)
            store.dispatch(action)

            experimentSegmentControl.didFinishSelection(to: experimentConvertSelectedIndex())

            navigationHandler?.start(panelType: newPanelType, navigationController: currentVC)
            swipeFromIndex = nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let fromVC = pageViewController.viewControllers?.first as? UINavigationController,
              let index = childPanelControllers.firstIndex(of: fromVC) else { return }

        swipeFromIndex = index
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard tabTrayUtils.shouldDisplayExperimentUI(),
              let fromIndex = swipeFromIndex,
              let width = scrollView.superview?.bounds.width else { return }

        let offsetX = scrollView.contentOffset.x
        let progress = (offsetX - width) / width

        let toIndex: Int
        if progress > 0 {
            toIndex = min(fromIndex + 1, childPanelControllers.count - 1)
        } else if progress < 0 {
            toIndex = max(fromIndex - 1, 0)
        } else {
            toIndex = fromIndex
        }

        experimentSegmentControl.updateSelectionProgress(
            fromIndex: fromIndex,
            toIndex: toIndex,
            progress: progress
        )
        applyTheme(fromIndex: fromIndex, toIndex: toIndex, progress: abs(progress))
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        swipeFromIndex = nil
    }

    // MARK: TabDisplayViewDragAndDropInteraction

    func dragAndDropStarted() {
        pageScrollView?.isScrollEnabled = false
    }

    func dragAndDropEnded() {
        pageScrollView?.isScrollEnabled = true
    }

    // MARK: - Notifiable
    nonisolated func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIAccessibility.reduceTransparencyStatusDidChangeNotification:
            DispatchQueue.main.async { [weak self] in
                self?.updateBlurView()
            }
        default: break
        }
    }
}
