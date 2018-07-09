/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import WebKit

struct TopTabsUX {
    static let TopTabsViewHeight: CGFloat = 44
    static let TopTabsBackgroundShadowWidth: CGFloat = 12
    static let TabWidth: CGFloat = 190
    static let FaderPading: CGFloat = 8
    static let SeparatorWidth: CGFloat = 1
    static let HighlightLineWidth: CGFloat = 3
    static let TabNudge: CGFloat = 1 // Nudge the favicon and close button by 1px
    static let TabTitlePadding: CGFloat = 10
    static let AnimationSpeed: TimeInterval = 0.1
    static let SeparatorYOffset: CGFloat = 7
    static let SeparatorHeight: CGFloat = 32
}

protocol TopTabsDelegate: class {
    func topTabsDidPressTabs()
    func topTabsDidPressNewTab(_ isPrivate: Bool)
    func topTabsDidTogglePrivateMode()
    func topTabsDidChangeTab()
}


class TopTabsViewController: UIViewController {
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate?
    fileprivate var tabDisplayManager: TabDisplayManager!

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: TopTabsViewLayout())
        collectionView.register(TopTabCell.self, forCellWithReuseIdentifier: TopTabCell.Identifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = false
        collectionView.accessibilityIdentifier = "Top Tabs View"
        collectionView.semanticContentAttribute = .forceLeftToRight
        return collectionView
    }()

    fileprivate lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.semanticContentAttribute = .forceLeftToRight
        tabsButton.addTarget(self, action: #selector(TopTabsViewController.tabsTrayTapped), for: .touchUpInside)
        tabsButton.accessibilityIdentifier = "TopTabsViewController.tabsButton"
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
        delegate.tabSelectionDelegate = tabDisplayManager
        return delegate
    }()

    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
        let focusTab: () -> Void = {
            self.scrollToCurrentTab(true, centerCell: true)
        }
        tabDisplayManager = TabDisplayManager(collectionView: self.collectionView, tabManager: self.tabManager, selectTab: focusTab)
        collectionView.dataSource = tabDisplayManager
        collectionView.delegate = tabLayoutDelegate
        [UICollectionElementKindSectionHeader, UICollectionElementKindSectionFooter].forEach {
            collectionView.register(TopTabsHeaderFooter.self, forSupplementaryViewOfKind: $0, withReuseIdentifier: "HeaderFooter")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabDisplayManager.performTabUpdates()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            collectionView.dragDelegate = tabDisplayManager
            collectionView.dropDelegate = tabDisplayManager
        }

        let topTabFader = TopTabFader()
        topTabFader.semanticContentAttribute = .forceLeftToRight

        view.addSubview(topTabFader)
        topTabFader.addSubview(collectionView)
        view.addSubview(tabsButton)
        view.addSubview(newTab)
        view.addSubview(privateModeButton)

        // Setup UIDropInteraction to handle dragging and dropping
        // links onto the "New Tab" button.
        if #available(iOS 11, *) {
            let dropInteraction = UIDropInteraction(delegate: tabDisplayManager)
            newTab.addInteraction(dropInteraction)
        }

        newTab.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(tabsButton.snp.leading).offset(-10)
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

        view.backgroundColor = UIColor.Photon.Grey80
        tabsButton.applyTheme()
        applyUIMode(isPrivate: tabManager.selectedTab?.isPrivate ?? false)

        updateTabCount(tabDisplayManager.tabCount, animated: false)
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
        delegate?.topTabsDidPressTabs()
    }

    @objc func newTabTapped() {
        if tabDisplayManager.pendingReloadData {
            return
        }
        self.delegate?.topTabsDidPressNewTab(self.tabDisplayManager.isPrivate)
        LeanPlumClient.shared.track(event: .openedNewTab, withParameters: ["Source": "Add tab button in the URL Bar on iPad"])
    }

    @objc func togglePrivateModeTapped() {
        let currentMode = tabDisplayManager.isPrivate

        tabDisplayManager.togglePBM()
        if currentMode != tabDisplayManager.isPrivate {
            delegate?.topTabsDidTogglePrivateMode()
        }
        self.privateModeButton.setSelected(tabDisplayManager.isPrivate, animated: true)
    }

    func scrollToCurrentTab(_ animated: Bool = true, centerCell: Bool = false) {
        assertIsMainThread("Only animate on the main thread")

        guard let currentTab = tabManager.selectedTab, let index = tabDisplayManager.tabStore.index(of: currentTab), !collectionView.frame.isEmpty else {
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

    func reloadData() {
        tabDisplayManager.reloadData()
    }
}

extension TopTabsViewController: Themeable, PrivateModeUI {
    func applyUIMode(isPrivate: Bool) {
        tabDisplayManager.isPrivate = isPrivate

        privateModeButton.onTint = UIColor.theme.topTabs.privateModeButtonOnTint
        privateModeButton.offTint = UIColor.theme.topTabs.privateModeButtonOffTint
        privateModeButton.applyUIMode(isPrivate: tabDisplayManager.isPrivate)
    }

    func applyTheme() {
        tabsButton.applyTheme()
        newTab.tintColor = UIColor.theme.topTabs.buttonTint
        collectionView.backgroundColor = view.backgroundColor
    }
}

