/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Storage

private func getDate(#dayOffset: Int) -> NSDate {
    let calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)!
    let nowComponents = calendar.components(NSCalendarUnit.YearCalendarUnit | NSCalendarUnit.MonthCalendarUnit | NSCalendarUnit.DayCalendarUnit, fromDate: NSDate())
    let today = calendar.dateFromComponents(nowComponents)!
    return calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: dayOffset, toDate: today, options: nil)!
}

class HistoryPanel: SiteTableViewController {
    private let NumSections = 4
    private var Today = getDate(dayOffset: 0)
    private var Yesterday = getDate(dayOffset: -1)
    private var ThisWeek = getDate(dayOffset: -7)

    private var sectionOffsets = [Int: Int]()

    override func reloadData() {
        let opts = QueryOptions()
        opts.sort = .LastVisit
        profile.history.get(opts, complete: { (data: Cursor) -> Void in
            self.refreshControl?.endRefreshing()
            self.sectionOffsets = [Int: Int]()
            self.data = data
            self.tableView.reloadData()
        })
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        let offset = sectionOffsets[indexPath.section]!
        if let site = data[indexPath.row + offset] as? Site {
            cell.textLabel?.text = site.title
            cell.detailTextLabel?.text = site.url
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
        let offset = sectionOffsets[indexPath.section]!
        if let site = data[indexPath.row + offset] as? Site {
            if let url = NSURL(string: site.url) {
                homePanelDelegate?.homePanel(didSubmitURL: url)
                return
            }
        }
        println("Could not click on history row")
    }

    // Functions that deal with showing header rows
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NumSections
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return NSLocalizedString("Today", comment: "")
        case 1: return NSLocalizedString("Yesterday", comment: "")
        case 2: return NSLocalizedString("Last week", comment: "")
        case 3: return NSLocalizedString("Last month", comment: "")
        default:
            assertionFailure("Invalid history section \(section)")
        }
    }

    private func isInSection(date: NSDate, section: Int) -> Bool {
        let now = NSDate()
        switch section {
        case 0:
            return date.timeIntervalSince1970 > Today.timeIntervalSince1970
        case 1:
            return date.timeIntervalSince1970 > Yesterday.timeIntervalSince1970
        case 2:
            return date.timeIntervalSince1970 > ThisWeek.timeIntervalSince1970
        default:
            return true
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let current = sectionOffsets[section] {
            if let next = sectionOffsets[section+1] {
                if current == next {
                    // If this points to the same element as the next one, it's empty. Don't show it.
                    return 0
                }
            }
        } else {
            // This may not be filled in yet (for instance, if the number of rows in data is zero). If it is,
            // just return zero.
            return 0
        }

        // Return the default height for header rows
        return super.tableView(tableView, heightForHeaderInSection: section)
    }


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let size = sectionOffsets[section] {
            if let nextSize = sectionOffsets[section+1] {
                return nextSize - size
            }
        }

        var searchingSection = 0
        sectionOffsets[searchingSection] = 0

        // Loop over all the data. Record the start of each "section" of our list.
        for i in 0..<data.count {
            if let site = data[i] as? Site {
                if !isInSection(site.latestVisit!.date, section: searchingSection) {
                    searchingSection++
                    sectionOffsets[searchingSection] = i
                }

                if searchingSection == NumSections {
                    break
                }
            }
        }

        // Now fill in any sections that weren't found with data.count.
        // Note, we actually fill in one past the end of the list to make finding the length
        // of a section easier.
        searchingSection++
        for i in searchingSection...NumSections {
            sectionOffsets[i] = data.count
        }

        // This function wants the size of a section, so return the distance between two adjacent ones
        return sectionOffsets[section+1]! - sectionOffsets[section]!
    }
}
