/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SnapKit
import UIKit
import Storage

private enum LibraryViewControllerUX {
    // Height of the top panel switcher button toolbar.
    static let ButtonContainerHeight: CGFloat = 50
}

extension LibraryViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

class LibraryViewController: UIViewController {

    let profile: Profile
    let panelDescriptors: [LibraryPanelDescriptor]
    // Delegate
    weak var delegate: LibraryPanelDelegate?
    // Variables
    fileprivate var panelState = LibraryPanelViewState()
    var onViewDismissed: (() -> Void)? = nil
    // Views
    fileprivate var controllerContainerView = UIView()
    fileprivate var titleContainerView = UIView()
    fileprivate var bottomBorder = UIView()
    fileprivate var buttons: [LibraryPanelButton] = []
    // Colors
    fileprivate var buttonTintColor: UIColor?
    fileprivate var buttonSelectedTintColor: UIColor?

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
        return librarySegmentControl
    }()

    lazy var navigationToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: librarySegmentControl)], animated: false)

        return toolbar
    }()

    fileprivate lazy var topLeftButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed("goBack"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(topLeftButtonAction))
        button.accessibilityIdentifier = "libraryPanelTopLeftButton"
        return button
    }()

    fileprivate lazy var topRightButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(title: String.AppSettingsDone,
                                     style: .done,
                                     target: self,
                                     action: #selector(topRightButtonAction))
        button.accessibilityIdentifier = "libraryPanelTopRightButton"
        return button
    }()

    fileprivate lazy var bottomLeftButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed("nav-add"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(bottomLeftButtonAction))
        button.accessibilityIdentifier = "libraryPanelBottomLeftButton"
        return button
    }()

    fileprivate lazy var bottomRightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: Strings.BookmarksEdit,
                                     style: .plain,
                                     target: self,
                                     action: #selector(bottomRightButtonAction))
        button.accessibilityIdentifier = "bookmarksPanelBottomRightButton"
        return button
    }()

    lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                               target: nil,
                               action: nil)
    }()

    fileprivate lazy var bottomToolbarItemsBothButtons: [UIBarButtonItem] = {
        return [bottomLeftButton, flexibleSpace, bottomRightButton]
    }()

    fileprivate lazy var bottomToolbarItemsSingleButton: [UIBarButtonItem] = {
        return [flexibleSpace, bottomRightButton]
    }()

    // MARK: - Initializers
    init(profile: Profile) {
        self.profile = profile

        self.panelDescriptors = LibraryPanels(profile: profile).enabledPanels

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViewWithState()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor =  UIColor.theme.homePanel.panelBackground
        view.addSubview(controllerContainerView)

        setToolbarItems(bottomToolbarItemsSingleButton, animated: false)
        navigationItem.rightBarButtonItem = topRightButton

        view.addSubview(navigationToolbar)
        navigationToolbar.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.top.equalTo(view.safeArea.top)
        }

        librarySegmentControl.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(343)
            make.height.equalTo(ChronologicalTabsControllerUX.navigationMenuHeight)
        }

        controllerContainerView.snp.makeConstraints { make in
            make.top.equalTo(navigationToolbar.snp.bottom)
            make.bottom.equalTo(view.snp.bottom)
            make.leading.trailing.equalTo(view)
        }

        if selectedPanel == nil {
            selectedPanel = .bookmarks
        }
        
        applyTheme()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.instance.currentName == .dark ? .lightContent : .default
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

    private func shouldShowBottomToolbar() {
        switch panelState.currentState {
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

                if index < panelDescriptors.count {
                    panelDescriptors[index].setup()
                    if let panel = self.panelDescriptors[index].viewController,
                       let navigationController = self.panelDescriptors[index].navigationController {
                        let accessibilityLabel = self.panelDescriptors[index].accessibilityLabel
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
        libraryPanel.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        libraryPanel.didMove(toParent: self)
        updateTitle()
    }

    fileprivate func updatePanelState() {
        guard let panel = children.first as? UINavigationController else { return }

        if selectedPanel == .bookmarks {
            if panel.viewControllers.count > 1 {
                if panelState.currentState == .bookmarks(state: .mainView) {
                    panelState.currentState = .bookmarks(state: .inFolder)
                } else if panelState.currentState == .bookmarks(state: .inFolderEditMode),
                     let _ = panel.viewControllers.last as? BookmarkDetailPanel {
                    panelState.currentState = .bookmarks(state: .itemEditMode)
                }
            } else {
                panelState.currentState = .bookmarks(state: .mainView)
            }

        } else if selectedPanel == .history {
            if panel.viewControllers.count > 1 {
                if panelState.currentState == .history(state: .mainView) {
                    panelState.currentState = .history(state: .inFolder)
                }
            } else {
                panelState.currentState = .history(state: .mainView)
            }
        }
    }

    fileprivate func updateStateOnShowPanel(to panelType: LibraryPanelType?) {
        switch panelType {
        case .bookmarks:
            panelState.currentState = .bookmarks(state: .mainView)
        case .downloads:
            panelState.currentState = .downloads
        case .history:
            panelState.currentState = .history(state: .mainView)
        case .readingList:
            panelState.currentState = .readingList
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
        switch panelState.currentState {
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
        switch panelState.currentState {
        case .bookmarks(state: .inFolderEditMode):
            navigationItem.rightBarButtonItem = nil
        case .bookmarks(state: .itemEditMode):
            topRightButton.title = Strings.SettingsAddCustomEngineSaveButtonText
            navigationItem.rightBarButtonItem = topRightButton
        default:
            topRightButton.title = String.AppSettingsDone
            navigationItem.rightBarButtonItem = topRightButton
        }
    }

    fileprivate func bottomToolbarButtonSetup() {
        switch panelState.currentState {
        case .bookmarks(state: .inFolderEditMode):
            setToolbarItems(bottomToolbarItemsBothButtons, animated: true)
        default:
            setToolbarItems(bottomToolbarItemsSingleButton, animated: false)
        }
    }

    fileprivate func bottomRightButtonSetup() {
        switch panelState.currentState {
        case .bookmarks(state: let subState):
            if subState == .inFolder {
                bottomRightButton.title = Strings.BookmarksEdit
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
        switch panelState.currentState {
        case .bookmarks(state: let subState):
            leftButtonBookmarkActions(for: subState, onPanel: panel)
        default:
            panel.popViewController(animated: true)
        }
        updateViewWithState()
    }


    @objc func topRightButtonAction() {
        switch panelState.currentState {
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
        switch panelState.currentState {
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
                panelState.currentState = .bookmarks(state: .mainView)
                panel.popViewController(animated: true)
            }

        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            bookmarksPanel.addNewBookmarkItemAction()

        case .itemEditMode:
            panelState.currentState = .bookmarks(state: .inFolderEditMode)
            panel.popViewController(animated: true)

        default:
            return
        }
    }

    @objc func bottomRightButtonAction() {
        switch panelState.currentState {
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
            panelState.currentState = .bookmarks(state: .inFolderEditMode)
            bookmarksPanel.enableEditMode()

        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            panelState.currentState = .bookmarks(state: .inFolder)
            bookmarksPanel.disableEditMode()

        case .itemEditMode:
            guard let bookmarkEditView = panel.viewControllers.last as? BookmarkDetailPanel else { return }
            bookmarkEditView.save().uponQueue(.main) { _ in
                self.panelState.currentState = .bookmarks(state: .inFolderEditMode)
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
extension LibraryViewController: Themeable {
    func applyTheme() {
        panelDescriptors.forEach { item in
            (item.viewController as? Themeable)?.applyTheme()
        }
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = ThemeManager.instance.userInterfaceStyle
            librarySegmentControl.tintColor = .white
        } else {
            librarySegmentControl.tintColor = UIColor.theme.tabTray.tabTitleText
        }
        
        bottomBorder.backgroundColor = UIColor.theme.tableView.separator
        view.backgroundColor =  UIColor.theme.homePanel.panelBackground
        buttonTintColor = UIColor.theme.homePanel.toolbarTint
        buttonSelectedTintColor = UIColor.theme.homePanel.toolbarHighlight
        navigationController?.navigationBar.barTintColor = UIColor.theme.tabTray.toolbar
        navigationController?.navigationBar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
        navigationController?.toolbar.barTintColor = UIColor.theme.tabTray.toolbar
        navigationController?.toolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
        navigationToolbar.barTintColor = UIColor.theme.tabTray.toolbar
        navigationToolbar.tintColor = UIColor.theme.tabTray.toolbarButtonTint
    }
}
