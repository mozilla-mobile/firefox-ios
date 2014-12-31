/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class HistoryViewController: UITableViewController {
    private let CELL_IDENTIFIER = "SITE_CELL"
    private let HEADER_IDENTIFIER = "SITE_HEADER"

    var sites: [Site]? = nil
    var _profile: Profile? = nil

    var profile: Profile! {
        get {
            return _profile
        }

        set (profile) {
            self._profile = profile
            self.sites = [Site]()
            profile.history.getSites(nil, success: { sites in
                self.sites = sites
            }, failure: { err in
                println("Err getting sites \(err)")
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

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if var sites = self.sites {
            return sites.count
        }
        return 0
    }

    // UITableViewController doesn't let us specify a style for recycling views. We override the default style here.
    private class CustomCell : UITableViewCell {
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            // ignore the style argument, use our own to override
            super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
            textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)
            textLabel?.textColor = UIColor.darkGrayColor()
            indentationWidth = 20

            detailTextLabel?.textColor = UIColor.lightGrayColor()
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private let FAVICON_SIZE = 32
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as UITableViewCell

        if var site = self.sites {
            let site = site[indexPath.row]

            // cell.imageView?.image = site.icon
            cell.textLabel?.text = site.title
            cell.detailTextLabel?.text = site.url
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
        if let sites = self.sites {
            let site = sites[indexPath.row]
            if let vc = parentViewController as? TabBarViewController {
                vc.loadUrl(site.url)
            }
        }
    }
}

class SearchViewController: HistoryViewController {
    var filter: String? {
        get {
            return ""
        }

        set {
            if let p = profile {
                profile.history.getSites(newValue, success: { sites in
                    self.sites = sites
                    self.tableView.reloadData()
                }, failure: { err in
                    println("Error filtering with \(newValue)")
                    // XXX - Do we keep the old data?
                })
            }
        }
    }
}
