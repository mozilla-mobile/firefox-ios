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
    private lazy var tableView = UITableView()
    private var isPrivate: Bool
    private var dismissing = false
    var tabManager: TabManager!
    var listData = [(item:WKBackForwardListItem, type:BackForwardType)]()
    
    init(profile: Profile, backForwardList: WKBackForwardList, isPrivate: Bool) {
        self.profile = profile
        self.isPrivate = isPrivate
        super.init(nibName: nil, bundle: nil)
        
        setupTableView()
        loadSites(backForwardList)
    }
    
    func setupTableView() {
        tableView.separatorStyle = .None
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = false
        tableView.registerClass(BackForwardTableViewCell.self, forCellReuseIdentifier: BackForwardListCellIdentifier)
        
        tableView.backgroundColor = isPrivate ? BackForwardViewUX.BackgroundColorPrivate:BackForwardViewUX.BackgroundColor
        let blurEffect = UIBlurEffect(style: isPrivate ? .Dark : .ExtraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.backgroundView = blurEffectView
    }
    
    func loadSites(backForwardList: WKBackForwardList) {
        let sql = profile.favicons as! SQLiteHistory
        var urls: [String] = [String]()
        
        for page in backForwardList.forwardList.reverse() {
            urls.append(page.URL.absoluteString)
            listData.append((page, .Forward))
        }
        
        var currentRow = 0
        if let currentPage = backForwardList.currentItem {
            currentRow = listData.count
            urls.append(currentPage.URL.absoluteString)
            listData.append((currentPage, .Current))
        }
        for page in backForwardList.backList.reverse() {
            urls.append(page.URL.absoluteString)
            listData.append((page, .Backward))
        }
        
        listData = listData.filter { !(($0.item.title ?? "").isEmpty)}
        
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
        
        if currentRow > 1 {
            scrollTableViewToIndex(currentRow)
        }
    }
    
    func scrollTableViewToIndex(index: Int) {
        let moveToIndexPath = NSIndexPath(forRow: index-2, inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([moveToIndexPath], withRowAnimation: .None)
        self.tableView.scrollToRowAtIndexPath(moveToIndexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: false)
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.resizeHeight()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.bottom.equalTo(self.view)
        }
        self.view.layoutIfNeeded()
        self.resizeHeight()
        
        setupDismissTap()
    }
    
    func setupDismissTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(BackForwardListViewController.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        parentViewController?.view.addGestureRecognizer(tap)
    }
    
    func handleTap() {
        dismissWithAnimation()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if touch.view?.isDescendantOfView(view) ?? true {
            return false
        }
        return true
    }
    
    func resizeHeight() {
        let height = min(CGFloat(BackForwardViewUX.RowHeight*listData.count), self.view.frame.height/2)
        UIView.animateWithDuration(0.2, animations: {
            self.tableView.snp_updateConstraints { make in
                make.height.equalTo(height)
            }
            self.view.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.2)
            self.view.layoutIfNeeded()
        })
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
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tabManager.selectedTab?.goToBackForwardListItem(listData[indexPath.item].item)
        dismissWithAnimation()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath  indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(BackForwardViewUX.RowHeight);
    }
    
    func dismissWithAnimation() {
        if dismissing {
            return
        }
        
        dismissing = true
        self.view.alpha = 1.0
        
        UIView.animateWithDuration(0.2, delay: 0, options: [UIViewAnimationOptions.CurveEaseIn, UIViewAnimationOptions.AllowUserInteraction], animations: {
            self.tableView.snp_updateConstraints { make in
                make.height.equalTo(0)
            }
            self.view.alpha = 0.1
            self.view.layoutIfNeeded()
            
            }, completion: { finished in
                if finished {
                    self.view.removeFromSuperview()
                    self.removeFromParentViewController()
                }
        })
    }
}
