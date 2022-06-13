// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared
import WebKit
import Storage

private struct BackForwardViewUX {
    static let RowHeight: CGFloat = 50
    static let BackgroundColor = UIColor.Photon.Grey10A40
}

class BackForwardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

    fileprivate let BackForwardListCellIdentifier = "BackForwardListViewController"
    fileprivate var profile: Profile
    fileprivate lazy var sites = [String: Site]()
    fileprivate var dismissing = false
    fileprivate var currentRow = 0
    fileprivate var verticalConstraints: [NSLayoutConstraint] = []
    var tableViewTopAnchor: NSLayoutConstraint!
    var tableViewBottomAnchor: NSLayoutConstraint!
    var tableViewHeightAnchor: NSLayoutConstraint!

    lazy var tableView: UITableView = .build { tableView in
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = false
        tableView.register(BackForwardTableViewCell.self, forCellReuseIdentifier: self.BackForwardListCellIdentifier)
        tableView.backgroundColor = UIColor.theme.tabTray.cellTitleBackground.withAlphaComponent(0.4)
        let blurEffect = UIBlurEffect(style: UIColor.theme.tabTray.tabTitleBlur)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.backgroundView = blurEffectView
        tableView.showsHorizontalScrollIndicator = false
    }

    lazy var shadow: UIView = .build { view in
        view.backgroundColor = UIColor(white: 0, alpha: 0.2)
    }

    var tabManager: TabManager!
    weak var bvc: BrowserViewController?
    var currentItem: WKBackForwardListItem?
    var listData = [WKBackForwardListItem]()

    var tableHeight: CGFloat {
        get {
            assert(Thread.isMainThread, "tableHeight interacts with UIKit components - cannot call from background thread.")
            return min(BackForwardViewUX.RowHeight * CGFloat(listData.count), self.view.frame.height/2)
        }
    }

    var backForwardTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = backForwardTransitionDelegate
        }
    }

    var snappedToBottom: Bool = true

    init(profile: Profile, backForwardList: WKBackForwardList) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)

        loadSites(backForwardList)
        loadSitesFromProfile()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(shadow)
        view.addSubview(tableView)

        let toolBarShouldShow = bvc?.shouldShowToolbarForTraitCollection(traitCollection) ?? false
        let isBottomSearchBar = bvc?.isBottomSearchBar ?? false
        snappedToBottom = toolBarShouldShow || isBottomSearchBar
        tableViewHeightAnchor = tableView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            tableViewHeightAnchor,
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            shadow.leftAnchor.constraint(equalTo: view.leftAnchor),
            shadow.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        remakeVerticalConstraints()
        view.layoutIfNeeded()
        scrollTableViewToIndex(currentRow)
        setupDismissTap()
    }

    func loadSitesFromProfile() {
        let sql = profile.favicons as! SQLiteHistory
        let urls: [String] = listData.compactMap {
            guard let internalUrl = InternalURL($0.url) else {
                return $0.url.absoluteString
            }

            return internalUrl.extractedUrlParam?.absoluteString
        }

        sql.getSites(forURLs: urls).uponQueue(.main) { result in
            guard let results = result.successValue else {
                return
            }
            // Add all results into the sites dictionary
            results.compactMap({$0}).forEach({site in
                if let url = site?.url {
                    self.sites[url] = site
                }
            })
            self.tableView.reloadData()
        }
    }

    func homeAndNormalPagesOnly(_ bfList: WKBackForwardList) {
        let items = bfList.forwardList.reversed() + [bfList.currentItem].compactMap({$0}) + bfList.backList.reversed()

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
        guard index > 1 else {
            return
        }
        let moveToIndexPath = IndexPath(row: index-2, section: 0)
        tableView.reloadRows(at: [moveToIndexPath], with: .none)
        tableView.scrollToRow(at: moveToIndexPath, at: .middle, animated: false)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard let bvc = self.bvc else {
            return
        }
        if bvc.shouldShowToolbarForTraitCollection(newCollection) != snappedToBottom, !bvc.isBottomSearchBar {
            if snappedToBottom {
                tableViewBottomAnchor.constant = 0
            } else {
                tableViewTopAnchor.constant = 0
            }
            tableViewHeightAnchor.constant = 0
            snappedToBottom = !snappedToBottom
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let correctHeight = {
            self.tableViewHeightAnchor.constant = min(BackForwardViewUX.RowHeight * CGFloat(self.listData.count), size.height / 2)
        }
        coordinator.animate(alongsideTransition: nil) { _ in
            self.remakeVerticalConstraints()
            correctHeight()
        }
    }

    func remakeVerticalConstraints() {
        guard let bvc = self.bvc else {
            return
        }
        for constraint in self.verticalConstraints {
            constraint.isActive = false
        }
        self.verticalConstraints = []
        if snappedToBottom {

            let keyboardContainerHeight = bvc.overKeyboardContainer.frame.height
            let toolbarContainerheight = bvc.bottomContainer.frame.height
            let offset = keyboardContainerHeight + toolbarContainerheight
            tableViewBottomAnchor = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -offset)
            let constraints: [NSLayoutConstraint] = [
                tableViewBottomAnchor,
                shadow.bottomAnchor.constraint(equalTo: tableView.topAnchor),
                shadow.topAnchor.constraint(equalTo: view.topAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
            verticalConstraints += constraints

        } else {

            let statusBarHeight = UIWindow.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            tableViewTopAnchor = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: bvc.header.frame.height + statusBarHeight)
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

    @objc func handleTap() {
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

    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: BackForwardListCellIdentifier, for: indexPath) as! BackForwardTableViewCell
        let item = listData[indexPath.item]
        let urlString = { () -> String in
            guard let url = InternalURL(item.url), let extracted = url.extractedUrlParam else {
                return item.url.absoluteString
            }
            return extracted.absoluteString
        }()

        cell.isCurrentTab = listData[indexPath.item] == self.currentItem
        cell.connectingBackwards = indexPath.item != listData.count-1
        cell.connectingForwards = indexPath.item != 0

        let isAboutHomeURL = InternalURL(item.url)?.isAboutHomeURL ?? false
        guard !isAboutHomeURL else {
            cell.site = Site(url: item.url.absoluteString, title: .FirefoxHomePage)
            return cell
        }

        cell.site = sites[urlString] ?? Site(url: urlString, title: item.title ?? "")
        cell.setNeedsDisplay()

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tabManager.selectedTab?.goToBackForwardListItem(listData[indexPath.item])
        dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt  indexPath: IndexPath) -> CGFloat {
        return BackForwardViewUX.RowHeight
    }
}
