// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage
import WebKit

struct TopTabsUX {
    static let TopTabsViewHeight: CGFloat = 44
    static let TopTabsBackgroundShadowWidth: CGFloat = 12
    static let MinTabWidth: CGFloat = 76
    static let MaxTabWidth: CGFloat = 220
    static let FaderPading: CGFloat = 8
    static let SeparatorWidth: CGFloat = 1
    static let TabNudge: CGFloat = 1 // Nudge the favicon and close button by 1px
    static let TabTitlePadding: CGFloat = 10
    static let AnimationSpeed: TimeInterval = 0.1
    static let SeparatorYOffset: CGFloat = 7
    static let SeparatorHeight: CGFloat = 32
    static let TabCornerRadius: CGFloat = 8
}

protocol TopTabsDelegate: AnyObject {
    func topTabsDidPressTabs()
    func topTabsDidPressNewTab(_ isPrivate: Bool)
    func topTabsDidTogglePrivateMode()
    func topTabsDidChangeTab()
}

class TopTabsViewController: UIViewController {

    // MARK: - Properties
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate?
    fileprivate var topTabDisplayManager: TabDisplayManager!
    var tabCellIdentifer: TabDisplayer.TabCellIdentifer = TopTabCell.cellIdentifier
    var profile: Profile

    // MARK: - UI ELements
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: TopTabsViewLayout())
        collectionView.register(cellType: TopTabCell.self)
        collectionView.register(cellType: InactiveTabCell.self)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = true
        collectionView.accessibilityIdentifier = "Top Tabs View"
        collectionView.semanticContentAttribute = .forceLeftToRight
        return collectionView
    }()

    fileprivate lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.semanticContentAttribute = .forceLeftToRight
        tabsButton.addTarget(self, action: #selector(TopTabsViewController.tabsTrayTapped), for: .touchUpInside)
        tabsButton.accessibilityIdentifier = "TopTabsViewController.tabsButton"
        tabsButton.inTopTabs = true
        return tabsButton
    }()

    fileprivate lazy var newTab: UIButton = {
        let newTab = UIButton.newTabButton()
        newTab.semanticContentAttribute = .forceLeftToRight
        newTab.addTarget(self, action: #selector(TopTabsViewController.newTabTapped), for: .touchUpInside)
        newTab.accessibilityIdentifier = "TopTabsViewController.newTabButton"
        return newTab
    }()

    lazy var privateModeButton: PrivateModeButton = {
        let privateModeButton = PrivateModeButton()
        privateModeButton.semanticContentAttribute = .forceLeftToRight
        privateModeButton.accessibilityIdentifier = "TopTabsViewController.privateModeButton"
        privateModeButton.addTarget(self, action: #selector(TopTabsViewController.togglePrivateModeTapped), for: .touchUpInside)
        return privateModeButton
    }()

    fileprivate lazy var tabLayoutDelegate: TopTabsLayoutDelegate = {
        let delegate = TopTabsLayoutDelegate()
        delegate.scrollViewDelegate = self
        delegate.tabSelectionDelegate = topTabDisplayManager
        return delegate
    }()

    private lazy var topTabFader: TopTabFader = {
        let fader = TopTabFader()
        fader.semanticContentAttribute = .forceLeftToRight

        return fader
    }()

    // MARK: - Inits
    init(tabManager: TabManager, profile: Profile) {
        self.tabManager = tabManager
        self.profile = profile
        super.init(nibName: nil, bundle: nil)

        topTabDisplayManager = TabDisplayManager(collectionView: self.collectionView,
                                                 tabManager: self.tabManager,
                                                 tabDisplayer: self,
                                                 reuseID: TopTabCell.cellIdentifier,
                                                 tabDisplayType: .TopTabTray,
                                                 profile: profile)
        collectionView.dataSource = topTabDisplayManager
        collectionView.delegate = tabLayoutDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        topTabDisplayManager.tabDisplayType = .TopTabTray
        refreshTabs()
    }

    func refreshTabs() {
        topTabDisplayManager.refreshStore(evenIfHidden: true)
    }

    deinit {
        tabManager.removeDelegate(self.topTabDisplayManager)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dragDelegate = topTabDisplayManager
        collectionView.dropDelegate = topTabDisplayManager

        view.addSubview(topTabFader)
        topTabFader.addSubview(collectionView)
        view.addSubview(tabsButton)
        view.addSubview(newTab)
        view.addSubview(privateModeButton)

        // Setup UIDropInteraction to handle dragging and dropping
        // links onto the "New Tab" button.
        let dropInteraction = UIDropInteraction(delegate: topTabDisplayManager)
        newTab.addInteraction(dropInteraction)

        view.snp.makeConstraints { make in
            make.height.equalTo(TopTabsUX.TopTabsViewHeight)
        }

        newTab.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(tabsButton.snp.leading)
            make.size.equalTo(view.snp.height)
        }
        tabsButton.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(view).offset(-10)
            make.size.equalTo(view.snp.height)
        }
        privateModeButton.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.leading.equalTo(view).offset(10)
            make.size.equalTo(view.snp.height)
        }
        topTabFader.snp.makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.leading.equalTo(privateModeButton.snp.trailing)
            make.trailing.equalTo(newTab.snp.leading)
        }
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(topTabFader)
        }

        tabsButton.applyTheme()
        applyUIMode(isPrivate: tabManager.selectedTab?.isPrivate ?? false)

        updateTabCount(topTabDisplayManager.dataStore.count, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UserDefaults.standard.set(tabManager.selectedTab?.isPrivate ?? false, forKey: "wasLastSessionPrivate")
    }

    func switchForegroundStatus(isInForeground reveal: Bool) {
        // Called when the app leaves the foreground to make sure no information is inadvertently revealed
        if let cells = self.collectionView.visibleCells as? [TopTabCell] {
            let alpha: CGFloat = reveal ? 1 : 0
            for cell in cells {
                cell.titleText.alpha = alpha
                cell.favicon.alpha = alpha
            }
        }
    }

    func updateTabCount(_ count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }

    @objc func tabsTrayTapped() {
        self.topTabDisplayManager.refreshStore(evenIfHidden: true)
        delegate?.topTabsDidPressTabs()
    }

    @objc func newTabTapped() {
        self.delegate?.topTabsDidPressNewTab(self.topTabDisplayManager.isPrivate)
    }

    @objc func togglePrivateModeTapped() {
        topTabDisplayManager.togglePrivateMode(isOn: !topTabDisplayManager.isPrivate, createTabOnEmptyPrivateMode: true)
        delegate?.topTabsDidTogglePrivateMode()
        self.privateModeButton.setSelected(topTabDisplayManager.isPrivate, animated: true)
    }

    func scrollToCurrentTab(_ animated: Bool = true, centerCell: Bool = false) {
        assertIsMainThread("Only animate on the main thread")

        guard let currentTab = tabManager.selectedTab, let index = topTabDisplayManager.dataStore.index(of: currentTab), !collectionView.frame.isEmpty else {
            return
        }
        if let frame = collectionView.layoutAttributesForItem(at: IndexPath(row: index, section: 0))?.frame {
            if centerCell {
                collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
            } else {
                // Padding is added to ensure the tab is completely visible (none of the tab is under the fader)
                let padFrame = frame.insetBy(dx: -(TopTabsUX.TopTabsBackgroundShadowWidth+TopTabsUX.FaderPading), dy: 0)
                if animated {
                    UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: {
                        self.collectionView.scrollRectToVisible(padFrame, animated: true)
                    })
                } else {
                    collectionView.scrollRectToVisible(padFrame, animated: false)
                }
            }
        }
    }

    private func handleFadeOutAfterTabSelection() {
        guard let currentTab = tabManager.selectedTab, let index = topTabDisplayManager.dataStore.index(of: currentTab), !collectionView.frame.isEmpty else {
            return
        }

        // Check wether first or last tab is being selected.
        if index == 0 {
            topTabFader.setFader(forSides: .right)

        } else if index == topTabDisplayManager.dataStore.count - 1 {
            topTabFader.setFader(forSides: .left)

        } else if collectionView.contentSize.width <= collectionView.frame.size.width { // all tabs are visible
            topTabFader.setFader(forSides: .none)
        }
    }
}

extension TopTabsViewController: TabDisplayer {

    func focusSelectedTab() {
        self.scrollToCurrentTab(true)
        self.handleFadeOutAfterTabSelection()
    }

    func cellFactory(for cell: UICollectionViewCell, using tab: Tab) -> UICollectionViewCell {
        guard let tabCell = cell as? TopTabCell else { return UICollectionViewCell() }
        tabCell.delegate = self
        let isSelected = (tab == tabManager.selectedTab)
        tabCell.configureWith(tab: tab, isSelected: isSelected)
        // Not all cells are visible when the appearance changes. Let's make sure
        // the cell has the proper theme when recycled.
        tabCell.applyTheme()
        return tabCell
    }
}

extension TopTabsViewController: TopTabCellDelegate {
    func tabCellDidClose(_ cell: UICollectionViewCell) {
        topTabDisplayManager.closeActionPerformed(forCell: cell)
        NotificationCenter.default.post(name: .TabClosed, object: nil)
    }
}

extension TopTabsViewController: NotificationThemeable, PrivateModeUI {
    func applyUIMode(isPrivate: Bool) {
        topTabDisplayManager.togglePrivateMode(isOn: isPrivate, createTabOnEmptyPrivateMode: true)

        privateModeButton.onTint = UIColor.theme.topTabs.privateModeButtonOnTint
        privateModeButton.offTint = UIColor.theme.topTabs.privateModeButtonOffTint
        privateModeButton.applyUIMode(isPrivate: topTabDisplayManager.isPrivate)
    }

    func applyTheme() {
        view.backgroundColor = UIColor.theme.topTabs.background
        tabsButton.applyTheme()
        privateModeButton.onTint = UIColor.theme.topTabs.privateModeButtonOnTint
        privateModeButton.offTint = UIColor.theme.topTabs.privateModeButtonOffTint
        privateModeButton.applyTheme()
        newTab.tintColor = UIColor.theme.topTabs.buttonTint
        collectionView.backgroundColor = view.backgroundColor
        (collectionView.visibleCells as? [TopTabCell])?.forEach { $0.applyTheme() }
        topTabDisplayManager.refreshStore()
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

// MARK: Functions for testing
extension TopTabsViewController {
    func test_getDisplayManager() -> TabDisplayManager {
        assert(AppConstants.IsRunningTest)
        return topTabDisplayManager
    }
}

