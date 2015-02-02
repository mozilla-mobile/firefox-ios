/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Storage

class HistoryViewController: UITableViewController, UrlViewController {
    private let CELL_IDENTIFIER = "HISTORY_CELL"
    private let HEADER_IDENTIFIER = "HISTORY_HEADER"

    var history: Cursor? = nil
    var _profile: Profile? = nil
    var delegate: UrlViewControllerDelegate? = nil

    var profile: Profile! {
        get {
            return _profile
        }

        set (profile) {
            self._profile = profile

            let opts = QueryOptions()
            opts.sort = .LastVisit

            profile.history.get(opts, complete: { (data: Cursor) -> Void in
                if data.status != .Success {
                    println("Err: \(data.statusMessage)")
                } else {
                    self.history = data
                    self.tableView.reloadData()
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(CustomCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if var hist = self.history {
            return hist.count
        }
        return 0
    }

    // UITableViewController doesn't let us specify a style for recycling views. We override the default style here.
    private class CustomCell : UITableViewCell {
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            // ignore the style argument, use our own to override
            super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
            textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)
            textLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
            indentationWidth = 0
            detailTextLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGrayColor() : UIColor.lightGrayColor()
            imageView?.bounds = CGRectMake(0, 0, 24, 24)
            // imageView?
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private let FAVICON_SIZE = 32
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as UITableViewCell

        if var hist = self.history {
            if let site = hist[indexPath.row] as? Site {
                cell.textLabel?.text = site.title
                cell.detailTextLabel?.text = site.url
                // cell.imageView?.image = UIImage(named: "leaf")

                let opts = QueryOptions()
                opts.filter = site.url
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if var hist = self.history {
            if let site = hist[indexPath.row] as? Site {
                if let url = NSURL(string: site.url) {
                    delegate?.didClickUrl(NSURL(string: site.url)!)
                } else {
                    println("Error creating url for \(site.url)")
                }
                return
            } else {
                println("Could not find a site for \(indexPath)")
            }
        } else {
            println("Could not get history")
        }
    }
}
