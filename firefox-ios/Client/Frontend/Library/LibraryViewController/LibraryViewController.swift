// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

extension LibraryViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

class LibraryViewController: UIViewController, Themeable {
    struct UX {
        struct NavigationMenu {
            static let height: CGFloat = 32
            static let width: CGFloat = 343
        }
    }

    var childPanelControllers = [UINavigationController]()
    var viewModel: LibraryViewModel
    var notificationCenter: NotificationProtocol
    weak var delegate: LibraryPanelDelegate?
    weak var navigationHandler: LibraryNavigationHandler?
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var logger: Logger
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    // Views
    private var controllerContainerView: UIView = .build { view in }
    private var titleLabel: UILabel?

    // UI Elements
    private lazy var librarySegmentControl: UISegmentedControl = .build { librarySegmentControl in
        librarySegmentControl.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.segmentedControl
        librarySegmentControl.selectedSegmentIndex = 1
    }

    private lazy var segmentControlToolbar: UIToolbar = .build { [weak self] toolbar in
        guard let self = self else { return }
        toolbar.delegate = self
    }

    private lazy var topLeftButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.chevronLeft)?
                .imageFlippedForRightToLeftLayoutDirection(),
            style: .plain,
            target: self,
            action: #selector(topLeftButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.topLeftButton
        return button
    }()

    private lazy var topRightButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(
            title: String.AppSettingsDone,
            style: .done,
            target: self,
            action: #selector(topRightButtonAction)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.topRightButton
        return button
    }()

    // MARK: - Initializers
    init(profile: Profile,
         tabManager: TabManager,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = LibraryViewModel(withProfile: profile)
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.logger = logger
        self.windowUUID = tabManager.windowUUID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [.LibraryPanelStateDidChange, .LibraryPanelBookmarkTitleChanged]
        )
       // updateTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recreateSegmentedControl()
        applyTheme()
        // Ensure navigation bar is visible and title is set
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.isNavigationBarHidden = false
        updateTitle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            self.navigationItem.titleView?.setNeedsLayout()
            self.navigationItem.titleView?.layoutIfNeeded()
        }
    }

    private func recreateSegmentedControl() {
        let newSegmentControl = UISegmentedControl(items: viewModel.segmentedControlItems)
        newSegmentControl.selectedSegmentIndex = viewModel.selectedPanel?.rawValue ?? 0
        newSegmentControl.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.segmentedControl
        newSegmentControl.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        newSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        librarySegmentControl = newSegmentControl
        let newItem = UIBarButtonItem(customView: newSegmentControl)
        librarySegmentControl.selectedSegmentIndex = viewModel.selectedPanel?.rawValue ?? 0
        segmentControlToolbar.setItems([newItem], animated: false)
        NSLayoutConstraint.activate([
            librarySegmentControl.widthAnchor.constraint(equalToConstant: UX.NavigationMenu.width),
            librarySegmentControl.heightAnchor.constraint(equalToConstant: UX.NavigationMenu.height),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Needed to update toolbar on panel changes
        updateViewWithState()
        // Update title when layout changes to ensure proper width calculation
        if titleLabel != nil {
            updateTitle()
        }
    }

    private func viewSetup() {
        navigationItem.rightBarButtonItem = topRightButton
        // Ensure navigation bar is visible
        navigationController?.setNavigationBarHidden(false, animated: false)
        view.addSubviews(controllerContainerView, segmentControlToolbar)

        NSLayoutConstraint.activate([
            segmentControlToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentControlToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentControlToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            librarySegmentControl.widthAnchor.constraint(equalToConstant: UX.NavigationMenu.width),
            librarySegmentControl.heightAnchor.constraint(equalToConstant: UX.NavigationMenu.height),

            controllerContainerView.topAnchor.constraint(equalTo: segmentControlToolbar.bottomAnchor),
            controllerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controllerContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controllerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func updateViewWithState() {
        setupButtons()
        updateSegmentControl()
    }

    /// The Library title can be updated from some subpanels navigation actions
    /// - Parameter subpanelTitle: The title coming from a subpanel, optional as by default we set the title to be
    /// the selectedPanel.title
    private func updateTitle(subpanelTitle: String? = nil) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        // Determine the correct title text
        let titleText: String = {
            if let subpanelTitle { return subpanelTitle }
            if let newTitle = viewModel.selectedPanel?.title { return newTitle }
            return ""
        }()
        guard !titleText.isEmpty else {
            navigationItem.titleView = nil
            titleLabel = nil
            return
        }
        // --- Label setup ---
        let label = UILabel()
        label.text = titleText
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.9
        label.translatesAutoresizingMaskIntoConstraints = false
        // --- Container view setup ---
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        // Allow the label to shrink properly inside container
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width - 180),
            container.heightAnchor.constraint(equalToConstant: 44)
        ])
        navigationItem.titleView = container
        titleLabel = label
        // Force layout update to ensure proper sizing
        DispatchQueue.main.async {
            container.layoutIfNeeded()
            label.layoutIfNeeded()
        }
    }

    private func applyThemeToTitleLabel() {
        guard let label = titleLabel else { return }
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        label.textColor = theme.colors.textPrimary
    }

    private func shouldHideBottomToolbar(panel: LibraryPanel) -> Bool {
        return panel.bottomToolbarItems.isEmpty || (navigationController?.isNavigationBarHidden ?? false)
    }

    func setupLibraryPanel(_ panel: UIViewController,
                           accessibilityLabel: String,
                           accessibilityIdentifier: String) {
        (panel as? LibraryPanel)?.libraryPanelDelegate = self
        panel.view.accessibilityNavigationStyle = .combined
        panel.view.accessibilityLabel = accessibilityLabel
        panel.view.accessibilityIdentifier = accessibilityIdentifier
        panel.title = accessibilityLabel
        panel.navigationController?.setNavigationBarHidden(true, animated: true)
        panel.navigationController?.isNavigationBarHidden = true
    }

    @objc
    func panelChanged() {
        var eventValue: TelemetryWrapper.EventValue
        var selectedPanel: LibraryPanelType

        switch librarySegmentControl.selectedSegmentIndex {
        case 0:
            selectedPanel = .bookmarks
            eventValue = .bookmarksPanel
        case 1:
            selectedPanel = .history
            eventValue = .historyPanel
        case 2:
            selectedPanel = .downloads
            eventValue = .downloadsPanel
        case 3:
            selectedPanel = .readingList
            eventValue = .readingListPanel
        default:
            return
        }

        setupOpenPanel(panelType: selectedPanel)
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .libraryPanel,
            value: eventValue
        )
    }

    func setupOpenPanel(panelType: LibraryPanelType) {
        // Prevent flicker, allocations, and disk access: avoid duplicate view controllers.
        guard viewModel.selectedPanel != panelType else { return }

        viewModel.selectedPanel = panelType
        hideCurrentPanel()
        setupPanel()
    }

    private func setupPanel() {
        guard let index = viewModel.selectedPanel?.rawValue,
              index < viewModel.panelDescriptors.count else { return }

        let panelDescriptor = viewModel.panelDescriptors[index]
        if let panelVC = childPanelControllers[index].topViewController {
            let panelNavigationController = childPanelControllers[index]
            setupLibraryPanel(
                panelVC,
                accessibilityLabel: panelDescriptor.accessibilityLabel,
                accessibilityIdentifier: panelDescriptor.accessibilityIdentifier
            )
            showPanel(panelNavigationController)
            navigationHandler?.start(
                panelType: viewModel.selectedPanel ?? .bookmarks,
                navigationController: panelNavigationController
            )
        }
        librarySegmentControl.selectedSegmentIndex = viewModel.selectedPanel?.rawValue ?? 0
    }

    private func hideCurrentPanel() {
        if let panel = children.first {
            panel.willMove(toParent: nil)
            panel.beginAppearanceTransition(false, animated: false)
            panel.view.removeFromSuperview()
            panel.endAppearanceTransition()
            panel.removeFromParent()
        }
    }

    private func showPanel(_ libraryPanel: UIViewController) {
        addChild(libraryPanel)
        libraryPanel.beginAppearanceTransition(true, animated: false)
        controllerContainerView.addSubview(libraryPanel.view)
        view.bringSubviewToFront(segmentControlToolbar)
        libraryPanel.endAppearanceTransition()

        libraryPanel.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            libraryPanel.view.topAnchor.constraint(equalTo: controllerContainerView.topAnchor),
            libraryPanel.view.leadingAnchor.constraint(equalTo: controllerContainerView.leadingAnchor),
            libraryPanel.view.bottomAnchor.constraint(equalTo: controllerContainerView.bottomAnchor),
            libraryPanel.view.trailingAnchor.constraint(equalTo: controllerContainerView.trailingAnchor)
        ])
        libraryPanel.didMove(toParent: self)
        // Ensure navigation bar is visible before updating title
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.isNavigationBarHidden = false
        // Delay title update to ensure navigation bar is fully visible
        DispatchQueue.main.async { [weak self] in
            self?.updateTitle()
        }
    }

    // MARK: - Buttons setup
    private func setupButtons() {
        topLeftButtonSetup()
        topRightButtonSetup()
        bottomToolbarButtonSetup()
    }

    private func topLeftButtonSetup() {
        let panelState = getCurrentPanelState()
        switch panelState {
        case .bookmarks(state: .inFolder), .bookmarks(state: .transitioning),
             .history(state: .inFolder):
            topLeftButton.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.chevronLeft)?
                .imageFlippedForRightToLeftLayoutDirection()
            navigationItem.leftBarButtonItem = topLeftButton
        case .bookmarks(state: .itemEditMode), .bookmarks(state: .itemEditModeInvalidField):
            topLeftButton.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross)
            navigationItem.leftBarButtonItem = topLeftButton
        default:
            navigationItem.leftBarButtonItem = nil
        }
    }

    private func topRightButtonSetup() {
        let panelState = getCurrentPanelState()
        switch panelState {
        case .bookmarks(state: .inFolderEditMode):
            navigationItem.rightBarButtonItem = nil
        case .bookmarks(state: .itemEditMode):
            topRightButton.title = .SettingsAddCustomEngineSaveButtonText
            navigationItem.rightBarButtonItem = topRightButton
            navigationItem.rightBarButtonItem?.isEnabled = true
        case .bookmarks(state: .itemEditModeInvalidField):
            topRightButton.title = .SettingsAddCustomEngineSaveButtonText
            navigationItem.rightBarButtonItem = topRightButton
            navigationItem.rightBarButtonItem?.isEnabled = false
        default:
            topRightButton.title = String.AppSettingsDone
            navigationItem.rightBarButtonItem = topRightButton
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    // MARK: - Toolbar Button Actions
    @objc
    func topLeftButtonAction() {
        guard let navController = children.first as? UINavigationController,
              getCurrentPanelState() != .bookmarks(state: .transitioning) else {
            return
        }

        navController.popViewController(animated: true)
        let panel = getCurrentPanel()
        panel?.handleLeftTopButton()
    }

    @objc
    func topRightButtonAction() {
        guard let panel = getCurrentPanel() else { return }

        if panel.shouldDismissOnDone() {
            dismiss(animated: true, completion: nil)
        }

        panel.handleRightTopButton()
    }

    private func getCurrentPanelState() -> LibraryPanelMainState {
        if let panelVC = getCurrentPanel() {
            return panelVC.state
        }
        return .bookmarks(state: .inFolder)
    }

    func getCurrentPanel() -> LibraryPanel? {
        let panelNavigationController = childPanelControllers[viewModel.selectedPanel?.rawValue ?? 0]
        let panelVC = panelNavigationController.viewControllers.last { $0 is LibraryPanel }
        if let panelVC = panelVC as? LibraryPanel {
            return panelVC
        }
        return nil
    }

    private func bottomToolbarButtonSetup() {
        guard let panel = getCurrentPanel() else { return }

        let shouldHideBar = shouldHideBottomToolbar(panel: panel)
        navigationController?.setToolbarHidden(shouldHideBar, animated: true)
        setToolbarItems(panel.bottomToolbarItems, animated: true)
    }

    private func setupToolBarAppearance() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let standardAppearance = UIToolbarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = theme.colors.layer1
        navigationController?.toolbar.standardAppearance = standardAppearance
        navigationController?.toolbar.compactAppearance = standardAppearance
        navigationController?.toolbar.scrollEdgeAppearance = standardAppearance
        navigationController?.toolbar.compactScrollEdgeAppearance = standardAppearance
        navigationController?.toolbar.tintColor = theme.colors.actionPrimary
    }

    private func updateSegmentControl() {
        guard librarySegmentControl.numberOfSegments > 0 else { return }

        let panelState = getCurrentPanelState()

        switch panelState {
        case .bookmarks(state: .inFolderEditMode):
            let affectedOptions: [LibraryPanelType] = [.history, .downloads, .readingList]
            affectedOptions.forEach { librarySegmentOption in
                self.librarySegmentControl.setEnabled(false, forSegmentAt: librarySegmentOption.rawValue)
            }
        default:
            LibraryPanelType.allCases.forEach { librarySegmentOption in
                self.librarySegmentControl.setEnabled(true, forSegmentAt: librarySegmentOption.rawValue)
            }
        }
    }

    func applyTheme() {
        // There is an ANNOYING bar in the nav bar above the segment control. These are the
        // UIBarBackgroundShadowViews. We must set them to be clear images in order to
        // have a seamless nav bar, if embedding the segmented control.
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        navigationController?.navigationBar.barTintColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        navigationController?.navigationBar.backgroundColor = theme.colors.layer1
        navigationController?.toolbar.barTintColor = theme.colors.layer1
        navigationController?.toolbar.tintColor = theme.colors.actionPrimary
        segmentControlToolbar.barTintColor = theme.colors.layer1
        segmentControlToolbar.tintColor = theme.colors.textPrimary
        segmentControlToolbar.isTranslucent = false

        setNeedsStatusBarAppearanceUpdate()
        setupToolBarAppearance()
        applyThemeToTitleLabel()
    }

    func setNavigationBarHidden(_ value: Bool) {
        navigationController?.setToolbarHidden(value, animated: true)
        navigationController?.setNavigationBarHidden(value, animated: false)
        let controlbarHeight = segmentControlToolbar.frame.height
        segmentControlToolbar.transform = value ? .init(translationX: 0, y: -controlbarHeight) : .identity
        controllerContainerView.transform = value ? .init(translationX: 0, y: -controlbarHeight) : .identity

        // Reload the current panel
        guard let index = viewModel.selectedPanel?.rawValue,
              let currentPanel = childPanelControllers[safe: index] else { return }
        currentPanel.view.layoutIfNeeded()
        // When navigation bar becomes visible again, update the title
        if !value {
            DispatchQueue.main.async { [weak self] in
                self?.updateTitle()
            }
        }
    }
}

// MARK: Notifiable
extension LibraryViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .LibraryPanelStateDidChange:
            ensureMainThread {
                self.setupButtons()
                self.updateSegmentControl()
            }

        case .LibraryPanelBookmarkTitleChanged:
            let title = notification.userInfo?["title"] as? String

            ensureMainThread {
                // Ensure navigation bar is visible before updating title
                self.navigationController?.setNavigationBarHidden(false, animated: false)
                self.navigationController?.isNavigationBarHidden = false
                // Small delay to ensure navigation bar is fully visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.updateTitle(subpanelTitle: title)
                }
            }

        default: break
        }
    }
}
