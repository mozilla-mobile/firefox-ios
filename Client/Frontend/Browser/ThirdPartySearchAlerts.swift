/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class ThirdPartySearchAlerts: UIAlertController {

    /**
    Allows the keyboard to pop back up after an alertview.
    **/
    override func canBecomeFirstResponder() -> Bool {
        return false
    }

    /**
     Builds the Alert view that asks if the users wants to add a third party search engine.

     - parameter okayCallback: Okay option handler.

     - returns: UIAlertController for asking the user to add a search engine
     **/

    static func addThirdPartySearchEngine(_ okayCallback: (UIAlertAction) -> Void) -> UIAlertController {
        let alert = ThirdPartySearchAlerts(
            title: Strings.ThirdPartySearchAddTitle,
            message: Strings.ThirdPartySearchAddMessage,
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let noOption = UIAlertAction(
            title: Strings.ThirdPartySearchCancelButton,
            style: UIAlertActionStyle.Cancel,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: Strings.ThirdPartySearchOkayButton,
            style: UIAlertActionStyle.Default,
            handler: okayCallback
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)

        return alert
    }

    /**
     Builds the Alert view that shows the user an error in case a search engine could not be added.

     - returns: UIAlertController with an error dialog
     **/

    static func failedToAddThirdPartySearch() -> UIAlertController {
        let alert = ThirdPartySearchAlerts(
            title: Strings.ThirdPartySearchFailedTitle,
            message: Strings.ThirdPartySearchFailedMessage,
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let okayOption = UIAlertAction(
            title: Strings.ThirdPartySearchOkayButton,
            style: UIAlertActionStyle.Default,
            handler: nil
        )

        alert.addAction(okayOption)
        return alert
    }

}
