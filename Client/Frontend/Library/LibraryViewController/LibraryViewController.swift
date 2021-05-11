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
    // Views
    fileprivate var controllerContainerView = UIView()
    fileprivate var titleContainerView = UIView()
    fileprivate var bottomBorder = UIView()
    fileprivate var buttons: [LibraryPanelButton] = []
    // Colors
    fileprivate var buttonTintColor: UIColor?
    fileprivate var buttonSelectedTintColor: UIColor?
    // Segment Control
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

    fileprivate lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DefaultStandardFontBold
        titleLabel.textColor = UIColor.theme.tabTray.tabTitleText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    fileprivate lazy var topLeftButton: UIButton =  {
        let button = UIButton()
        button.setTitle(Strings.BackTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.titleLabel?.textAlignment = .left
        button.addTarget(self, action: #selector(topLeftButtonAction), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var topRightButton: UIButton =  {
        let button = UIButton()
        button.setTitle(String.AppSettingsDone, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(topRightButtonAction), for: .touchUpInside)
        return button
    }()

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
        self.edgesForExtendedLayout = []
        view.addSubview(controllerContainerView)
        view.addSubview(librarySegmentControl)
        view.addSubview(titleLabel)
        view.addSubview(titleContainerView)
        view.addSubview(bottomBorder)
        view.addSubview(topRightButton)
        var topPadding = 0
        if #available(iOS 13, *) {} else {
            topPadding = 20
        }
        
        titleContainerView.addSubview(titleLabel)
        titleContainerView.addSubview(topLeftButton)
        titleContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(view.snp.top).inset(topPadding)
            make.height.equalTo(58)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleContainerView)
            make.centerY.equalTo(titleContainerView)
            make.height.equalTo(30)
        }
        
        topLeftButton.snp.makeConstraints { make in
            make.leading.equalTo(titleContainerView).offset(20)
            make.centerY.equalTo(titleContainerView)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        
        topRightButton.snp.makeConstraints { make in
            make.trailing.equalTo(titleContainerView).offset(-20)
            make.centerY.equalTo(titleContainerView)
            make.width.equalTo(50)
            make.height.equalTo(30)
        }
        
        librarySegmentControl.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(16)
            make.trailing.equalTo(view).offset(-16)
            make.top.equalTo(titleContainerView.snp.bottom)
        }

        librarySegmentControl.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(343)
            make.height.equalTo(32)
        }
        
        bottomBorder.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(librarySegmentControl.snp.bottom).offset(10)
            make.height.equalTo(1)
        }

        controllerContainerView.snp.makeConstraints { make in
            make.top.equalTo(bottomBorder.snp.bottom)
            make.bottom.equalTo(view.snp.bottom)
            make.leading.trailing.equalTo(view)
        }

        if selectedPanel == nil {
            selectedPanel = .bookmarks
        }
        
        applyTheme()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { return ThemeManager.instance.currentName == .dark ? .lightContent : .default
    }

    func updateViewWithState() {
        updatePanelState()
        topLeftButtonSetup()
        topRightButtonSetup()
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
            titleLabel.text = selectedPanel!.title
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
        libraryPanel.endAppearanceTransition()
        libraryPanel.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        libraryPanel.didMove(toParent: self)
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
        children.first?.navigationController?.toolbar.backgroundColor = .red
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

    // MARK: - Buttons
    fileprivate func topLeftButtonSetup() {
        switch panelState.currentState {
        case .bookmarks(state: .inFolder),
             .history(state: .inFolder):
            topLeftButton.isHidden = false
            topLeftButton.setTitle(Strings.BackTitle, for: .normal)
            topLeftButton.setImage(nil, for: .normal)
        case .bookmarks(state: .inFolderEditMode):
            topLeftButton.isHidden = false
            topLeftButton.setTitle("", for: .normal)
            let img = UIImage.templateImageNamed("nav-add")
            topLeftButton.setImage(img, for: .normal)
        case .bookmarks(state: .itemEditMode):
            topLeftButton.isHidden = false
            topLeftButton.setTitle(Strings.CancelString, for: .normal)
            topLeftButton.setImage(nil, for: .normal)
        default:
            topLeftButton.isHidden = true
        }
    }

    fileprivate func topRightButtonSetup() {
        switch panelState.currentState {
        case .bookmarks(state: .inFolder):
            topRightButton.setTitle(Strings.BookmarksEdit, for: .normal)
        case .bookmarks(state: .inFolderEditMode):
            topRightButton.setTitle(String.AppSettingsDone, for: .normal)
        case .bookmarks(state: .itemEditMode):
            topRightButton.setTitle(Strings.SettingsAddCustomEngineSaveButtonText, for: .normal)
        default:
            topRightButton.setTitle(String.AppSettingsDone, for: .normal)
        }
    }

    // MARK: - Left Button Actions
    @objc func topLeftButtonAction() {
        guard let panel = children.first as? UINavigationController else { return }

        switch panelState.currentState {
        case .bookmarks(state: let state):
            leftButtonBookmarkActions(for: state, onPanel: panel)
        case .history(state: .inFolder):
            panel.popViewController(animated: true)
        default:
            return
        }
        updateViewWithState()
    }

    fileprivate func leftButtonBookmarkActions(for state: LibraryPanelSubState, onPanel panel: UINavigationController) {

        switch state {
        case .mainView:
            return

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
        }
    }

    // MARK: - Right Button Actions
    @objc func topRightButtonAction() {
        switch panelState.currentState {
        case .bookmarks(state: let state):
            rightButtonBookmarkActions(for: state)
        default:
            self.dismiss(animated: true, completion: nil)
        }
        updateViewWithState()
    }

    fileprivate func rightButtonBookmarkActions(for state: LibraryPanelSubState) {
        guard let panel = children.first as? UINavigationController else { return }
        switch state {
        case .mainView:
            self.dismiss(animated: true, completion: nil)

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
        
        titleLabel.textColor = UIColor.theme.tabTray.tabTitleText
        bottomBorder.backgroundColor = UIColor.theme.tableView.separator
        view.backgroundColor =  UIColor.theme.homePanel.panelBackground
        buttonTintColor = UIColor.theme.homePanel.toolbarTint
        buttonSelectedTintColor = UIColor.theme.homePanel.toolbarHighlight
    }
}
