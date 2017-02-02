/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Snap

class LoginViewController: UIViewController {
    var accountManager: AccountProfileManager!

    override func loadView() {
        view = LoginView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let loginView = view as LoginView

        loginView.didClickLogin = { [unowned self] in
            self.accountManager.login(loginView.username, password: loginView.password, { err in
                switch err {
                case .badAuth:
                    println("Invalid username and/or password")
                default:
                    println("Connection error")
                }
            })
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
