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
        }
    }

    var viewModel: LibraryViewModel
    weak var delegate: LibraryPanelDelegate?
    var onViewDismissed: (() -> Void)?

    // Views
    fileprivate var controllerContainerView: UIView = .build { view in }

    // UI Elements
    lazy var librarySegmentControl: UISegmentedControl = {
        var librarySegmentControl: UISegmentedControl
        librarySegmentControl = UISegmentedControl(items: viewModel.segmentedControlItems)
        librarySegmentControl.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.segmentedControl
        librarySegmentControl.selectedSegmentIndex = 1
        librarySegmentControl.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        librarySegmentControl.translatesAutoresizingMaskIntoConstraints = false
        return librarySegmentControl
    }()

    lazy var navigationToolbar: UIToolbar = .build { [weak self] toolbar in
        guard let self = self else { return }
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: self.librarySegmentControl)], animated: false)
    }

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
    init(profile: Profile, tabManager: TabManager) {
        self.viewModel = LibraryViewModel(withProfile: profile, tabManager: tabManager)

        super.init(nibName: nil, bundle: nil)
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
        print("YRD viewDidLoad")
        viewSetup()
        applyTheme()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("YRD viewWillAppear")
        applyTheme()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("YRD viewDidLayoutSubviews")
        // Needed to update toolbar on panel changes
        updateViewWithState()
    }

    private func viewSetup() {
        print("YRD viewSetup")
        if let appWindow = (UIApplication.shared.delegate?.window),
           let window = appWindow as UIWindow? {
            window.backgroundColor = .black
        }

        navigationItem.rightBarButtonItem = topRightButton
        view.addSubviews(controllerContainerView, navigationToolbar)

        NSLayoutConstraint.activate([
            navigationToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            librarySegmentControl.widthAnchor.constraint(equalToConstant: UX.NavigationMenu.width),
            librarySegmentControl.heightAnchor.constraint(equalToConstant: UX.NavigationMenu.height),

            controllerContainerView.topAnchor.constraint(equalTo: navigationToolbar.bottomAnchor),
            controllerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controllerContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controllerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        if viewModel.selectedPanel == nil {
            viewModel.selectedPanel = .bookmarks
        }
        setupPanel()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        LegacyThemeManager.instance.statusBarStyle
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .DisplayThemeChanged, object: nil)
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
        print("YRD LVC shouldHideBottomToolbar")
        return panel.bottomToolbarItems().isEmpty
    }

    func setupLibraryPanel(_ panel: UIViewController,
                           accessibilityLabel: String,
                           accessibilityIdentifier: String) {
        print("YRD setupLibraryPanel with segment \(librarySegmentControl.selectedSegmentIndex)")
        (panel as? LibraryPanel)?.libraryPanelDelegate = self
        panel.view.accessibilityNavigationStyle = .combined
        panel.view.accessibilityLabel = accessibilityLabel
        panel.view.accessibilityIdentifier = accessibilityIdentifier
        panel.title = accessibilityLabel
        panel.navigationController?.setNavigationBarHidden(true, animated: false)
        panel.navigationController?.isNavigationBarHidden = true
    }

    @objc func panelChanged() {
        print("YRD panelChanged with segment \(librarySegmentControl.selectedSegmentIndex)")
        var eventValue: TelemetryWrapper.EventValue

        switch librarySegmentControl.selectedSegmentIndex {
        case 0:
            viewModel.selectedPanel = .bookmarks
            eventValue = .bookmarksPanel
        case 1:
            viewModel.selectedPanel = .history
            eventValue = .historyPanel
        case 2:
            viewModel.selectedPanel = .downloads
            eventValue = .downloadsPanel
        case 3:
            viewModel.selectedPanel = .readingList
            eventValue = .readingListPanel
        default:
            return
        }

        setupPanel()
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .libraryPanel, value: eventValue)
    }

    private func setupPanel() {
        print("YRD setupPanel")
        guard let index = viewModel.selectedPanel?.rawValue,
              index < viewModel.panelDescriptors.count else { return }

        viewModel.panelDescriptors[index].setup()
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
        print("YRD showPanel")
        addChild(libraryPanel)
        libraryPanel.beginAppearanceTransition(true, animated: false)
        controllerContainerView.addSubview(libraryPanel.view)
        view.bringSubviewToFront(navigationToolbar)
        libraryPanel.endAppearanceTransition()

        libraryPanel.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            libraryPanel.view.topAnchor.constraint(equalTo: navigationToolbar.bottomAnchor),
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

    fileprivate func topLeftButtonSetup() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: .inFolder),
             .history(state: .inFolder):
            topLeftButton.image = UIImage.templateImageNamed("goBack")?.imageFlippedForRightToLeftLayoutDirection()
            navigationItem.leftBarButtonItem = topLeftButton
        case .bookmarks(state: .itemEditMode):
            topLeftButton.image = UIImage.templateImageNamed("nav-stop")
            navigationItem.leftBarButtonItem = topLeftButton
        default:
            navigationItem.leftBarButtonItem = nil
        }
    }

    fileprivate func topRightButtonSetup() {
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
        guard let panel = viewModel.getCurrentPanel() else { return }

        let shouldHideBar = shouldHideBottomToolbar(panel: panel)
        navigationController?.setToolbarHidden(shouldHideBar, animated: true)
        setToolbarItems(panel.bottomToolbarItems(), animated: true)
    }
}

// MARK: UIAppearance
extension LibraryViewController: NotificationThemeable {
    @objc func applyTheme() {
        viewModel.panelDescriptors.forEach { item in
            (item.viewController as? NotificationThemeable)?.applyTheme()
        }

        // There is an ANNOYING bar in the nav bar above the segment control. These are the
        // UIBarBackgroundShadowViews. We must set them to be clear images in order to
        // have a seamless nav bar, if embedding the segmented control.
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        view.backgroundColor = UIColor.theme.homePanel.panelBackground
        navigationController?.navigationBar.barTintColor = UIColor.theme.tabTray.toolbar
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationController?.navigationBar.backgroundColor = UIColor.theme.tabTray.toolbar
        navigationController?.toolbar.barTintColor = UIColor.theme.tabTray.toolbar
        navigationController?.toolbar.tintColor = .systemBlue
        navigationToolbar.barTintColor = UIColor.theme.tabTray.toolbar
        navigationToolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
        navigationToolbar.isTranslucent = false

        setNeedsStatusBarAppearanceUpdate()
    }
}
