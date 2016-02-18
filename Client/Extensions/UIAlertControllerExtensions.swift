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

    class func clearPrivateDataAlert(okayCallback: () -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: NSLocalizedString("Clear Private Data", tableName: "ClearPrivateDataConfirm", comment: "Title of the confirmation dialog shown when a user tries to clear private data."),
            message: NSLocalizedString("This action will clear all of your private data. It cannot be undone.", tableName: "ClearPrivateDataConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear their private data."),
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let noOption = UIAlertAction(
            title: NSLocalizedString("Cancel", tableName: "ClearPrivateDataConfirm", comment: "The cancel button when confirming clear private data."),
            style: UIAlertActionStyle.Cancel,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: NSLocalizedString("Clear", tableName: "ClearPrivateDataConfirm", comment: "The button that clears private data."),
            style: UIAlertActionStyle.Destructive,
            handler: {_ in okayCallback() }
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)
        return alert
    }

    /**
     Builds the Alert view that asks if the users wants to also delete history stored on their other devices.
     
     - parameter okayCallback: Okay option handler.

     - returns: UIAlertController for asking the user to restore tabs after a crash
     */

    class func clearSyncedHistoryAlert(okayCallback: () -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: NSLocalizedString("Remove history from your Firefox Account?", tableName: "ClearHistoryConfirm", comment: "Title of the confirmation dialog shown when a user tries to clear history that's synced to another device."),
            message: NSLocalizedString("This action will clear all of your private data, including history from all your synced devices. It cannot be undone.", tableName: "ClearHistoryConfirm", comment: "Description of the confirmation dialog shown when a user tries to clear history that's synced to another device."),
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let noOption = UIAlertAction(
            title: NSLocalizedString("Cancel", tableName: "ClearHistoryConfirm", comment: "The cancel button when confirming clear history."),
            style: UIAlertActionStyle.Cancel,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: NSLocalizedString("Clear", tableName: "ClearHistoryConfirm", comment: "The button that clears history even when Sync is connected."),
            style: UIAlertActionStyle.Destructive,
            handler: {_ in okayCallback() }
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)
        return alert
    }

    /**
     Creates an alert view to warn the user that their logins will either be completely deleted in the 
     case of local-only logins or deleted across synced devices in synced account logins.

     - parameter deleteCallback: Block to run when delete is tapped.
     - parameter hasSyncedLogins: Boolean indicating the user has logins that have been synced.

     - returns: UIAlertController instance
     */
    class func deleteLoginAlertWithDeleteCallback(
        deleteCallback: UIAlertActionCallback,
        hasSyncedLogins: Bool) -> UIAlertController {

        let areYouSureTitle = NSLocalizedString("Are you sure?",
            tableName: "LoginManager",
            comment: "Prompt title when deleting logins")
        let deleteLocalMessage = NSLocalizedString("Logins will be permanently removed.",
            tableName: "LoginManager",
            comment: "Prompt message warning the user that deleting non-synced logins will permanently remove them")
        let deleteSyncedDevicesMessage = NSLocalizedString("Logins will be removed from all connected devices.",
            tableName: "LoginManager",
            comment: "Prompt message warning the user that deleted logins will remove logins from all connected devices")
        let cancelActionTitle = NSLocalizedString("Cancel",
            tableName: "LoginManager",
            comment: "Prompt option for cancelling out of deletion")
        let deleteActionTitle = NSLocalizedString("Delete",
            tableName: "LoginManager",
            comment: "Button in login detail screen that deletes the current login")

        let deleteAlert: UIAlertController
        if hasSyncedLogins {
            deleteAlert = UIAlertController(title: areYouSureTitle, message: deleteSyncedDevicesMessage, preferredStyle: .Alert)
        } else {
            deleteAlert = UIAlertController(title: areYouSureTitle, message: deleteLocalMessage, preferredStyle: .Alert)
        }

        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        let deleteAction = UIAlertAction(title: deleteActionTitle, style: .Destructive, handler: deleteCallback)

        deleteAlert.addAction(cancelAction)
        deleteAlert.addAction(deleteAction)

        return deleteAlert
    }
}
