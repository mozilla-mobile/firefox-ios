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
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var logger: Logger
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

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

    func updateViewWithState() {
        setupButtons()
    }

    fileprivate func updateTitle() {
        if let newTitle = viewModel.selectedPanel?.title {
            navigationItem.title = newTitle
        }
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
        updateTitle()
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
        case .bookmarks(state: .inFolder),
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
    }

    func setNavigationBarHidden(_ value: Bool) {
        navigationController?.setToolbarHidden(value, animated: true)
        navigationController?.setNavigationBarHidden(value, animated: false)
        let controlbarHeight = segmentControlToolbar.frame.height
        segmentControlToolbar.transform = value ? .init(translationX: 0, y: -controlbarHeight) : .identity
        controllerContainerView.transform = value ? .init(translationX: 0, y: -controlbarHeight) : .identity
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
