/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

import Photos
import UIKit
import WebKit
import Shared
import Storage
import SnapKit
import XCGLogger
import Alamofire
import Account
import ReadingList
import MobileCoreServices
import WebImage

class BlurTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var profile: Profile!
    var site: Site!
    weak var asp: ActivityStreamPanel!
    var ugh: Bool = false
    var browserActions: BrowserActions!
    var tableView = UITableView()
    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(BlurTableViewController.dismiss(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        return tapRecognizer
    }()

    lazy var visualEffectView : UIVisualEffectView = {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        visualEffectView.frame = self.view.bounds
        visualEffectView.alpha = 0.90
        return visualEffectView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(visualEffectView)

        view.addGestureRecognizer(tapRecognizer)

        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.equalTo(290)
            make.height.equalTo(297)
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.scrollEnabled = false
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.layer.cornerRadius = 10
        tableView.accessibilityIdentifier = "SiteTable"
        tableView.registerClass(BlurTableViewCell.self, forCellReuseIdentifier: "BlurTableViewCell")
        tableView.registerClass(BlurTableViewHeaderCell.self, forCellReuseIdentifier: "BlurTableViewHeaderCell")

        if #available(iOS 9, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()

        let shadowLayer = CALayer()
        shadowLayer.backgroundColor = UIColor.blackColor().CGColor
        shadowLayer.shadowColor = UIColor.darkGrayColor().CGColor
        shadowLayer.shadowOffset = CGSizeMake(0, 3)
        shadowLayer.shadowRadius = 5.0
        shadowLayer.shadowOpacity = 0.8
        shadowLayer.cornerRadius = 10
        shadowLayer.frame = CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y, tableView.frame.size.width, tableView.frame.size.height)

        view.layer.addSublayer(shadowLayer)
        view.layer.addSublayer(tableView.layer)
    }

    func dismiss(gestureRecognizer: UIGestureRecognizer) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    func tableView(tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.row == 0 ? 74 : 56
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 1:
            if !ugh {
                browserActions.addBookmark(site)
            } else {
                browserActions.removeBookmark(site)
            }

//        case 2:
////            browserActions
//        case 3:
////            browserActions
        case 4:
            self.profile.history.removeHistoryForURL(site.url)
            self.asp.reloadRecentHistory()
            self.asp.tableView.reloadData()
        default:
            return
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("BlurTableViewHeaderCell", forIndexPath: indexPath) as! BlurTableViewHeaderCell
                cell.preservesSuperviewLayoutMargins = false
                cell.separatorInset = UIEdgeInsetsZero
                cell.layoutMargins = UIEdgeInsetsZero
                cell.configureWithSite(site)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("BlurTableViewCell", forIndexPath: indexPath) as! BlurTableViewCell

                // if isBookmarked then do . . .
                isBookmarked(site)

                let seconds = 0.05
                let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))

                dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                    
                    // here code perfomed with delay
                    if self.ugh {
                        let string = NSLocalizedString("Remove Bookmark", comment: "Context Menu Action for Activity Stream")
                        cell.configureCell(string, imageString: "action_bookmark")
                    } else {
                        let string = NSLocalizedString("Bookmark", comment: "Context Menu Action for Activity Stream")
                        cell.configureCell(string, imageString: "action_bookmark")
                    }
                    
                })


                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("BlurTableViewCell", forIndexPath: indexPath) as! BlurTableViewCell
                let string = NSLocalizedString("Share", comment: "Context Menu Action for Activity Stream")

                cell.configureCell(string, imageString: "action_share")
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("BlurTableViewCell", forIndexPath: indexPath) as! BlurTableViewCell
                let string = NSLocalizedString("Dismiss", comment: "Context Menu Action for Activity Stream")

                cell.configureCell(string, imageString: "action_close")
                return cell
            case 4:
                let cell = tableView.dequeueReusableCellWithIdentifier("BlurTableViewCell", forIndexPath: indexPath) as! BlurTableViewCell
                let string = NSLocalizedString("Delete from History", comment: "Context Menu Action for Activity Stream")

                cell.configureCell(string, imageString: "action_delete")
                return cell
            default:
                return tableView.dequeueReusableCellWithIdentifier("BlurTableViewCell")!
        }
    }

    func setImageWithURL(imageView: UIImageView, url: NSURL) {
        imageView.sd_setImageWithURL(url) { (img, err, type, url) -> Void in
            guard let img = img else {
                return
            }
            imageView.image = img
        }
        imageView.layer.masksToBounds = true
    }

    func isBookmarked(site: Site) {
        profile.bookmarks.modelFactory >>== {
            $0.isBookmarked(site.url).uponQueue(dispatch_get_main_queue()) {
                guard let isBookmarked = $0.successValue else {
                    return
                }
                self.ugh = isBookmarked
            }
        }
    }
}

class BlurTableViewHeaderCell: SimpleHighlightCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale

        isAccessibilityElement = true

        descriptionLabel.numberOfLines = 1
        titleLabel.numberOfLines = 1

        contentView.addSubview(siteImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(titleLabel)

        siteImageView.snp_remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(12)
            make.size.equalTo(SimpleHighlightCellUX.SiteImageViewSize)
        }

        titleLabel.snp_remakeConstraints { make in
            make.leading.equalTo(siteImageView.snp_trailing).offset(SimpleHighlightCellUX.CellTopBottomOffset)
            make.trailing.equalTo(contentView).inset(12)
//            make.top.equalTo(siteImageView).offset(SimpleHighlightCellUX.CellTopBottomOffset)
        }

        descriptionLabel.snp_remakeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(siteImageView).inset(10)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithSite(site: Site) {
        if let icon = site.icon {
            let url = icon.url
            self.siteImageView.layer.borderWidth = 0
            self.setImageWithURL(NSURL(string: url)!)
        } else if let url = NSURL(string: site.url) {
            self.siteImage = FaviconFetcher.getDefaultFavicon(url)
            self.siteImageView.layer.borderWidth = SimpleHighlightCellUX.BorderWidth
        }
        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
        self.descriptionLabel.text = site.tileURL.baseDomain()
    }
}