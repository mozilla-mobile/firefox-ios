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

    // Delegate
    weak var delegate: LibraryPanelDelegate?

    // Variables
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

    fileprivate lazy var topLeftButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed("goBack")?.imageFlippedForRightToLeftLayoutDirection(),
                                     style: .plain,
                                     target: self,
                                     action: #selector(topLeftButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.topLeftButton
        return button
    }()

    fileprivate lazy var topRightButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(title: String.AppSettingsDone, style: .done, target: self, action: #selector(topRightButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.topRightButton
        return button
    }()

    // MARK: - Bottom Toolbar
    private lazy var bottomLeftButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed("nav-add"), style: .plain, target: self, action: #selector(bottomLeftButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomLeftButton
        return button
    }()

    private lazy var bottomRightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .BookmarksEdit, style: .plain, target: self, action: #selector(bottomRightButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomRightButton
        return button
    }()

    private lazy var bottomSearchButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed(ImageIdentifiers.libraryPanelSearch),
                                     style: .plain,
                                     target: self,
                                     action: #selector(bottomSearchButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomSearchButton
        return button
    }()

    lazy var bottomDeleteButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed(ImageIdentifiers.libraryPanelDelete),
                                     style: .plain,
                                     target: self,
                                     action: #selector(bottomDeleteButtonAction))
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.bottomDeleteButton
        return button
    }()

    private lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }()

    private lazy var bottomToolbarItemsBothButtons: [UIBarButtonItem] = {
        return [bottomLeftButton, flexibleSpace, bottomRightButton]
    }()

    private lazy var bottomToolbarItemsSingleButton: [UIBarButtonItem] = {
        return [flexibleSpace, bottomRightButton]
    }()

    private lazy var bottomToolbarHistoryItemsButton: [UIBarButtonItem] = {
        return [bottomDeleteButton, flexibleSpace, bottomSearchButton, flexibleSpace]
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
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Needed to update toolbar on panel changes
        updateViewWithState()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        applyTheme()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    private func viewSetup() {
        if let appWindow = (UIApplication.shared.delegate?.window),
           let window = appWindow as UIWindow? {
            window.backgroundColor = .black
        }

        setToolbarItems(bottomToolbarItemsSingleButton, animated: false)
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

        if selectedPanel == nil {
            selectedPanel = .bookmarks
        }
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
        updatePanelState()
        shouldShowBottomToolbar()
        setupButtons()
    }

    fileprivate func updateTitle() {
        if let newTitle = selectedPanel?.title {
            navigationItem.title = newTitle
        }
    }

    fileprivate func shouldShowBottomToolbar() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: let subState):
            navigationController?.setToolbarHidden(subState == .mainView, animated: false)
        case .history:
            let shouldShowSearch = viewModel.shouldShowSearch
            navigationController?.setToolbarHidden(!shouldShowSearch, animated: true)
        default:
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }

    // MARK: - Panel
    var selectedPanel: LibraryPanelType? {
        didSet {
            if oldValue == selectedPanel {
                // Prevent flicker, allocations, and disk access: avoid duplicate view controllers.
                return
            }

            hideCurrentPanel()

            if let index = selectedPanel?.rawValue {

                if index < viewModel.panelDescriptors.count {
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
                }
            }
            librarySegmentControl.selectedSegmentIndex = selectedPanel!.rawValue
        }
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
        switch librarySegmentControl.selectedSegmentIndex {
        case 0:
            selectedPanel = .bookmarks
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .libraryPanel, value: .bookmarksPanel)
        case 1:
            selectedPanel = .history
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .libraryPanel, value: .historyPanel)
        case 2:
            selectedPanel = .downloads
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .libraryPanel, value: .downloadsPanel)
        case 3:
            selectedPanel = .readingList
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .libraryPanel, value: .readingListPanel)
        default:
            return
        }
    }

    fileprivate func hideCurrentPanel() {
        if let panel = children.first {
            panel.willMove(toParent: nil)
            panel.beginAppearanceTransition(false, animated: false)
            panel.view.removeFromSuperview()
            panel.endAppearanceTransition()
            panel.removeFromParent()
        }
    }

    fileprivate func showPanel(_ libraryPanel: UIViewController) {
        updateStateOnShowPanel(to: selectedPanel)
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

    fileprivate func updatePanelState() {
        guard let panel = children.first as? UINavigationController else { return }

        if selectedPanel == .bookmarks {
            if panel.viewControllers.count > 1 {
                if viewModel.currentPanelState == .bookmarks(state: .mainView) {
                    viewModel.currentPanelState = .bookmarks(state: .inFolder)
                } else if viewModel.currentPanelState == .bookmarks(state: .inFolderEditMode),
                     let _ = panel.viewControllers.last as? BookmarkDetailPanel {
                    viewModel.currentPanelState = .bookmarks(state: .itemEditMode)
                }
            } else {
                viewModel.currentPanelState = .bookmarks(state: .mainView)
            }

        } else if selectedPanel == .history {
            if panel.viewControllers.count > 1 {
                if viewModel.currentPanelState == .history(state: .mainView) || viewModel.currentPanelState == .history(state: .search) {
                    viewModel.currentPanelState = .history(state: .inFolder)
                }
            } else if viewModel.currentPanelState != .history(state: .search) {
                 viewModel.currentPanelState = .history(state: .mainView)
            }
        }
    }

    fileprivate func updateStateOnShowPanel(to panelType: LibraryPanelType?) {
        switch panelType {
        case .bookmarks:
            viewModel.currentPanelState = .bookmarks(state: .mainView)
        case .downloads:
            viewModel.currentPanelState = .downloads
        case .history:
            viewModel.currentPanelState = .history(state: .mainView)
        case .readingList:
            viewModel.currentPanelState = .readingList
        default:
            return
        }
    }

    // MARK: - Buttons setup
    private func setupButtons() {
        topLeftButtonSetup()
        topRightButtonSetup()
        bottomToolbarButtonSetup()
        bottomRightButtonSetup()
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

    fileprivate func bottomToolbarButtonSetup() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: .inFolderEditMode):
            setToolbarItems(bottomToolbarItemsBothButtons, animated: true)
        case .history:
            if viewModel.shouldShowSearch {
                setToolbarItems(bottomToolbarHistoryItemsButton, animated: true)
            }
        default:
            setToolbarItems(bottomToolbarItemsSingleButton, animated: false)
        }
    }

    fileprivate func bottomRightButtonSetup() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: let subState):
            if subState == .inFolder {
                bottomRightButton.title = .BookmarksEdit
            } else if subState == .inFolderEditMode {
                bottomRightButton.title = String.AppSettingsDone
            }
        default:
            return
        }
    }

    // MARK: - Nav bar button actions
    @objc func topLeftButtonAction() {
        guard let panel = children.first as? UINavigationController else { return }
        switch viewModel.currentPanelState {
        case .bookmarks(state: let subState):
            leftButtonBookmarkActions(for: subState, onPanel: panel)
        default:
            panel.popViewController(animated: true)
        }
        updateViewWithState()
    }

    @objc func topRightButtonAction() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: .itemEditMode):
            rightButtonBookmarkActions(for: .itemEditMode)
        case .history(state: .search):
            rightButtonHistoryActions(for: .search)
        default:
            self.dismiss(animated: true, completion: nil)
        }
        updateViewWithState()
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

        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        if theme == .dark {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            bottomSearchButton.tintColor = .white
            bottomDeleteButton.tintColor = .white
        } else {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            bottomSearchButton.tintColor = .black
            bottomDeleteButton.tintColor = .black
        }
        setNeedsStatusBarAppearanceUpdate()
    }
}
