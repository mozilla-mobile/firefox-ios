/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper
import LocalAuthentication

extension AppAuthenticator {
    static func presentPasscodeAuthentication(_ presentingNavController: UINavigationController?) -> Deferred<Bool> {
        let deferred = Deferred<Bool>()
        let passcodeVC = PasscodeEntryViewController(passcodeCompletion: { isOk in
            deferred.fill(isOk)
        })

        let navController = UINavigationController(rootViewController: passcodeVC)
        navController.modalPresentationStyle = .formSheet
        presentingNavController?.present(navController, animated: true, completion: nil)
        return deferred
    }
}
