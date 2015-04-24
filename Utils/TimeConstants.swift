/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public typealias Timestamp = UInt64

public let ThreeWeeksInSeconds = 3 * 7 * 24 * 60 * 60

public let OneMonthInMilliseconds = 30 * OneDayInMilliseconds
public let OneWeekInMilliseconds = 7 * OneDayInMilliseconds
public let OneDayInMilliseconds = 24 * OneHourInMilliseconds
public let OneHourInMilliseconds = 60 * OneMinuteInMilliseconds
public let OneMinuteInMilliseconds: UInt64 = 60 * 1000

extension NSDate {
    public class func now() -> Timestamp {
        return UInt64(1000 * NSDate().timeIntervalSince1970)
    }

    public func toRelativeTimeString() -> String {

        let now = NSDate()

        let units = NSCalendarUnit.CalendarUnitSecond | NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitWeekOfYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitHour

        let components = NSCalendar.currentCalendar().components(units, fromDate: self, toDate: now, options: NSCalendarOptions.allZeros)

        if components.year > 0 {
            if components.year > 1 {
                return String(format: NSLocalizedString("%@ years ago", comment: "relative time"), String(components.year))
            } else if components.year == 1 {
                return String(format: NSLocalizedString("a year ago", comment: "relative time"))
            }
        } else if components.month > 0 {
            if components.month > 1 {
                return String(format: NSLocalizedString("%@ months ago", comment: "relative time"), String(components.month))
            } else if components.month == 1 {
                return String(format: NSLocalizedString("a month ago", comment: "relative time"))
            }
        } else if components.weekOfYear > 0 {
            if components.weekOfYear > 1 {
                return String(format: NSLocalizedString("%@ weeks ago", comment: "relative time"), String(components.weekOfYear))
            } else if components.weekOfYear == 1 {
                return String(format: NSLocalizedString("a week ago", comment: "relative time"))
            }
        } else if components.day > 0 {
            if components.day > 1 {
                return String(format: NSLocalizedString("%@ days ago", comment: "relative time"), String(components.day))
            } else if components.day == 1 {
                return String(format: NSLocalizedString("a day ago", comment: "relative time"))
            }
        } else if components.hour > 0 {
            if components.hour > 1 {
                println(components.hour)
                return String(format: NSLocalizedString("%@ hours ago", comment: "relative time"), String(components.hour))
            } else if components.hour == 1 {
                return String(format: NSLocalizedString("an hour ago", comment: "relative time"))
            }
        } else if components.minute > 0 {
            if components.minute > 1 {
                return String(format: NSLocalizedString("%@ minutes ago", comment: "relative time"), String(components.minute))
            } else if components.minute == 1 {
                return String(format: NSLocalizedString("a minute ago", comment: "relative time"))
            }
        } else {
            if components.second >= 10 {
                return String(format: NSLocalizedString("%@ seconds ago", comment: "relative time"), String(components.second))
            }
        }
        return String(format: NSLocalizedString("just now", comment: "relative time"))
    }
}

public func decimalSecondsStringToTimestamp(input: String) -> Timestamp? {
    if let double = NSScanner(string: input).scanDouble() {
        return Timestamp(double * 1000)
    }
    return nil
}

public func millisecondsToDecimalSeconds(input: Timestamp) -> String {
    let val: Double = Double(input) / 1000
    return String(format: "%.2F", val)
}

extension Timestamp {
    public func toNSDate() -> NSDate {
        return NSDate(timeIntervalSince1970: NSTimeInterval(self / 1000))
    }
}
