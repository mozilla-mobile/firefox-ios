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
public let OneMinuteInMilliseconds: UInt64 = 60 * 1000

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

    public func toRelativeTimeString() -> String {
        let now = NSDate()
        let units = NSCalendarUnit.CalendarUnitSecond | NSCalendarUnit.CalendarUnitMinute |
            NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitWeekOfYear |
            NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitHour
        let components = NSCalendar.currentCalendar().components(units, fromDate: self, toDate: now, options: NSCalendarOptions.allZeros)
        let formatter = NSDateFormatter()
        
        if components.year > 0 {
            return String(format: NSDateFormatter.localizedStringFromDate(self, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
        }

        if components.month == 1 {
            return String(format: NSLocalizedString("More than a month ago", comment: "Relative date for dates older than a month and less than two months."))
        }
        else if components.month > 1 {
            return String(format: NSDateFormatter.localizedStringFromDate(self, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
        }
        

        if components.weekOfYear > 0 {
            return String(format: NSLocalizedString("More than a week ago", comment: "Description for a date more than a week ago, but less than a month ago."))
        }

        if components.day == 1 {
            return String(format: NSLocalizedString("Yesterday", comment: "Relative date for yesterday."))
        }
        else if components.day > 1 {
            return String(format: NSLocalizedString("This week", comment: "Relative date for date in past week."), String(components.day))
        }
        

        if components.hour > 0 || components.minute > 0 {
            return String(format: NSLocalizedString("Today at %@", comment: "Relative date for date older than a minute."), NSDateFormatter.localizedStringFromDate(self, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
        }

        return String(format: NSLocalizedString("Just now", comment: "Description for a tab that was visited within the last few moments."))
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
        return NSDate(timeIntervalSince1970: NSTimeInterval((millisecondsToDecimalSeconds(self) as NSString).doubleValue))
    }
}
