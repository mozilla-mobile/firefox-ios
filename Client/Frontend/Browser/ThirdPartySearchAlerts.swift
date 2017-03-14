/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class ThirdPartySearchAlerts: UIAlertController {

    /**
    Allows the keyboard to pop back up after an alertview.
    **/
    override var canBecomeFirstResponder: Bool {
        return false
    }

    /**
     Builds the Alert view that asks if the users wants to add a third party search engine.

     - parameter okayCallback: Okay option handler.

     - returns: UIAlertController for asking the user to add a search engine
     **/

    static func addThirdPartySearchEngine(_ okayCallback: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = ThirdPartySearchAlerts(
            title: Strings.ThirdPartySearchAddTitle,
            message: Strings.ThirdPartySearchAddMessage,
            preferredStyle: UIAlertControllerStyle.alert
        )

        let noOption = UIAlertAction(
            title: Strings.ThirdPartySearchCancelButton,
            style: UIAlertActionStyle.cancel,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: Strings.ThirdPartySearchOkayButton,
            style: UIAlertActionStyle.default,
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
        return searchAlertWithOK(title: Strings.ThirdPartySearchFailedTitle,
                                 message: Strings.ThirdPartySearchFailedMessage)
    }
    
    static func incorrectCustomEngineForm() -> UIAlertController {
        return searchAlertWithOK(title: Strings.CustomEngineFormErrorTitle,
                                      message: Strings.CustomEngineFormErrorMessage)
    }
    
    static func duplicateCustomEngine() -> UIAlertController {
        return searchAlertWithOK(title: Strings.CustomEngineDuplicateErrorTitle,
                                 message: Strings.CustomEngineDuplicateErrorMessage)
    }
    
    private static func searchAlertWithOK(title: String, message: String) -> UIAlertController {
        let alert = ThirdPartySearchAlerts(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        let okayOption = UIAlertAction(
            title: Strings.ThirdPartySearchOkayButton,
            style: UIAlertActionStyle.default,
            handler: nil
        )
        
        alert.addAction(okayOption)
        return alert
    }

}
