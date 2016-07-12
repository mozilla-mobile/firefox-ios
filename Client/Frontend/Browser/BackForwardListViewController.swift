/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import Storage
import SnapKit

class BackForwardListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
    
    enum BackForwardType {
        case forward
        case current
        case backward
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
    var listData = [(item:WKBackForwardListItem, type:BackForwardType)]()
    
    var tableHeight: CGFloat
    {
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
    
    init(profile: Profile, backForwardList: WKBackForwardList, isPrivate: Bool) {
        self.profile = profile
        self.isPrivate = isPrivate
        super.init(nibName: nil, bundle: nil)
        
        loadSites(backForwardList)
    }
    
    func loadSites(_ backForwardList: WKBackForwardList) {
        let sql = profile.favicons as! SQLiteHistory
        var urls: [String] = [String]()
        
        for page in backForwardList.forwardList.reversed() {
            urls.append(page.url.absoluteString!)
            listData.append((page, .forward))
        }
        
        if let currentPage = backForwardList.currentItem {
            currentRow = listData.count
            urls.append(currentPage.url.absoluteString!)
            listData.append((currentPage, .current))
        }
        for page in backForwardList.backList.reversed() {
            urls.append(page.url.absoluteString!)
            listData.append((page, .backward))
        }
        
        listData = listData.filter { !(($0.item.title ?? "").isEmpty && $0.item.URL.baseDomain()?.contains("localhost") ?? false)}
        
        sql.getSites(forURLs: urls).uponQueue(DispatchQueue.main) { result in
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
    
    func scrollTableView(toIndex index: Int) {
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
        tableView.snp_updateConstraints { make in
            make.bottom.equalTo(self.view).offset(bvc.shouldShowFooterForTraitCollection(newCollection) ? -UIConstants.ToolbarHeight : 0)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
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
        tableView.snp_makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-bvc.footer.frame.height)
        }
        shadow.snp_makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.bottom.equalTo(tableView.snp_top)
        }
        view.layoutIfNeeded()
        scrollTableView(toIndex: currentRow)
        setupDismissTap()
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
        let item = listData[(indexPath as NSIndexPath).item].item
        
        if let site = sites[item.URL.absoluteString] {
            cell.site = site
        }
        else {
            cell.site = Site(url: item.initialURL.absoluteString, title: item.title ?? "")
        }
        
        cell.isCurrentTab = (listData[(indexPath as NSIndexPath).item].type == .current)
        cell.connectingBackwards = ((indexPath as NSIndexPath).item != listData.count-1)
        cell.connectingForwards = ((indexPath as NSIndexPath).item != 0)
        cell.isPrivate = isPrivate
        
        cell.setNeedsDisplay()
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tabManager.selectedTab?.goToBackForwardListItem(listData[(indexPath as NSIndexPath).item].item)
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt  indexPath: IndexPath) -> CGFloat {
        return CGFloat(BackForwardViewUX.RowHeight);
    }
}
