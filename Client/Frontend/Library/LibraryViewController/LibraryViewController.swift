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

    var viewModel: LibraryViewModel

    // Delegate
    weak var delegate: LibraryPanelDelegate?

    // Variables
    var onViewDismissed: (() -> Void)? = nil

    // Views
    fileprivate var controllerContainerView: UIView = .build { view in }
    fileprivate var buttons: [LibraryPanelButton] = []

    // UI Elements
    lazy var librarySegmentControl: UISegmentedControl = {
        var librarySegmentControl: UISegmentedControl
        librarySegmentControl = UISegmentedControl(items: [UIImage(named: "library-bookmark")!,
                                                           UIImage(named: "library-history")!,
                                                           UIImage(named: "library-downloads")!,
                                                           UIImage(named: "library-readinglist")!])
        librarySegmentControl.accessibilityIdentifier = "librarySegmentControl"
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
        let button = UIBarButtonItem(image: UIImage.templateImageNamed("goBack"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(topLeftButtonAction))
        button.accessibilityIdentifier = "libraryPanelTopLeftButton"
        return button
    }()

    fileprivate lazy var topRightButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(title: String.AppSettingsDone, style: .done, target: self, action: #selector(topRightButtonAction))
        button.accessibilityIdentifier = "libraryPanelTopRightButton"
        return button
    }()

    fileprivate lazy var bottomLeftButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed("nav-add"), style: .plain, target: self,  action: #selector(bottomLeftButtonAction))
        button.accessibilityIdentifier = "libraryPanelBottomLeftButton"
        return button
    }()

    fileprivate lazy var bottomRightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: .BookmarksEdit, style: .plain, target: self, action: #selector(bottomRightButtonAction))
        button.accessibilityIdentifier = "bookmarksPanelBottomRightButton"
        return button
    }()

    lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }()

    fileprivate lazy var bottomToolbarItemsBothButtons: [UIBarButtonItem] = {
        return [bottomLeftButton, flexibleSpace, bottomRightButton]
    }()

    fileprivate lazy var bottomToolbarItemsSingleButton: [UIBarButtonItem] = {
        return [flexibleSpace, bottomRightButton]
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
            
            librarySegmentControl.widthAnchor.constraint(equalToConstant: 343),
            librarySegmentControl.heightAnchor.constraint(equalToConstant: CGFloat(ChronologicalTabsControllerUX.navigationMenuHeight)),
            
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

    fileprivate func updateViewWithState() {
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
            if subState == .mainView {
                navigationController?.setToolbarHidden(true, animated: true)
            } else {
                navigationController?.setToolbarHidden(false, animated: true)
            }
        default:
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }


    // MARK: - Panel
    var selectedPanel: LibraryPanelType? = nil {
        didSet {
            if oldValue == selectedPanel {
                // Prevent flicker, allocations, and disk access: avoid duplicate view controllers.
                return
            }

            if let index = oldValue?.rawValue {
                if index < buttons.count {
                    let currentButton = buttons[index]
                    currentButton.isSelected = false
                }
            }

            hideCurrentPanel()

            if let index = selectedPanel?.rawValue {
                if index < buttons.count {
                    let newButton = buttons[index]
                    newButton.isSelected = true
                }

                if index < viewModel.panelDescriptors.count {
                    viewModel.panelDescriptors[index].setup()
                    if let panel = self.viewModel.panelDescriptors[index].viewController,
                       let navigationController = self.viewModel.panelDescriptors[index].navigationController {
                        let accessibilityLabel = self.viewModel.panelDescriptors[index].accessibilityLabel
                        setupLibraryPanel(panel, accessibilityLabel: accessibilityLabel)
                        self.showPanel(navigationController)
                    }
                }
            }
            librarySegmentControl.selectedSegmentIndex = selectedPanel!.rawValue
        }
    }

    func setupLibraryPanel(_ panel: UIViewController, accessibilityLabel: String) {
        (panel as? LibraryPanel)?.libraryPanelDelegate = self
        panel.view.accessibilityNavigationStyle = .combined
        panel.view.accessibilityLabel = accessibilityLabel
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
                if viewModel.currentPanelState == .history(state: .mainView) {
                    viewModel.currentPanelState = .history(state: .inFolder)
                }
            } else {
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
    fileprivate func setupButtons() {
        topLeftButtonSetup()
        topRightButtonSetup()
        bottomToolbarButtonSetup()
        bottomRightButtonSetup()
    }

    fileprivate func topLeftButtonSetup() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: .inFolder),
             .history(state: .inFolder):
            topLeftButton.image = UIImage.templateImageNamed("goBack")
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
        default:
            self.dismiss(animated: true, completion: nil)
        }
        updateViewWithState()
    }

    // MARK: - Toolbar Button Actions
    @objc func bottomLeftButtonAction() {
        guard let panel = children.first as? UINavigationController else { return }
        switch viewModel.currentPanelState {
        case .bookmarks(state: let state):
            leftButtonBookmarkActions(for: state, onPanel: panel)
        default:
            return
        }
        updateViewWithState()
    }

    fileprivate func leftButtonBookmarkActions(for state: LibraryPanelSubState, onPanel panel: UINavigationController) {

        switch state {
        case .inFolder:
            if panel.viewControllers.count > 1 {
                viewModel.currentPanelState = .bookmarks(state: .mainView)
                panel.popViewController(animated: true)
            }

        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            bookmarksPanel.addNewBookmarkItemAction()

        case .itemEditMode:
            viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
            panel.popViewController(animated: true)

        default:
            return
        }
    }

    @objc func bottomRightButtonAction() {
        switch viewModel.currentPanelState {
        case .bookmarks(state: let state):
            rightButtonBookmarkActions(for: state)
        default:
            return
        }
        updateViewWithState()
    }

    fileprivate func rightButtonBookmarkActions(for state: LibraryPanelSubState) {
        guard let panel = children.first as? UINavigationController else { return }
        switch state {
        case .inFolder:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
            bookmarksPanel.enableEditMode()

        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            viewModel.currentPanelState = .bookmarks(state: .inFolder)
            bookmarksPanel.disableEditMode()

        case .itemEditMode:
            guard let bookmarkEditView = panel.viewControllers.last as? BookmarkDetailPanel else { return }
            bookmarkEditView.save().uponQueue(.main) { _ in
                self.viewModel.currentPanelState = .bookmarks(state: .inFolderEditMode)
                panel.popViewController(animated: true)
                if bookmarkEditView.isNew,
                   let bookmarksPanel = panel.navigationController?.visibleViewController as? BookmarksPanel {
                    bookmarksPanel.didAddBookmarkNode()
                }
            }
        default:
            return
        }
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
        } else {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        }
        setNeedsStatusBarAppearanceUpdate()
    }
}
