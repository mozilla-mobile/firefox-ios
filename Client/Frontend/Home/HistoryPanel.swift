/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Storage

class HistoryPanel: UITableViewController, HomePanel {
    private let CELL_IDENTIFIER = "HISTORY_CELL"
    private let HEADER_IDENTIFIER = "HISTORY_HEADER"

    var history: Cursor? = nil
    var _profile: Profile? = nil
    weak var delegate: HomePanelDelegate? = nil

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

        tableView.registerClass(TwoLineCell.self, forCellReuseIdentifier: CELL_IDENTIFIER)
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

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER) as UITableViewCell

        if var hist = self.history {
            if let site = hist[indexPath.row] as? Site {
                cell.textLabel?.text = site.title
                cell.detailTextLabel?.text = site.url
                if let img = site.icon? {
                    let imgURL = NSURL(string: img.url)
                    cell.imageView?.sd_setImageWithURL(imgURL, placeholderImage: self.profile.favicons.defaultIcon)
                } else {
                    cell.imageView?.image = self.profile.favicons.defaultIcon
                }
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
                    delegate?.homePanel(didSubmitURL: NSURL(string: site.url)!)
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
