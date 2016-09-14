/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

class BlurTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var profile: Profile!
    var site: Site!
    var tableView = UITableView()
    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(BlurTableViewController.dismiss(_:)))
        tapRecognizer.numberOfTapsRequired = 1
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
            make.height.equalTo(279)
        }

        let shadowLayer = CALayer()
        shadowLayer.shadowColor = UIColor.darkGrayColor().CGColor
        shadowLayer.shadowPath = UIBezierPath(roundedRect: tableView.bounds, cornerRadius: tableView.layer.cornerRadius).CGPath
        shadowLayer.shadowOffset = CGSize(width: 10, height: 10)
        shadowLayer.shadowOpacity = 0.8
        shadowLayer.shadowRadius = 2
        view.layer.addSublayer(shadowLayer)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.scrollEnabled = false
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.layer.cornerRadius = 10
        tableView.accessibilityIdentifier = "SiteTable"
        tableView.registerClass(BlurTableViewCell.self, forCellReuseIdentifier: "BlurTableViewCell")
        tableView.registerClass(TwoLineTableViewCell.self, forCellReuseIdentifier: "TwoLineCell")

        if #available(iOS 9, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
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
        return 56
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TwoLineCell", forIndexPath: indexPath)
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero

        switch indexPath.row {
            case 0:
                cell.textLabel?.text = site.title
                cell.detailTextLabel?.text = site.url
                if let icon = site.icon {
                    let url = icon.url
                    cell.imageView?.layer.borderWidth = 0
                    self.setImageWithURL(cell.imageView!, url: NSURL(string: url)!)
                } else if let url = NSURL(string: site.url) {
                    cell.imageView?.image = FaviconFetcher.getDefaultFavicon(url)
                    cell.imageView!.layer.borderWidth = SimpleHighlightCellUX.BorderWidth
                }
                
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("BlurTableViewCell", forIndexPath: indexPath) as! BlurTableViewCell

                // if isBookmarked then do . . .
                let string = NSLocalizedString("Bookmark", comment: "Context Menu Action for Activity Stream")
                cell.configureCell(string, imageString: "action_bookmark")
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
                let string = NSLocalizedString("Delete", comment: "Context Menu Action for Activity Stream")

                cell.configureCell(string, imageString: "action_delete")
                return cell
            default:
                return cell
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

//    func isBookmarked(site: Site) -> Bool {
//        profile.bookmarks.modelFactory >>== { bookmark in
//            $0.isBookmarked(site.url)
//                .uponQueue(dispatch_get_main_queue()) {
//                    guard let isBookmarked = $0.successValue else {
//                        log.error("Error getting bookmark status: \($0.failureValue).")
//                        return false
//                    }
//            }
//        }
//        return true
//    }
}