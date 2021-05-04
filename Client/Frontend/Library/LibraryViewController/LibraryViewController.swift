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

/// This enum describes the different states the Bookmarks panel,
/// in the Library Panel, can have. All other Library Panels do
/// not have states associated with them, allowing this one
/// state to be persisted.
enum BookmarksPanelState {
    case home
    case inFolder
    case inFolderEditMode
    case bookmarkEditMode
}

class LibraryViewController: UIViewController {

    let profile: Profile
    let panelDescriptors: [LibraryPanelDescriptor]
    // Delegate
    weak var delegate: LibraryPanelDelegate?
    // Variables
    fileprivate var bookmarkPanelState: BookmarksPanelState = .home
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
    
    init(profile: Profile) {
        self.profile = profile

        self.panelDescriptors = LibraryPanels(profile: profile).enabledPanels

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViewWithState()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor =  UIColor.theme.homePanel.panelBackground
        bookmarkPanelState = .home
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
            make.width.equalTo(60)
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
                    if let panel = self.panelDescriptors[index].viewController, let navigationController = self.panelDescriptors[index].navigationController {
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

    func updateViewWithState() {
        updateBookmarkPanelState()
        topLeftButtonSetup()
        topRightButtonSetup()
    }

    func updateBookmarkPanelState() {
        if librarySegmentControl.selectedSegmentIndex == 0 {
            if let panel = children.first as? UINavigationController,
               panel.viewControllers.count > 1 {
                if bookmarkPanelState == .home {
                    bookmarkPanelState = .inFolder
                } else if bookmarkPanelState == .inFolderEditMode,
                     let _ = panel.viewControllers.last as? BookmarkDetailPanel {
                    bookmarkPanelState = .bookmarkEditMode
                }
            } else {
                bookmarkPanelState = .home
            }
        }
        children.first?.navigationController?.toolbar.backgroundColor = .red
    }

    func topLeftButtonSetup() {
        switch bookmarkPanelState {
        case .home:
            topLeftButton.isHidden = true
        case .inFolder:
            topLeftButton.isHidden = false
            topLeftButton.setTitle(Strings.BackTitle, for: .normal)
            topLeftButton.setImage(nil, for: .normal)
        case .inFolderEditMode:
            topLeftButton.isHidden = false
            topLeftButton.setTitle("", for: .normal)
            let img = UIImage.templateImageNamed("nav-add")
            topLeftButton.setImage(img, for: .normal)
        case .bookmarkEditMode:
            topLeftButton.isHidden = false
            topLeftButton.setTitle(Strings.CancelString, for: .normal)
            topLeftButton.setImage(nil, for: .normal)
        }
    }

    func topRightButtonSetup() {
        switch bookmarkPanelState {
        case .home:
            topRightButton.setTitle(String.AppSettingsDone, for: .normal)
        case .inFolder:
            topRightButton.setTitle(Strings.BookmarksEdit, for: .normal)
        case .inFolderEditMode:
            topRightButton.setTitle(String.AppSettingsDone, for: .normal)
        case .bookmarkEditMode:
            topRightButton.setTitle(Strings.SettingsAddCustomEngineSaveButtonText, for: .normal)
        }
    }

    @objc func topLeftButtonAction() {
        guard let panel = children.first as? UINavigationController else { return }
        switch bookmarkPanelState {
        case .home:
            return
        case .inFolder:
            if panel.viewControllers.count > 1 {
                bookmarkPanelState = .home
                panel.popViewController(animated: true)
            }
        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            bookmarksPanel.addNewBookmarkItemAction()
        case .bookmarkEditMode:
            bookmarkPanelState = .inFolderEditMode
            panel.popViewController(animated: true)
        }
        updateViewWithState()
    }

    @objc func topRightButtonAction() {
        guard let panel = children.first as? UINavigationController else { return }

        switch bookmarkPanelState {
        case .home:
            self.dismiss(animated: true, completion: nil)
        case .inFolder:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            bookmarkPanelState = .inFolderEditMode
            bookmarksPanel.enableEditMode()
        case .inFolderEditMode:
            guard let bookmarksPanel = panel.viewControllers.last as? BookmarksPanel else { return }
            bookmarkPanelState = .inFolder
            bookmarksPanel.disableEditMode()
        case .bookmarkEditMode:
            guard let bookmarkEditView = panel.viewControllers.last as? BookmarkDetailPanel else { return }
            bookmarkEditView.save().uponQueue(.main) { _ in
                self.bookmarkPanelState = .inFolderEditMode
                panel.popViewController(animated: true)
                if bookmarkEditView.isNew,
                   let bookmarksPanel = panel.navigationController?.visibleViewController as? BookmarksPanel {
                    bookmarksPanel.didAddBookmarkNode()
                }
            }
        }
        updateViewWithState()
    }
    
    func setupLibraryPanel(_ panel: UIViewController, accessibilityLabel: String) {
        (panel as? LibraryPanel)?.libraryPanelDelegate = self
        panel.view.accessibilityNavigationStyle = .combined
        panel.view.accessibilityLabel = accessibilityLabel
        panel.title = accessibilityLabel
        panel.navigationController?.setNavigationBarHidden(true, animated: false)
        panel.navigationController?.isNavigationBarHidden = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.instance.currentName == .dark ? .lightContent : .default
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
        addChild(libraryPanel)
        libraryPanel.beginAppearanceTransition(true, animated: false)
        controllerContainerView.addSubview(libraryPanel.view)
        libraryPanel.endAppearanceTransition()
        libraryPanel.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        libraryPanel.didMove(toParent: self)
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
