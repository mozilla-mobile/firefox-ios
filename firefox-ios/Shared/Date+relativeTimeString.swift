// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension Date {
    func toRelativeTimeString(
        dateStyle: DateFormatter.Style = .short,
        timeStyle: DateFormatter.Style = .short
    ) -> String {
        let now = Date()

        let units: Set<Calendar.Component> = [.second, .minute, .day, .weekOfYear, .month, .year, .hour]
        let components = Calendar.current.dateComponents(units, from: self, to: now)

        if components.year ?? 0 > 0 {
            return String(
                format: DateFormatter.localizedString(
                    from: self,
                    dateStyle: dateStyle,
                    timeStyle: timeStyle
                )
            )
        }

        if components.month == 1 {
            return String(format: .TimeConstantMoreThanAMonth)
        }

        if components.month ?? 0 > 1 {
            return String(
                format: DateFormatter.localizedString(
                    from: self,
                    dateStyle: dateStyle,
                    timeStyle: timeStyle
                )
            )
        }

        if components.weekOfYear ?? 0 > 0 {
            return String(format: .TimeConstantMoreThanAWeek)
        }

        if components.day == 1 {
            return String(format: .TimeConstantYesterday)
        }

        if components.day ?? 0 > 1 {
            return String(format: .TimeConstantThisWeek, String(describing: components.day))
        }

        if components.hour ?? 0 > 0 || components.minute ?? 0 > 0 {
            // Can't have no time specified for this formatting case.
            let timeStyle = timeStyle != .none ? timeStyle : .short
            let absoluteTime = DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: timeStyle)
            return String(format: .TimeConstantRelativeToday, absoluteTime)
        }

        return String(format: .TimeConstantJustNow)
    }
}
