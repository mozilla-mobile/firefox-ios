/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public typealias Timestamp = UInt64
public typealias MicrosecondTimestamp = UInt64

public let ThreeWeeksInSeconds = 3 * 7 * 24 * 60 * 60

public let OneMonthInMilliseconds = 30 * OneDayInMilliseconds
public let OneWeekInMilliseconds = 7 * OneDayInMilliseconds
public let OneDayInMilliseconds = 24 * OneHourInMilliseconds
public let OneHourInMilliseconds = 60 * OneMinuteInMilliseconds
public let OneMinuteInMilliseconds = 60 * OneSecondInMilliseconds
public let OneSecondInMilliseconds: UInt64 = 1000

extension NSDate {
    public class func now() -> Timestamp {
        return UInt64(1000 * NSDate().timeIntervalSince1970)
    }

    public class func nowNumber() -> NSNumber {
        return NSNumber(unsignedLongLong: now())
    }

    public class func nowMicroseconds() -> MicrosecondTimestamp {
        return UInt64(1000000 * NSDate().timeIntervalSince1970)
    }

    public class func fromTimestamp(timestamp: Timestamp) -> NSDate {
        return NSDate(timeIntervalSince1970: Double(timestamp) / 1000)
    }

    public class func fromMicrosecondTimestamp(microsecondTimestamp: MicrosecondTimestamp) -> NSDate {
        return NSDate(timeIntervalSince1970: Double(microsecondTimestamp) / 1000000)
    }

    public func toRelativeTimeString(isConcise: Bool = false) -> String {
        let now = NSDate()

        let units: NSCalendarUnit = [NSCalendarUnit.Second, NSCalendarUnit.Minute, NSCalendarUnit.Day, NSCalendarUnit.WeekOfYear, NSCalendarUnit.Month, NSCalendarUnit.Year, NSCalendarUnit.Hour]

        let components = NSCalendar.currentCalendar().components(units,
            fromDate: self,
            toDate: now,
            options: [])

        if isConcise {
            if components.year == 1 {
                return NSLocalizedString("\(components.year) year ago", comment: "Concise date for date older than a year.")
            }

            if components.year > 0 {
                return NSLocalizedString("\(components.year) years ago", comment: "Concise date for date older than a year.")
            }

            if components.month == 1 {
                return NSLocalizedString("\(components.month) month ago", comment: "Concise date for date older than a month.")
            }

            if components.month > 1 {
                return NSLocalizedString("\(components.month) months ago", comment: "Concise date for date older than a month.")
            }

            if components.weekOfYear == 1 {
                return NSLocalizedString("\(components.weekOfYear) week ago", comment: "Concise date for date older than a week.")
            }

            if components.weekOfYear > 0 {
                return NSLocalizedString("\(components.weekOfYear) weeks ago", comment: "Concise date for date older than a week.")
            }

            if components.day == 1 {
                return String(format: NSLocalizedString("day ago", comment: "Relative date for yesterday."))
            }

            if components.day > 1 {
                return NSLocalizedString("\(components.day) days ago", comment: "Concise date for date older than a day.")
            }

            if components.hour == 1 {
                return NSLocalizedString("\(components.hour) hour ago", comment: "Concise date for date older than a hour.")
            }

            if components.hour > 0 {
                return NSLocalizedString("\(components.hour) hours ago", comment: "Concise date for date older than a hour.")
            }

            if components.minute == 1 {
                return NSLocalizedString("\(components.minute) min ago", comment: "Concise date for date older than a minute.")
            }

            if components.minute > 0 {
                return NSLocalizedString("\(components.minute) mins ago", comment: "Concise date for date older than a minute.")
            }
        }
        
        if components.year > 0 {
            return String(format: NSDateFormatter.localizedStringFromDate(self, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
        }

        if components.month == 1 {
            return String(format: NSLocalizedString("more than a month ago", comment: "Relative date for dates older than a month and less than two months."))
        }

        if components.month > 1 {
            return String(format: NSDateFormatter.localizedStringFromDate(self, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
        }

        if components.weekOfYear > 0 {
            return String(format: NSLocalizedString("more than a week ago", comment: "Description for a date more than a week ago, but less than a month ago."))
        }

        if components.day == 1 {
            return String(format: NSLocalizedString("yesterday", comment: "Relative date for yesterday."))
        }

        if components.day > 1 {
            return String(format: NSLocalizedString("this week", comment: "Relative date for date in past week."), String(components.day))
        }

        if components.hour > 0 || components.minute > 0 {
            let absoluteTime = NSDateFormatter.localizedStringFromDate(self, dateStyle: NSDateFormatterStyle.NoStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
            let format = NSLocalizedString("today at %@", comment: "Relative date for date older than a minute.")
            return String(format: format, absoluteTime)
        }

        return String(format: NSLocalizedString("just now", comment: "Relative time for a tab that was visited within the last few moments."))
    }
}

public func decimalSecondsStringToTimestamp(input: String) -> Timestamp? {
    var double = 0.0
    if NSScanner(string: input).scanDouble(&double) {
        return Timestamp(double * 1000)
    }
    return nil
}

public func millisecondsToDecimalSeconds(input: Timestamp) -> String {
    let val: Double = Double(input) / 1000
    return String(format: "%.2F", val)
}
