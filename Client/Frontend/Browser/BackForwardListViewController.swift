/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import Storage
import SnapKit

struct BackForwardViewUX {
    static let RowHeight = 50
    static let BackgroundColor = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.4)
    static let BackgroundColorPrivate = UIColor(colorLiteralRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
}

class BackForwardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

    private let BackForwardListCellIdentifier = "BackForwardListViewController"
    private var profile: Profile
    private lazy var sites = [String: Site]()
    private var isPrivate: Bool
    private var dismissing = false
    private var currentRow = 0
    private var verticalConstraints: [Constraint] = []
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .None
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = false
        tableView.registerClass(BackForwardTableViewCell.self, forCellReuseIdentifier: self.BackForwardListCellIdentifier)
        tableView.backgroundColor = self.isPrivate ? BackForwardViewUX.BackgroundColorPrivate:BackForwardViewUX.BackgroundColor
        let blurEffect = UIBlurEffect(style: self.isPrivate ? .Dark : .ExtraLight)
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
            assert(NSThread.isMainThread(), "tableHeight interacts with UIKit components - cannot call from background thread.")
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
        tableView.snp_makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.equalTo(self.view)
        }
        shadow.snp_makeConstraints { make in
            make.left.right.equalTo(self.view)
        }
        remakeVerticalConstraints()
        view.layoutIfNeeded()
        scrollTableViewToIndex(currentRow)
        setupDismissTap()
    }

    func loadSitesFromProfile() {
        let sql = profile.favicons as! SQLiteHistory
        let urls = self.listData.flatMap {$0.URL.isLocal ? $0.URL.getQuery()["url"]?.unescape() : $0.URL.absoluteString}

        sql.getSitesForURLs(urls).uponQueue(dispatch_get_main_queue()) { result in
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

    func loadSites(bfList: WKBackForwardList) {
        let items = bfList.forwardList.reverse() + [bfList.currentItem].flatMap({$0}) + bfList.backList.reverse()
        self.currentItem = bfList.currentItem

        //error url's are OK as they are used to populate history on session restore.
        listData = items.filter({return !($0.URL.isLocal && ($0.URL.originalURLFromErrorURL?.isLocal ?? true))})

    }
    
    func scrollTableViewToIndex(index: Int) {
        guard index > 1 else {
            return
        }
        let moveToIndexPath = NSIndexPath(forRow: index-2, inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([moveToIndexPath], withRowAnimation: .None)
        self.tableView.scrollToRowAtIndexPath(moveToIndexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: false)
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        guard let bvc = self.bvc else {
            return
        }
        if bvc.shouldShowFooterForTraitCollection(newCollection) != snappedToBottom {
            tableView.snp_updateConstraints { make in
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
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        let correctHeight = {
            self.tableView.snp_updateConstraints { make in
                make.height.equalTo(min(CGFloat(BackForwardViewUX.RowHeight * self.listData.count), size.height / 2))
            }
        }
        coordinator.animateAlongsideTransition(nil) { _ in
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
        tableView.snp_makeConstraints { make in
            if snappedToBottom {
                verticalConstraints += [make.bottom.equalTo(self.view).offset(-bvc.footer.frame.height).constraint]
            } else {
                verticalConstraints += [make.top.equalTo(self.view).offset(bvc.header.frame.height + UIApplication.sharedApplication().statusBarFrame.size.height).constraint]
            }
        }
        shadow.snp_makeConstraints() { make in
            if snappedToBottom {
                verticalConstraints += [
                    make.bottom.equalTo(tableView.snp_top).constraint,
                    make.top.equalTo(self.view).constraint
                ]
                
            } else {
                verticalConstraints += [
                    make.top.equalTo(tableView.snp_bottom).constraint,
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
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if touch.view?.isDescendantOfView(tableView) ?? true {
            return false
        }
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Table view
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       let cell = self.tableView.dequeueReusableCellWithIdentifier(BackForwardListCellIdentifier, forIndexPath: indexPath) as! BackForwardTableViewCell
        let item = listData[indexPath.item]
        let urlString = item.URL.isLocal ? item.URL.getQuery()["url"]?.unescape() : item.URL.absoluteString
        guard let url = urlString else {
            return cell // This should never happen.
        }

        if let site = sites[url] {
            cell.site = site
        } else {
            cell.site = Site(url: url, title: item.title ?? "")
        }
        
        cell.isCurrentTab = listData[indexPath.item] == self.currentItem
        cell.connectingBackwards = indexPath.item != listData.count-1
        cell.connectingForwards = indexPath.item != 0
        cell.isPrivate = isPrivate
        
        cell.setNeedsDisplay()
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tabManager.selectedTab?.goToBackForwardListItem(listData[indexPath.item])
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath  indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(BackForwardViewUX.RowHeight)
    }
}
