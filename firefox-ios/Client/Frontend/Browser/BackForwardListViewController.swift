// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import WebKit
import Storage
import Common

private struct BackForwardViewUX {
    static let RowHeight: CGFloat = 50
}

/// Provides information about the size of various BrowserViewController's subviews.
protocol BrowserFrameInfoProvider: AnyObject {
    func getBottomContainerSize() -> CGSize

    func getHeaderSize() -> CGSize

    func getOverKeyboardContainerSize() -> CGSize
}

class BackForwardListViewController: UIViewController,
                                     UITableViewDataSource,
                                     UITableViewDelegate,
                                     UIGestureRecognizerDelegate,
                                     Themeable,
                                     SearchBarLocationProvider {
    private var profile: Profile
    private lazy var sites = [String: Site]()
    private var dismissing = false
    private var currentRow = 0
    private var verticalConstraints: [NSLayoutConstraint] = []
    var tableViewTopAnchor: NSLayoutConstraint?
    var tableViewBottomAnchor: NSLayoutConstraint?
    var tableViewHeightAnchor: NSLayoutConstraint?

    // MARK: - Theme
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    lazy var tableView: UITableView = .build { tableView in
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = false
        tableView.register(BackForwardTableViewCell.self,
                           forCellReuseIdentifier: BackForwardTableViewCell.cellIdentifier)
        tableView.showsHorizontalScrollIndicator = false
    }

    lazy var shadow: UIView = .build { _ in }

    var tabManager: TabManager?
    weak var browserFrameInfoProvider: BrowserFrameInfoProvider?
    var currentItem: WKBackForwardListItem?
    var listData = [WKBackForwardListItem]()
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var tableHeight: CGFloat {
        return min(BackForwardViewUX.RowHeight * CGFloat(listData.count), self.view.frame.height/2)
    }

    var backForwardTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = backForwardTransitionDelegate
        }
    }

    var snappedToBottom = true

    init(profile: Profile,
         windowUUID: WindowUUID,
         backForwardList: WKBackForwardList,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        loadSites(backForwardList)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupLayout()
        applyTheme()
        scrollTableViewToIndex(currentRow)
        setupDismissTap()

        setupNotifications(forObserver: self,
                           observing: [UIAccessibility.reduceTransparencyStatusDidChangeNotification])
    }

    private func setupLayout() {
        view.addSubview(shadow)
        view.addSubview(tableView)

        snappedToBottom = isDisplayedAtBottom(for: traitCollection, isBottomSearchBar: isBottomSearchBar)
        let tableViewHeightAnchor = tableView.heightAnchor.constraint(equalToConstant: 0)
        self.tableViewHeightAnchor = tableViewHeightAnchor

        NSLayoutConstraint.activate([
            tableViewHeightAnchor,
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),

            shadow.leftAnchor.constraint(equalTo: view.leftAnchor),
            shadow.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        remakeVerticalConstraints()
        view.layoutIfNeeded()
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let theme = currentTheme()

        if UIAccessibility.isReduceTransparencyEnabled {
            // Remove the visual effect and the background alpha
            (tableView.backgroundView as? UIVisualEffectView)?.effect = nil
            tableView.backgroundView?.backgroundColor = theme.colors.layer1
            tableView.backgroundColor = theme.colors.layer1
        } else {
            tableView.backgroundColor = .clear
            let blurEffect = UIBlurEffect(style: .regular)
            if let visualEffectView = tableView.backgroundView as? UIVisualEffectView {
                visualEffectView.effect = blurEffect
            } else {
                let blurEffectView = UIVisualEffectView(effect: blurEffect)
                tableView.backgroundView = blurEffectView
            }
            tableView.backgroundView?.backgroundColor = theme.colors.layer1.withAlphaComponent(0.9)
        }

        shadow.backgroundColor = theme.colors.shadowDefault
    }

    func homeAndNormalPagesOnly(_ bfList: WKBackForwardList) {
        let items = bfList.forwardList.reversed() + [bfList.currentItem].compactMap({ $0 }) + bfList.backList.reversed()

        // error url's are OK as they are used to populate history on session restore.
        listData = items.filter {
            guard let internalUrl = InternalURL($0.url) else { return true }
            if internalUrl.isAboutHomeURL {
                return true
            }
            if let url = internalUrl.originalURLFromErrorPage, InternalURL.isValid(url: url) {
                return false
            }
            return true
        }
    }

    func loadSites(_ bfList: WKBackForwardList) {
        currentItem = bfList.currentItem

        homeAndNormalPagesOnly(bfList)
    }

    func scrollTableViewToIndex(_ index: Int) {
        guard index > 1 else { return }
        let moveToIndexPath = IndexPath(row: index-2, section: 0)
        tableView.reloadRows(at: [moveToIndexPath], with: .none)
        tableView.scrollToRow(at: moveToIndexPath, at: .middle, animated: false)
    }

    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.willTransition(to: newCollection, with: coordinator)

        let isDisplayedAtBottom = isDisplayedAtBottom(for: newCollection, isBottomSearchBar: isBottomSearchBar)

        if snappedToBottom != isDisplayedAtBottom {
            snappedToBottom = isDisplayedAtBottom
            let anchor = snappedToBottom ? tableViewTopAnchor : tableViewBottomAnchor
            anchor?.constant = 0
            tableViewHeightAnchor?.constant = 0
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let correctHeight = {
            self.tableViewHeightAnchor?.constant = min(
                BackForwardViewUX.RowHeight * CGFloat(self.listData.count),
                size.height / 2
            )
        }
        coordinator.animate(alongsideTransition: nil) { _ in
            self.remakeVerticalConstraints()
            correctHeight()
        }
    }

    // the back/forward list can be shown at the top or bottom of the screen
    // the position depends on the address bar position and whether the navigation toolbar is shown or not
    private func isDisplayedAtBottom(for traitCollection: UITraitCollection, isBottomSearchBar: Bool) -> Bool {
        let showNavToolbar = ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection)
        return showNavToolbar || isBottomSearchBar
    }

    func remakeVerticalConstraints() {
        guard let browserFrameInfo = browserFrameInfoProvider else { return }
        for constraint in self.verticalConstraints {
            constraint.isActive = false
        }
        self.verticalConstraints = []
        if snappedToBottom {
            let keyboardContainerHeight = browserFrameInfo.getOverKeyboardContainerSize().height
            let toolbarContainerheight = browserFrameInfo.getBottomContainerSize().height
            let offset = keyboardContainerHeight + toolbarContainerheight
            let tableViewBottomAnchor = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -offset)
            self.tableViewBottomAnchor = tableViewBottomAnchor

            let constraints: [NSLayoutConstraint] = [
                tableViewBottomAnchor,
                shadow.bottomAnchor.constraint(equalTo: tableView.topAnchor),
                shadow.topAnchor.constraint(equalTo: view.topAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
            verticalConstraints += constraints
        } else {
            let statusBarHeight = UIWindow.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            let tableViewTopAnchor = tableView.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: browserFrameInfo.getHeaderSize().height + statusBarHeight
            )
            self.tableViewTopAnchor = tableViewTopAnchor

            let constraints: [NSLayoutConstraint] = [
                tableViewTopAnchor,
                shadow.topAnchor.constraint(equalTo: tableView.bottomAnchor),
                shadow.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
            verticalConstraints += constraints
        }
    }

    func setupDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    @objc
    func handleTap() {
        dismiss(animated: true, completion: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: tableView) ?? true {
            return false
        }
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func reduceTransparencyChanged() {
        // If the user toggles transparency settings, re-apply the theme to also toggle the blur effect.
        applyTheme()
    }

    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BackForwardTableViewCell.cellIdentifier,
                                                       for: indexPath) as? BackForwardTableViewCell
        else {
            return UITableViewCell()
        }

        let item = listData[indexPath.item]
        let urlString = { () -> String in
            guard let url = InternalURL(item.url),
                  let extracted = url.extractedUrlParam
            else { return item.url.absoluteString }

            return extracted.absoluteString
        }()

        let isAboutHomeURL = InternalURL(item.url)?.isAboutHomeURL ?? false
        var site: Site
        if isAboutHomeURL {
            site = Site(url: item.url.absoluteString, title: .FirefoxHomePage)
        } else {
            site = sites[urlString] ?? Site(url: urlString, title: item.title ?? "")
        }

        let viewModel = BackForwardCellViewModel(site: site,
                                                 connectingForwards: indexPath.item != 0,
                                                 connectingBackwards: indexPath.item != listData.count-1,
                                                 isCurrentTab: listData[indexPath.item] == currentItem,
                                                 strokeBackgroundColor: currentTheme().colors.iconPrimary)

        cell.configure(viewModel: viewModel, theme: currentTheme())
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tabManager?.selectedTab?.goToBackForwardListItem(listData[indexPath.item])
        dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt  indexPath: IndexPath) -> CGFloat {
        return BackForwardViewUX.RowHeight
    }
}

extension BackForwardListViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIAccessibility.reduceTransparencyStatusDidChangeNotification:
            reduceTransparencyChanged()
        default: break
        }
    }
}
