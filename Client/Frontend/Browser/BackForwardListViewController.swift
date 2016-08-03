/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import Storage
import SnapKit

class BackForwardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    enum BackForwardType {
        case Forward
        case Current
        case Backward
    }
    
    struct BackForwardViewUX {
        static let RowHeight = 50
        static let BackgroundColor = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.4)
        static let BackgroundColorPrivate = UIColor(colorLiteralRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
    }
    
    private let BackForwardListCellIdentifier = "BackForwardListViewController"
    private var profile: Profile
    private lazy var sites = [String: Site]()
    private var isPrivate: Bool
    private var dismissing = false
    private var currentRow = 0
    
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
    var listData = [(item:WKBackForwardListItem, type:BackForwardType)]()
    
    var tableHeight: CGFloat
    {
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
    
    init(profile: Profile, backForwardList: WKBackForwardList, isPrivate: Bool) {
        self.profile = profile
        self.isPrivate = isPrivate
        super.init(nibName: nil, bundle: nil)
        
        loadSites(backForwardList)
    }
    
    func loadSites(backForwardList: WKBackForwardList) {
        let sql = profile.favicons as! SQLiteHistory
        var urls: [String] = [String]()
        
        for page in backForwardList.forwardList.reverse() {
            urls.append(page.URL.absoluteString)
            listData.append((page, .Forward))
        }
        
        if let currentPage = backForwardList.currentItem {
            currentRow = listData.count
            urls.append(currentPage.URL.absoluteString)
            listData.append((currentPage, .Current))
        }
        for page in backForwardList.backList.reverse() {
            urls.append(page.URL.absoluteString)
            listData.append((page, .Backward))
        }
        
        listData = listData.filter { !(($0.item.title ?? "").isEmpty && $0.item.URL.baseDomain()?.contains("localhost") ?? false)}
        
        sql.getSitesForURLs(urls).uponQueue(dispatch_get_main_queue()) { result in
            if let cursor = result.successValue {
                for cursorSite in cursor {
                    if let site = cursorSite, let url = site?.url {
                        self.sites[url] = site
                    }
                }
                self.tableView.reloadData()
            }
        }
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
        tableView.snp_updateConstraints { make in
            make.bottom.equalTo(self.view).offset(bvc.shouldShowFooterForTraitCollection(newCollection) ? -UIConstants.ToolbarHeight : 0)
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        tableView.snp_updateConstraints { make in
            make.height.equalTo(min(CGFloat(BackForwardViewUX.RowHeight*listData.count), size.height/2))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let bvc = self.bvc else {
            return
        }
        view.addSubview(shadow)
        view.addSubview(tableView)
        let snappedToBottom = bvc.toolbar != nil
        tableView.snp_makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.equalTo(self.view)
            if snappedToBottom {
                make.bottom.equalTo(self.view).offset(-bvc.footer.frame.height)
            } else {
                make.top.equalTo(self.view).offset(bvc.header.frame.height)
            }
        }
        shadow.snp_makeConstraints { make in
            make.left.right.equalTo(self.view)
            if snappedToBottom {
                make.bottom.equalTo(tableView.snp_top)
                make.top.equalTo(self.view)
            } else {
                make.top.equalTo(tableView.snp_bottom)
                make.bottom.equalTo(self.view)
            }
        }
        view.layoutIfNeeded()
        scrollTableViewToIndex(currentRow)
        setupDismissTap()
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
        let item = listData[indexPath.item].item
        
        if let site = sites[item.URL.absoluteString] {
            cell.site = site
        }
        else {
            cell.site = Site(url: item.initialURL.absoluteString, title: item.title ?? "")
        }
        
        cell.isCurrentTab = (listData[indexPath.item].type == .Current)
        cell.connectingBackwards = (indexPath.item != listData.count-1)
        cell.connectingForwards = (indexPath.item != 0)
        cell.isPrivate = isPrivate
        
        cell.setNeedsDisplay()
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tabManager.selectedTab?.goToBackForwardListItem(listData[indexPath.item].item)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath  indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(BackForwardViewUX.RowHeight);
    }
}
