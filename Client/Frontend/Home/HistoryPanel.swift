/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Storage

private func getDate(#dayOffset: Int) -> NSTimeInterval {
    let calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)!
    let nowComponents = calendar.components(NSCalendarUnit.YearCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.DayCalendarUnit, fromDate: NSDate())
    let today = calendar.dateFromComponents(nowComponents)!
    return calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: dayOffset, toDate: today, options: nil)!.timeIntervalSince1970
}

class HistoryPanel: SiteTableViewController {
    private var sections = [Cursor]()

    override func reloadData() {
        var Today = getDate(dayOffset: 0)
        var Yesterday = getDate(dayOffset: -1)
        var ThisWeek = getDate(dayOffset: -7)

        var finished = 0
        func finishedFunc(section: Int) -> (data: Cursor) -> () {
            return { data in
                self.sections[section] = data
                finished++
                // We current reload data as it comes in
                self.tableView.reloadData()
                if finished == self.sections.count {
                    self.refreshControl?.endRefreshing()
                }
            }
        }

        // Prefill sections with some empty data
        sections.removeAll(keepCapacity: true)
        for i in 0..<4 {
            sections.append(Cursor(status: .Success, msg: "Loading"))
        }

        let opts = QueryOptions()
        let nilTime: NSTimeInterval? = nil
        opts.filterType = FilterType.DateRange
        opts.sort = .LastVisit

        opts.filter = DateRange(start: nilTime, end: Today)
        profile.history.get(opts, complete: finishedFunc(0))

        opts.filter = DateRange(start: Today, end: Yesterday)
        profile.history.get(opts, complete: finishedFunc(1))

        opts.filter = DateRange(start: Yesterday, end: ThisWeek)
        profile.history.get(opts, complete: finishedFunc(2))

        opts.filter = DateRange(start: ThisWeek, end: nilTime)
        profile.history.get(opts, complete: finishedFunc(3))
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        let cursor = sections[indexPath.section]

        if let site = cursor[indexPath.row] as? Site {
            if site.title != "" {
                cell.textLabel?.text = site.title
                cell.detailTextLabel?.text = site.url
            } else {
                cell.textLabel?.text = site.url
                cell.detailTextLabel?.text = ""
            }
            if let img = site.icon? {
                let imgURL = NSURL(string: img.url)
                cell.imageView?.sd_setImageWithURL(imgURL, placeholderImage: self.profile.favicons.defaultIcon)
            } else {
                cell.imageView?.image = self.profile.favicons.defaultIcon
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cursor = sections[indexPath.section]
        if let site = cursor[indexPath.row] as? Site {
            if let url = NSURL(string: site.url) {
                homePanelDelegate?.homePanel(didSubmitURL: url)
                return
            }
        }
    }

    // Functions that deal with showing header rows
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return NSLocalizedString("Today", comment: "")
        case 1: return NSLocalizedString("Yesterday", comment: "")
        case 2: return NSLocalizedString("Past week", comment: "")
        case 3: return NSLocalizedString("Older", comment: "")
        default:
            assertionFailure("Invalid history section \(section)")
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let cursor = sections[section]
        if cursor.count == 0 {
            return 0
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
}
