// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Alamofire

func createMockFavicon(icon: UIImage) -> UIImage {
    let size = CGSize(width: 30, height: 30)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    var context = UIGraphicsGetCurrentContext()
    icon.drawInRect(CGRectInset(CGRect(origin: CGPointZero, size: size), 1.0, 1.0))
    CGContextSetStrokeColorWithColor(context, UIColor.grayColor().CGColor)
    CGContextSetLineWidth(context, 0.5);
    CGContextStrokeEllipseInRect(context, CGRectInset(CGRect(origin: CGPointZero, size: size), 1.0, 1.0))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

class BookmarksViewController: UITableViewController
{
    var account: Account!
    var bookmarks: [Bookmark] = [];
    // TODO: Move this to the authenticator when its available.
    let favicons: Favicons = BasicFavicons();
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.sectionFooterHeight = 0
        //tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    func reloadData() {
        account.bookmarks.getAll(
            { response in
                self.bookmarks = response
                dispatch_async(dispatch_get_main_queue()) {
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            },
            error: { err in
                // TODO: Figure out a good way to handle this.
                println("Error: could not load bookmarks")
            })
    }
    
    func refresh() {
        reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks.count;
    }
    
    private let FAVICON_SIZE = 32;
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)

        if let image = (UIImage(named: "leaf.png")) {
            cell.imageView.image = createMockFavicon(image)
        }
        
        let bookmark = bookmarks[indexPath.row]
        // TODO: We need an async image loader api here
        favicons.getForUrl(NSURL(string: bookmark.url)!, options: nil, callback: { (icon: Favicon) -> Void in
            if let img = icon.img {
                cell.imageView.image = createMockFavicon(img);
            }
        });
        
        cell.textLabel.text = bookmark.title
        cell.textLabel.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        cell.textLabel.textColor = UIColor.darkGrayColor()
        cell.indentationWidth = 20
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 42
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let objects = UINib(nibName: "TabsViewControllerHeader", bundle: nil).instantiateWithOwner(nil, options: nil)
        let view = objects[0] as? UIView
        
        if let label = view?.viewWithTag(1) as? UILabel {
            label.text = "Recent Bookmarks"
        }
        
        return view
    }
    
    //    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    //        let objects = UINib(nibName: "TabsViewControllerHeader", bundle: nil).instantiateWithOwner(nil, options: nil)
    //        if let view = objects[0] as? UIView {
    //            if let label = view.viewWithTag(1) as? UILabel {
    //                // TODO: More button
    //            }
    //        }
    //        return view
    //    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let bookmark = bookmarks[indexPath.row]
        UIApplication.sharedApplication().openURL(NSURL(string: bookmark.url)!)
    }
}
