// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage
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
    var onViewDismissed: (() -> Void)?
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var logger: Logger

    // Views
    private var controllerContainerView: UIView = .build { view in }

    // UI Elements
    private lazy var librarySegmentControl: UISegmentedControl = {
        var librarySegmentControl: UISegmentedControl
        librarySegmentControl = UISegmentedControl(items: viewModel.segmentedControlItems)
        librarySegmentControl.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.segmentedControl
        librarySegmentControl.selectedSegmentIndex = 1
        librarySegmentControl.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        librarySegmentControl.translatesAutoresizingMaskIntoConstraints = false
        return librarySegmentControl
    }()

    private lazy var segmentControlToolbar: UIToolbar = .build { [weak self] toolbar in
        guard let self = self else { return }
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: self.librarySegmentControl)], animated: false)
    }

    private lazy var topLeftButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.chevronLeft)?.imageFlippedForRightToLeftLayoutDirection(),
            style: .plain,
            target: self,
            action: #selector(topLeftButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.topLeftButton
        return button
    }()

    private lazy var topRightButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(title: String.AppSettingsDone, style: .done, target: self, action: #selector(topRightButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.topRightButton
        return button
    }()

    // MARK: - Initializers
    init(profile: Profile,
         tabManager: TabManager,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.logger = logger

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        listenForThemeChange(view)
        setupNotifications(forObserver: self, observing: [.LibraryPanelStateDidChange])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Needed to update toolbar on panel changes
        updateViewWithState()
    }

    private func viewSetup() {
        navigationItem.rightBarButtonItem = topRightButton
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        LegacyThemeManager.instance.statusBarStyle
    }

    func resetHistoryPanelPagination() {
        if CoordinatorFlagManager.isLibraryCoordinatorEnabled {
            viewModel.resetHistoryPanelPagination()
        }
    }

    func updateViewWithState() {
        setupButtons()
    }

    fileprivate func updateTitle() {
        if let newTitle = viewModel.selectedPanel?.title {
            navigationItem.title = newTitle
        }
    }

    private func shouldHideBottomToolbar(panel: LibraryPanel) -> Bool {
        return panel.bottomToolbarItems.isEmpty
    }

    func setupLibraryPanel(_ panel: UIViewController,
                           accessibilityLabel: String,
                           accessibilityIdentifier: String) {
        (panel as? LibraryPanel)?.libraryPanelDelegate = self
        panel.view.accessibilityNavigationStyle = .combined
        panel.view.accessibilityLabel = accessibilityLabel
        panel.view.accessibilityIdentifier = accessibilityIdentifier
        panel.title = accessibilityLabel
        panel.navigationController?.setNavigationBarHidden(true, animated: false)
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
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .libraryPanel, value: eventValue)
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

        if CoordinatorFlagManager.isLibraryCoordinatorEnabled {
            let panelDescriptor = viewModel.panelDescriptors[index]
            if let panelVC = childPanelControllers[index].topViewController {
                let panelNavigationController = childPanelControllers[index]
                setupLibraryPanel(panelVC, accessibilityLabel: panelDescriptor.accessibilityLabel, accessibilityIdentifier: panelDescriptor.accessibilityIdentifier)
                showPanel(panelNavigationController)
                navigationHandler?.start(panelType: viewModel.selectedPanel ?? .bookmarks, navigationController: panelNavigationController)
            }
        } else {
            viewModel.setupNavigationController()
            if let panelVC = self.viewModel.panelDescriptors[index].viewController,
               let navigationController = self.viewModel.panelDescriptors[index].navigationController {
                let accessibilityLabel = self.viewModel.panelDescriptors[index].accessibilityLabel
                let accessibilityId = self.viewModel.panelDescriptors[index].accessibilityIdentifier
                setupLibraryPanel(panelVC,
                                  accessibilityLabel: accessibilityLabel,
                                  accessibilityIdentifier: accessibilityId)
                self.showPanel(navigationController)
            }
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
            libraryPanel.view.topAnchor.constraint(equalTo: segmentControlToolbar.bottomAnchor),
            libraryPanel.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            libraryPanel.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            libraryPanel.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        libraryPanel.didMove(toParent: self)
        updateTitle()
    }

    // MARK: - Buttons setup
    private func setupButtons() {
        topLeftButtonSetup()
        topRightButtonSetup()
        bottomToolbarButtonSetup()
    }

    private func topLeftButtonSetup() {
        var panelState: LibraryPanelMainState
        if CoordinatorFlagManager.isLibraryCoordinatorEnabled {
            panelState = getCurrentPanelState()
        } else {
            panelState = viewModel.currentPanelState
        }
        switch panelState {
        case .bookmarks(state: .inFolder),
             .history(state: .inFolder):
            topLeftButton.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.chevronLeft)?.imageFlippedForRightToLeftLayoutDirection()
            navigationItem.leftBarButtonItem = topLeftButton
        case .bookmarks(state: .itemEditMode), .bookmarks(state: .itemEditModeInvalidField):
            topLeftButton.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross)
            navigationItem.leftBarButtonItem = topLeftButton
        default:
            navigationItem.leftBarButtonItem = nil
        }
    }

    private func topRightButtonSetup() {
        var panelState: LibraryPanelMainState
        if CoordinatorFlagManager.isLibraryCoordinatorEnabled {
            panelState = getCurrentPanelState()
        } else {
            panelState = viewModel.currentPanelState
        }
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

    private func getCurrentPanelState() -> LibraryPanelMainState {
        if let panelVC = getCurrentPanel() {
            return panelVC.state
        }
        return .bookmarks(state: .inFolder)
    }

    func getCurrentPanel() -> LibraryPanel? {
        let panelNavigationController = childPanelControllers[viewModel.selectedPanel?.rawValue ?? 0]
        if let panelVC = panelNavigationController.topViewController as? LibraryPanel {
            return panelVC
        }
        return nil
    }

    private func bottomToolbarButtonSetup() {
        var panel: LibraryPanel?
        if CoordinatorFlagManager.isLibraryCoordinatorEnabled {
            panel = getCurrentPanel()
        } else {
            panel = viewModel.currentPanel
        }
        guard let panel = panel else { return }

        let shouldHideBar = shouldHideBottomToolbar(panel: panel)
        navigationController?.setToolbarHidden(shouldHideBar, animated: true)
        setToolbarItems(panel.bottomToolbarItems, animated: true)
    }

    private func setupToolBarAppearance() {
        let standardAppearance = UIToolbarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundColor = themeManager.currentTheme.colors.layer1
        navigationController?.toolbar.standardAppearance = standardAppearance
        navigationController?.toolbar.compactAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            navigationController?.toolbar.scrollEdgeAppearance = standardAppearance
            navigationController?.toolbar.compactScrollEdgeAppearance = standardAppearance
        }
        navigationController?.toolbar.tintColor = themeManager.currentTheme.colors.actionPrimary
    }

    func applyTheme() {
        // There is an ANNOYING bar in the nav bar above the segment control. These are the
        // UIBarBackgroundShadowViews. We must set them to be clear images in order to
        // have a seamless nav bar, if embedding the segmented control.
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        view.backgroundColor = themeManager.currentTheme.colors.layer3
        navigationController?.navigationBar.barTintColor = themeManager.currentTheme.colors.layer1
        navigationController?.navigationBar.tintColor = themeManager.currentTheme.colors.actionPrimary
        navigationController?.navigationBar.backgroundColor = themeManager.currentTheme.colors.layer1
        navigationController?.toolbar.barTintColor = themeManager.currentTheme.colors.layer1
        navigationController?.toolbar.tintColor = themeManager.currentTheme.colors.actionPrimary
        segmentControlToolbar.barTintColor = themeManager.currentTheme.colors.layer1
        segmentControlToolbar.tintColor = themeManager.currentTheme.colors.textPrimary
        segmentControlToolbar.isTranslucent = false

        setNeedsStatusBarAppearanceUpdate()
        setupToolBarAppearance()
    }
}

// MARK: Notifiable
extension LibraryViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .LibraryPanelStateDidChange:
            setupButtons()
        default: break
        }
    }
}
