// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit
import Storage

extension LibraryViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

class LibraryViewController: UIViewController {
    struct UX {
        struct NavigationMenu {
            static let height: CGFloat = 32
            static let width: CGFloat = 343
            static let margin: CGFloat = 16
            static let bottom: CGFloat = 32
        }
    }

    var viewModel: LibraryViewModel
    var notificationCenter: NotificationProtocol
    weak var delegate: LibraryPanelDelegate?
    var onViewDismissed: (() -> Void)?

    // Views
    private var controllerContainerView: UIView = .build { view in }
    fileprivate lazy var topSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.theme.ecosia.barSeparator
        return view
    }()

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

    private lazy var topLeftButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed("goBack")?.imageFlippedForRightToLeftLayoutDirection(),
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
    init(profile: Profile, tabManager: TabManager, notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        applyTheme()
        setupNotifications(forObserver: self, observing: [.DisplayThemeChanged, .LibraryPanelStateDidChange])
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
        view.addSubviews(controllerContainerView, librarySegmentControl)

        NSLayoutConstraint.activate([
            librarySegmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            librarySegmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.NavigationMenu.margin),
            librarySegmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.NavigationMenu.margin),

            controllerContainerView.topAnchor.constraint(equalTo: librarySegmentControl.bottomAnchor, constant: UX.NavigationMenu.bottom),
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

    @objc func panelChanged() {
        // Ecosia // var eventValue: TelemetryWrapper.EventValue
        var selectedPanel: LibraryPanelType

        switch librarySegmentControl.selectedSegmentIndex {
        case 0:
            selectedPanel = .bookmarks
            // Ecosia // eventValue = .bookmarksPanel
        case 1:
            selectedPanel = .history
            // Ecosia // eventValue = .historyPanel
        case 2:
            selectedPanel = .readingList
        case 3:
            selectedPanel = .downloads
        default:
            return
        }

        setupOpenPanel(panelType: selectedPanel)
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
        view.bringSubviewToFront(librarySegmentControl)
        libraryPanel.endAppearanceTransition()

        libraryPanel.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            libraryPanel.view.topAnchor.constraint(equalTo: controllerContainerView.topAnchor),
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
        switch viewModel.currentPanelState {
        case .bookmarks(state: .inFolder),
             .history(state: .inFolder):
            topLeftButton.image = UIImage.templateImageNamed("goBack")?.imageFlippedForRightToLeftLayoutDirection()
            navigationItem.leftBarButtonItem = topLeftButton
        case .bookmarks(state: .itemEditMode):
            topLeftButton.image = UIImage.templateImageNamed("goBack")
            navigationItem.leftBarButtonItem = topLeftButton
        default:
            navigationItem.leftBarButtonItem = nil
        }
    }

    private func topRightButtonSetup() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: .inFolderEditMode):
            navigationItem.rightBarButtonItem = nil
        case .bookmarks(state: .itemEditMode):
            topRightButton.title = .SettingsAddCustomEngineSaveButtonText
            navigationItem.rightBarButtonItem = topRightButton
        default:
            topRightButton.title = String.AppSettingsDone
            navigationItem.rightBarButtonItem = topRightButton
        }
    }

    private func bottomToolbarButtonSetup() {
        guard let panel = viewModel.currentPanel else { return }

        let shouldHideBar = shouldHideBottomToolbar(panel: panel)
        navigationController?.setToolbarHidden(shouldHideBar, animated: true)
        setToolbarItems(panel.bottomToolbarItems, animated: true)
    }

}

// MARK: Notifiable
extension LibraryViewController: NotificationThemeable, Notifiable {

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        case .LibraryPanelStateDidChange:
            setupButtons()
        default: break
        }
    }

    @objc func applyTheme() {
        viewModel.panelDescriptors.forEach { item in
            (item.viewController as? NotificationThemeable)?.applyTheme()
        }

        // There is an ANNOYING bar in the nav bar above the segment control. These are the
        // UIBarBackgroundShadowViews. We must set them to be clear images in order to
        // have a seamless nav bar, if embedding the segmented control.
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.theme.homePanel.panelBackground
        navAppearance.shadowImage = UIImage()
        navAppearance.shadowColor = .clear
        navAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.theme.ecosia.primaryText]
        navigationController?.navigationBar.standardAppearance = navAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navAppearance
        navigationController?.navigationBar.tintColor = UIColor.theme.ecosia.primaryButton

        view.backgroundColor = UIColor.theme.homePanel.panelBackground

        let appearance = UIToolbarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.theme.tabTray.toolbar
        appearance.shadowColor = UIColor.theme.ecosia.barSeparator
        navigationController?.toolbar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.toolbar.scrollEdgeAppearance = appearance
        }
        navigationController?.toolbar.tintColor = UIColor.theme.ecosia.primaryButton

        librarySegmentControl.setTitleTextAttributes([.foregroundColor: UIColor.theme.ecosia.primaryText], for: .normal)
        librarySegmentControl.setTitleTextAttributes([.foregroundColor: UIColor.Light.Text.primary], for: .selected)
        librarySegmentControl.selectedSegmentTintColor = .Light.Background.primary
        librarySegmentControl.backgroundColor = UIColor.theme.ecosia.segmentBackground

        setNeedsStatusBarAppearanceUpdate()
    }
}
