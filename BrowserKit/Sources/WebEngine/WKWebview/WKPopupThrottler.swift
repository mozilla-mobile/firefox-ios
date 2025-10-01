// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
public protocol WKPopupThrottler {
    func canShowAlert(type: WKPopupType) -> Bool

    func willShowAlert(type: WKPopupType)
}

public enum WKPopupType {
    /// Javascript alert()
    case alert
    /// Popup window (window.open)
    case popupWindow

    /// Max consecutive popups allowed within a given time period (below)
    /// after which throttling begins.
    var maxPopupThreshold: Int {
        switch self {
        case .alert: return 5
        case .popupWindow: return 2
        }
    }

    /// The time within which the popup threshold may be reached. After this
    /// many seconds since the first alert, the time and alert count are reset.
    var resetTime: TimeInterval {
        switch self {
        case .alert: return 20
        case .popupWindow: return 2
        }
    }

    public static let defaultResetTimes = [WKPopupType.alert: WKPopupType.alert.resetTime,
                                           WKPopupType.popupWindow: WKPopupType.popupWindow.resetTime]
}

/// Utility for tracking various types of popups that may be presented
/// over a short time. Used to prevent Javascript abuse or DOS attacks.
public final class DefaultPopupThrottler: WKPopupThrottler {
    private var alertCount = [WKPopupType.alert: 0, WKPopupType.popupWindow: 0]
    private var lastAlertDate = [WKPopupType.alert: Date.distantPast, WKPopupType.popupWindow: Date.distantPast]
    private let resetTime: [WKPopupType: TimeInterval]

    public init(resetTime: [WKPopupType: TimeInterval] = WKPopupType.defaultResetTimes) {
        self.resetTime = resetTime
    }

    // MARK: - Public API

    public func canShowAlert(type: WKPopupType) -> Bool {
        guard let count = alertCount[type] else { return true }
        guard let date = lastAlertDate[type] else { return true }
        guard let time = resetTime[type] else { return true }

        let alertCountOK = count < type.maxPopupThreshold
        let timeOK = date.timeIntervalSinceNow < (time * -1.0)
        return alertCountOK || timeOK
    }

    public func willShowAlert(type: WKPopupType) {
        guard let count = alertCount[type] else { return }
        guard let date = lastAlertDate[type] else { return }
        guard let time = resetTime[type] else { return }

        let timeSinceLastAlert = date.timeIntervalSinceNow * -1.0
        if timeSinceLastAlert >= time {
            // Our reasonable time limit has passed, which means we can reset our
            // alert count and allow any further alerts.
            alertCount[type] = 1
            lastAlertDate[type] = Date()
        } else {
            alertCount[type] = count + 1
        }
    }
}
