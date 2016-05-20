/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import Storage
import SnapKit

class BackForwardListView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    enum BackForwardType {
        case Forward
        case Current
        case Backward
    }
    
    struct BackForwardViewUX {
        static let RowHeight = 50
    }
    
    private var profile: Profile?
    private var sites = [String: Site]()
    private var tableView: UITableView!
    private var isPrivate: Bool!
    private var dismissing = false
    var tabManager: TabManager!
    var listData = [(item:WKBackForwardListItem, type:BackForwardType)]()
    
    init(profile: Profile, backForwardList: WKBackForwardList, isPrivate: Bool) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clearColor()
        
        self.profile = profile
        self.isPrivate = isPrivate
        
        tableView = UITableView()
        tableView.separatorStyle = .None
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 1))
        tableView.alwaysBounceVertical = false
        
        if isPrivate {
            tableView.backgroundColor = UIColor.init(colorLiteralRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
            let blurEffect = UIBlurEffect(style: .Dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            tableView.backgroundView = blurEffectView
        }
        else {
            tableView.backgroundColor = UIColor.init(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.4)
            let blurEffect = UIBlurEffect(style: .ExtraLight)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            tableView.backgroundView = blurEffectView
        }
        
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
        
        let deferred = sql.getSitesForURLs(urls)
        
        deferred.uponQueue(dispatch_get_main_queue()) { result in
            if let cursor = result.successValue {
                for cursorSite in cursor {
                    if let site = cursorSite, let url = site?.url {
                        self.sites[url] = site
                    }
                }
                self.tableView.reloadData()
            }
        }
        
        addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.bottom.equalTo(self)
        }
        
        if currentRow > 1 {
            self.tableView.reloadData()
            let moveToIndexPath = NSIndexPath(forRow: currentRow-2, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([moveToIndexPath], withRowAnimation: .None)
            self.tableView.scrollToRowAtIndexPath(moveToIndexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: false)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if dismissing {
            return
        }
        
        let height = min(CGFloat(BackForwardViewUX.RowHeight*listData.count), self.frame.height/2)
        UIView.animateWithDuration(0.2, animations: {
            self.tableView.snp_updateConstraints { make in
                make.height.equalTo(height)
            }
            self.backgroundColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.2)
            self.layoutIfNeeded()
        })
    }
    
    // MARK: - Table view
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: BackForwardTableViewCell? = tableView.dequeueReusableCellWithIdentifier("BackForwardListViewController") as? BackForwardTableViewCell
        if (cell == nil)
        {
            cell = BackForwardTableViewCell(style: UITableViewCellStyle.Default,
                                            reuseIdentifier: "BackForwardListViewController", isPrivate: isPrivate)
        }
        let item = listData[indexPath.item].item
        
        if let site = sites[item.URL.absoluteString] {
            cell?.site = site
        }
        else {
            cell?.site = Site(url: item.initialURL.absoluteString, title: item.title ?? "")
        }
        
        
        cell?.currentTab = (listData[indexPath.item].type == .Current)
        cell?.connectingBackwards = (indexPath.item != listData.count-1)
        cell?.connectingForwards = (indexPath.item != 0)
        
        cell?.setNeedsDisplay()
        
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tabManager.selectedTab?.goToBackForwardListItem(listData[indexPath.item].item)
        dismissWithAnimation()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath  indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(BackForwardViewUX.RowHeight);
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if !CGRectContainsPoint(tableView.frame, point) {
            dismissWithAnimation()
        }
        return super.pointInside(point, withEvent: event)
    }
    
    func dismissWithAnimation() {
        if dismissing {
            return
        }
        
        dismissing = true
        self.alpha = 1.0
        
        UIView.animateWithDuration(0.2, delay: 0, options: [UIViewAnimationOptions.CurveEaseIn, UIViewAnimationOptions.AllowUserInteraction], animations: {
            self.tableView.snp_updateConstraints { make in
                make.height.equalTo(0)
            }
            self.alpha = 0.1
            self.layoutIfNeeded()
            
            }, completion: { finished in
                if finished {
                    self.removeFromSuperview()
                }
        })
    }
}
