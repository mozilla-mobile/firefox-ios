// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common

protocol TopTabsDelegate: AnyObject {
    func topTabsDidPressTabs()
    func topTabsDidPressNewTab(_ isPrivate: Bool)
    func topTabsDidLongPressNewTab(button: UIButton)
    func topTabsDidChangeTab()
    func topTabsDidPressPrivateMode()
    func topTabsShowCloseTabsToast()
}

class TopTabsViewController: UIViewController, Themeable, Notifiable, FeatureFlaggable {
    private struct UX {
        static let trailingEdgeSpace: CGFloat = 10
        static let topTabsViewHeight: CGFloat = 44
        static let topTabsBackgroundShadowWidth: CGFloat = 12
        static let faderPading: CGFloat = 8
        static let animationSpeed: TimeInterval = 0.1
    }

    // MARK: - Properties
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate?

    private lazy var topTabDisplayManager = TopTabDisplayManager(
        collectionView: collectionView,
        tabManager: tabManager,
        tabDisplayer: self,
        reuseID: TopTabCell.cellIdentifier,
        profile: profile
    )

    var tabCellIdentifier: TabDisplayerDelegate.TabCellIdentifier = TopTabCell.cellIdentifier
    var profile: Profile
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    var currentWindowUUID: UUID? { windowUUID }
    var windowUUID: WindowUUID { tabManager.windowUUID }

    // MARK: - UI Elements
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: TopTabsViewLayout())
        collectionView.register(cellType: TopTabCell.self)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = true
        collectionView.accessibilityIdentifier = AccessibilityIdentifiers.Browser.TopTabs.collectionView
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var tabsButton: TabsButton = .build { button in
        button.semanticContentAttribute = .forceLeftToRight
        button.addTarget(self, action: #selector(TopTabsViewController.tabsTrayTapped), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.tabsButton
        button.showsLargeContentViewer = true
    }

    private lazy var newTab: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus), for: .normal)
        button.semanticContentAttribute = .forceLeftToRight
        button.addTarget(self, action: #selector(TopTabsViewController.newTabTapped), for: .touchUpInside)
        if self.featureFlags.isFeatureEnabled(.toolbarOneTapNewTab, checking: .buildOnly) &&
           self.featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly) {
            let longPressRecognizer = UILongPressGestureRecognizer(
                target: self,
                action: #selector(TopTabsViewController.newTabLongPressed)
            )
            button.addGestureRecognizer(longPressRecognizer)
        }
        button.accessibilityIdentifier = AccessibilityIdentifiers.Toolbar.addNewTabButton
        button.accessibilityLabel = .AddTabAccessibilityLabel
        button.showsLargeContentViewer = true
        button.largeContentTitle = .AddTabAccessibilityLabel
    }

    lazy var privateModeButton: PrivateModeButton = {
        let privateModeButton = PrivateModeButton()
        privateModeButton.semanticContentAttribute = .forceLeftToRight
        privateModeButton.accessibilityIdentifier = AccessibilityIdentifiers.Browser.TopTabs.privateModeButton
        privateModeButton.addTarget(
            self,
            action: #selector(TopTabsViewController.togglePrivateModeTapped),
            for: .touchUpInside
        )
        privateModeButton.translatesAutoresizingMaskIntoConstraints = false
        privateModeButton.showsLargeContentViewer = true
        return privateModeButton
    }()

    private lazy var tabLayoutDelegate: TopTabsLayoutDelegate = {
        let delegate = TopTabsLayoutDelegate()
        delegate.scrollViewDelegate = self
        delegate.tabSelectionDelegate = topTabDisplayManager
        return delegate
    }()

    private lazy var topTabFader: TopTabFader = {
        let fader = TopTabFader()
        fader.semanticContentAttribute = .forceLeftToRight
        fader.translatesAutoresizingMaskIntoConstraints = false

        return fader
    }()

    // MARK: - Inits
    init(tabManager: TabManager,
         profile: Profile,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.tabManager = tabManager
        self.profile = profile
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        collectionView.dataSource = topTabDisplayManager
        collectionView.delegate = tabLayoutDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        refreshTabs()
    }

    func refreshTabs() {
        topTabDisplayManager.refreshStore(forceReload: true)
    }

    deinit {
        tabManager.removeDelegate(self.topTabDisplayManager, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dragDelegate = topTabDisplayManager
        collectionView.dropDelegate = topTabDisplayManager

        listenForThemeChange(view)
        setupLayout()

        setupNotifications(forObserver: self,
                           observing: [.TabsTrayDidClose])

        // Setup UIDropInteraction to handle dragging and dropping
        // links onto the "New Tab" button.
        let dropInteraction = UIDropInteraction(delegate: topTabDisplayManager)
        newTab.addInteraction(dropInteraction)

        let uiLargeContentViewInteraction = UILargeContentViewerInteraction()
        view.addInteraction(uiLargeContentViewInteraction)

        tabsButton.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        applyUIMode(
            isPrivate: tabManager.selectedTab?.isPrivate ?? false,
            theme: themeManager.getCurrentTheme(for: windowUUID)
        )

        updateTabCount(topTabDisplayManager.dataStore.count, animated: false)
    }

    func applyTheme() {
        let currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        let colors = currentTheme.colors

        view.backgroundColor = colors.layer3
        tabsButton.applyTheme(theme: currentTheme)
        privateModeButton.applyTheme(theme: currentTheme)
        newTab.tintColor = colors.iconPrimary
        collectionView.backgroundColor = view.backgroundColor
        collectionView.reloadData()
        topTabDisplayManager.refreshStore()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UserDefaults.standard.set(tabManager.selectedTab?.isPrivate ?? false,
                                  forKey: PrefsKeys.LastSessionWasPrivate)
    }

    func updateTabCount(_ count: Int, animated: Bool = true) {
        tabsButton.updateTabCount(count, animated: animated)
    }

    @objc
    func tabsTrayTapped() {
        topTabDisplayManager.refreshStore(forceReload: true)
        delegate?.topTabsDidPressTabs()
    }

    @objc
    func newTabTapped() {
        delegate?.topTabsDidPressNewTab(self.topTabDisplayManager.isPrivate)
        store.dispatch(TopTabsAction(windowUUID: windowUUID, actionType: TopTabsActionType.didTapNewTab))
    }

    @objc
    func newTabLongPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            delegate?.topTabsDidLongPressNewTab(button: newTab)
        }
    }

    @objc
    func togglePrivateModeTapped() {
        delegate?.topTabsDidPressPrivateMode()
        topTabDisplayManager.togglePrivateMode(isOn: !topTabDisplayManager.isPrivate,
                                               createTabOnEmptyPrivateMode: true,
                                               shouldSelectMostRecentTab: true)
        self.privateModeButton.setSelected(topTabDisplayManager.isPrivate, animated: true)
    }

    func scrollToCurrentTab(_ animated: Bool = true, centerCell: Bool = false) {
        guard let currentTab = tabManager.selectedTab,
              let index = topTabDisplayManager.dataStore.index(of: currentTab),
              !collectionView.frame.isEmpty
        else { return }

        ensureMainThread { [self] in
            if let frame = collectionView.layoutAttributesForItem(
                at: IndexPath(row: index, section: 0)
            )?.frame {
                if centerCell {
                    collectionView.scrollToItem(
                        at: IndexPath(item: index, section: 0),
                        at: .centeredHorizontally,
                        animated: false
                    )
                } else {
                    // Padding is added to ensure the tab is completely visible (none of the tab is under the fader)
                    let padFrame = frame.insetBy(
                        dx: -(UX.topTabsBackgroundShadowWidth+UX.faderPading),
                        dy: 0
                    )
                    if animated {
                        UIView.animate(withDuration: UX.animationSpeed, animations: {
                            self.collectionView.scrollRectToVisible(padFrame, animated: true)
                        })
                    } else {
                        collectionView.scrollRectToVisible(padFrame, animated: false)
                    }
                }
            }
        }
    }

    private func setupLayout() {
        view.addSubview(topTabFader)
        topTabFader.addSubview(collectionView)

        let isToolbarRefactorEnabled = featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)
        if !isToolbarRefactorEnabled {
            view.addSubview(tabsButton)
        }

        view.addSubview(newTab)
        view.addSubview(privateModeButton)

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: UX.topTabsViewHeight),

            newTab.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            newTab.widthAnchor.constraint(equalTo: view.heightAnchor),
            newTab.heightAnchor.constraint(equalTo: view.heightAnchor),

            privateModeButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            privateModeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            privateModeButton.widthAnchor.constraint(equalTo: view.heightAnchor),
            privateModeButton.heightAnchor.constraint(equalTo: view.heightAnchor),

            topTabFader.topAnchor.constraint(equalTo: view.topAnchor),
            topTabFader.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            topTabFader.leadingAnchor.constraint(equalTo: privateModeButton.trailingAnchor),
            topTabFader.trailingAnchor.constraint(equalTo: newTab.leadingAnchor),

            collectionView.topAnchor.constraint(equalTo: topTabFader.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: topTabFader.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: topTabFader.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: topTabFader.trailingAnchor),
        ])

        if isToolbarRefactorEnabled {
            newTab.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                             constant: -UX.trailingEdgeSpace).isActive = true
        } else {
            NSLayoutConstraint.activate([
                newTab.trailingAnchor.constraint(equalTo: tabsButton.leadingAnchor),

                tabsButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                tabsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.trailingEdgeSpace),
                tabsButton.widthAnchor.constraint(equalTo: view.heightAnchor),
                tabsButton.heightAnchor.constraint(equalTo: view.heightAnchor),
            ])
        }
    }

    private func handleFadeOutAfterTabSelection() {
        guard let currentTab = tabManager.selectedTab,
              let index = topTabDisplayManager.dataStore.index(of: currentTab),
              !collectionView.frame.isEmpty
        else { return }

        // Check whether first or last tab is being selected.
        if index == 0 {
            topTabFader.setFader(forSides: .right)
        } else if index == topTabDisplayManager.dataStore.count - 1 {
            topTabFader.setFader(forSides: .left)
        } else if collectionView.contentSize.width <= collectionView.frame.size.width { // all tabs are visible
            topTabFader.setFader(forSides: .none)
        }
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .TabsTrayDidClose:
            guard windowUUID == notification.windowUUID else { return }
            refreshTabs()
        default:
            break
        }
    }
}

extension TopTabsViewController: TabDisplayerDelegate {
    func focusSelectedTab() {
        self.scrollToCurrentTab(true)
        self.handleFadeOutAfterTabSelection()
    }

    func cellFactory(for cell: UICollectionViewCell, using tab: Tab) -> UICollectionViewCell {
        guard let tabCell = cell as? TopTabCell else { return UICollectionViewCell() }
        tabCell.delegate = self
        let isSelected = (tab == tabManager.selectedTab)
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        tabCell.configureLegacyCellWith(tab: tab,
                                        isSelected: isSelected,
                                        theme: theme)
        // Not all cells are visible when the appearance changes. Let's make sure
        // the cell has the proper theme when recycled.
        tabCell.applyTheme(theme: theme)
        return tabCell
    }
}

extension TopTabsViewController: TopTabCellDelegate {
    func tabCellDidClose(_ cell: UICollectionViewCell) {
        topTabDisplayManager.closeActionPerformed(forCell: cell)
        delegate?.topTabsShowCloseTabsToast()
        NotificationCenter.default.post(name: .TopTabsTabClosed, object: nil, userInfo: windowUUID.userInfo)
        store.dispatch(TopTabsAction(windowUUID: windowUUID, actionType: TopTabsActionType.didTapCloseTab))
    }
}

extension TopTabsViewController: PrivateModeUI {
    func applyUIMode(isPrivate: Bool, theme: Theme) {
        // TODO: [FXIOS-8907] Ideally we shouldn't create tabs as a side-effect of UI theme updates. Investigate refactor.
        topTabDisplayManager.togglePrivateMode(isOn: isPrivate, createTabOnEmptyPrivateMode: true)

        privateModeButton.applyTheme(theme: theme)
        privateModeButton.applyUIMode(isPrivate: topTabDisplayManager.isPrivate, theme: theme)
    }
}

// MARK: TopTabsScrollDelegate
extension TopTabsViewController: TopTabsScrollDelegate {
    // disable / enable TopTabFader dynamically based on visible tabs
    func collectionViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let scrollViewWidth = scrollView.frame.size.width
        let scrollViewContentSize = scrollView.contentSize.width

        let reachedLeftEnd = offsetX == 0
        let reachedRightEnd = (scrollViewContentSize - offsetX) == scrollViewWidth

        if reachedLeftEnd {
            topTabFader.setFader(forSides: .right)
        } else if reachedRightEnd {
            topTabFader.setFader(forSides: .left)
        } else {
            topTabFader.setFader(forSides: .both)
        }
    }
}
