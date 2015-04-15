/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public typealias Timestamp = UInt64

public let OneMonthInMilliseconds = 30 * OneDayInMilliseconds
public let OneWeekInMilliseconds = 7 * OneDayInMilliseconds
public let OneDayInMilliseconds = 24 * OneHourInMilliseconds
public let OneHourInMilliseconds = 60 * OneMinuteInMilliseconds
public let OneMinuteInMilliseconds: Timestamp = 60 * 1000

extension NSDate {
    public class func now() -> Timestamp {
        return UInt64(1000 * NSDate().timeIntervalSince1970)
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