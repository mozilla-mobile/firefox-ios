/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import WebKit
import Storage
import SnapKit

struct BackForwardViewUX {
    static let RowHeight = 50
    static let BackgroundColor = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.4)
    static let BackgroundColorPrivate = UIColor(colorLiteralRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
}

class BackForwardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

    fileprivate let BackForwardListCellIdentifier = "BackForwardListViewController"
    fileprivate var profile: Profile
    fileprivate lazy var sites = [String: Site]()
    fileprivate var isPrivate: Bool
    fileprivate var dismissing = false
    fileprivate var currentRow = 0
    fileprivate var verticalConstraints: [Constraint] = []
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = false
        tableView.register(BackForwardTableViewCell.self, forCellReuseIdentifier: self.BackForwardListCellIdentifier)
        tableView.backgroundColor = self.isPrivate ? BackForwardViewUX.BackgroundColorPrivate:BackForwardViewUX.BackgroundColor
        let blurEffect = UIBlurEffect(style: self.isPrivate ? .dark : .extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.backgroundView = blurEffectView
        
        return tableView
    }()
    
    lazy var shadow: UIView = {
        let shadow = UIView()
        shadow.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.2)
        return shadow
    }()
    
    var tabManager: TabManager!
    weak var bvc: BrowserViewController?
    var currentItem: WKBackForwardListItem?
    var listData = [WKBackForwardListItem]()

    var tableHeight: CGFloat {
        get {
            assert(Thread.isMainThread, "tableHeight interacts with UIKit components - cannot call from background thread.")
            return min(CGFloat(BackForwardViewUX.RowHeight*listData.count), self.view.frame.height/2)
        }
    }
    
    var backForwardTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = backForwardTransitionDelegate
        }
    }
    
    var snappedToBottom: Bool = true
    
    init(profile: Profile, backForwardList: WKBackForwardList, isPrivate: Bool) {
        self.profile = profile
        self.isPrivate = isPrivate
        super.init(nibName: nil, bundle: nil)
        
        loadSites(backForwardList)
        loadSitesFromProfile()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(shadow)
        view.addSubview(tableView)
        self.snappedToBottom = self.bvc?.toolbar != nil
        tableView.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.equalTo(self.view)
        }
        shadow.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
        }
        remakeVerticalConstraints()
        view.layoutIfNeeded()
        scrollTableViewToIndex(currentRow)
        setupDismissTap()
    }
    
    func loadSitesFromProfile() {
        let sql = profile.favicons as! SQLiteHistory
        let urls = self.listData.flatMap {$0.url.isLocal ? $0.url.getQuery()["url"]?.unescape() : $0.url.absoluteString}

        sql.getSitesForURLs(urls).uponQueue(DispatchQueue.main) { result in
            guard let results = result.successValue else {
                return
            }
            // Add all results into the sites dictionary
            results.flatMap({$0}).forEach({site in
                if let url = site?.url {
                    self.sites[url] = site
                }
            })
            self.tableView.reloadData()
        }
    }

    func homeAndNormalPagesOnly(_ bfList: WKBackForwardList) {
        let items = bfList.forwardList.reversed() + [bfList.currentItem].flatMap({$0}) + bfList.backList.reversed()
        
        //error url's are OK as they are used to populate history on session restore.
        listData = items.filter({return !($0.url.isLocal && ($0.url.originalURLFromErrorURL?.isLocal ?? true)) || $0.url.isAboutHomeURL})
    }
    
    func loadSites(_ bfList: WKBackForwardList) {
        self.currentItem = bfList.currentItem
        
        homeAndNormalPagesOnly(bfList)
    }
    
    func scrollTableViewToIndex(_ index: Int) {
        guard index > 1 else {
            return
        }
        let moveToIndexPath = IndexPath(row: index-2, section: 0)
        self.tableView.reloadRows(at: [moveToIndexPath], with: .none)
        self.tableView.scrollToRow(at: moveToIndexPath, at: UITableViewScrollPosition.middle, animated: false)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard let bvc = self.bvc else {
            return
        }
        if bvc.shouldShowFooterForTraitCollection(newCollection) != snappedToBottom {
            tableView.snp.updateConstraints { make in
                if snappedToBottom {
                    make.bottom.equalTo(self.view).offset(0)
                } else {
                    make.top.equalTo(self.view).offset(0)
                }
                make.height.equalTo(0)
            }
            snappedToBottom = !snappedToBottom
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let correctHeight = {
            self.tableView.snp.updateConstraints { make in
                make.height.equalTo(min(CGFloat(BackForwardViewUX.RowHeight * self.listData.count), size.height / 2))
            }
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
            constraint.deactivate()
        }
        self.verticalConstraints = []
        tableView.snp.makeConstraints { make in
            if snappedToBottom {
                verticalConstraints += [make.bottom.equalTo(self.view).offset(-bvc.footer.frame.height).constraint]
            } else {
                verticalConstraints += [make.top.equalTo(self.view).offset(bvc.header.frame.height + UIApplication.shared.statusBarFrame.size.height).constraint]
            }
        }
        shadow.snp.makeConstraints() { make in
            if snappedToBottom {
                verticalConstraints += [
                    make.bottom.equalTo(tableView.snp.top).constraint,
                    make.top.equalTo(self.view).constraint
                ]
                
            } else {
                verticalConstraints += [
                    make.top.equalTo(tableView.snp.bottom).constraint,
                    make.bottom.equalTo(self.view).constraint
                ]
            }
        }
    }

    func setupDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(BackForwardListViewController.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
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
    
    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: BackForwardListCellIdentifier, for: indexPath) as! BackForwardTableViewCell
        let item = listData[indexPath.item]
        let urlString = item.url.isLocal ? item.url.getQuery()["url"]?.unescape() : item.url.absoluteString
        
        cell.isCurrentTab = listData[indexPath.item] == self.currentItem
        cell.connectingBackwards = indexPath.item != listData.count-1
        cell.connectingForwards = indexPath.item != 0
        cell.isPrivate = isPrivate
        
        guard let url = urlString else {
            cell.site = Site(url: item.url.absoluteString, title: Strings.FirefoxHomePage)
            return cell
        }
        
        if item.url.isAboutHomeURL {
            cell.site = Site(url: item.url.absoluteString, title: Strings.FirefoxHomePage)
            return cell
        }
        
        if let site = sites[url] {
            cell.site = site
        } else {
            cell.site = Site(url: url, title: item.title ?? "")
        }
        
        cell.setNeedsDisplay()
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tabManager.selectedTab?.goToBackForwardListItem(listData[indexPath.item])
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt  indexPath: IndexPath) -> CGFloat {
        return CGFloat(BackForwardViewUX.RowHeight)
    }
}
