/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

typealias UIAlertActionCallback = (UIAlertAction) -> Void

// MARK: - Extension methods for building specific UIAlertController instances used across the app
extension UIAlertController {

    /**
    Builds the Alert view that asks the user if they wish to opt into crash reporting.

    - parameter sendReportCallback: Send report option handler
    - parameter alwaysSendCallback: Always send option handler
    - parameter dontSendCallback:   Dont send option handler
    - parameter neverSendCallback:  Never send option handler

    - returns: UIAlertController for opting into crash reporting after a crash occurred
    */
    class func crashOptInAlert(
        sendReportCallback sendReportCallback: UIAlertActionCallback,
        alwaysSendCallback: UIAlertActionCallback,
        dontSendCallback: UIAlertActionCallback) -> UIAlertController {

        let alert = UIAlertController(
            title: NSLocalizedString("Oops! Firefox crashed", comment: "Title for prompt displayed to user after the app crashes"),
            message: NSLocalizedString("Send a crash report so Mozilla can fix the problem?", comment: "Message displayed in the crash dialog above the buttons used to select when sending reports"),
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let sendReport = UIAlertAction(
            title: NSLocalizedString("Send Report", comment: "Used as a button label for crash dialog prompt"),
            style: UIAlertActionStyle.Default,
            handler: sendReportCallback
        )

        let alwaysSend = UIAlertAction(
            title: NSLocalizedString("Always Send", comment: "Used as a button label for crash dialog prompt"),
            style: UIAlertActionStyle.Default,
            handler: alwaysSendCallback
        )

        let dontSend = UIAlertAction(
            title: NSLocalizedString("Don't Send", comment: "Used as a button label for crash dialog prompt"),
            style: UIAlertActionStyle.Default,
            handler: dontSendCallback
        )

        alert.addAction(sendReport)
        alert.addAction(alwaysSend)
        alert.addAction(dontSend)

        return alert
    }

    /**
    Builds the Alert view that asks the user if they wish to restore their tabs after a crash.

    - parameter okayCallback: Okay option handler
    - parameter noCallback:   No option handler

    - returns: UIAlertController for asking the user to restore tabs after a crash
    */
    class func restoreTabsAlert(okayCallback okayCallback: UIAlertActionCallback, noCallback: UIAlertActionCallback) -> UIAlertController {
        let alert = UIAlertController(
            title: NSLocalizedString("Well, this is embarrassing.", comment: "Restore Tabs Prompt Title"),
            message: NSLocalizedString("Looks like Firefox crashed previously. Would you like to restore your tabs?", comment: "Restore Tabs Prompt Description"),
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let noOption = UIAlertAction(
            title: NSLocalizedString("No", comment: "Restore Tabs Negative Action"),
            style: UIAlertActionStyle.Cancel,
            handler: noCallback
        )

        let okayOption = UIAlertAction(
            title: NSLocalizedString("Okay", comment: "Restore Tabs Affirmative Action"),
            style: UIAlertActionStyle.Default,
            handler: okayCallback
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)
        return alert
    }
}
