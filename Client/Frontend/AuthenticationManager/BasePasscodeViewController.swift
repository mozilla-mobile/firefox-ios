/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper

class BasePasscodeViewController: UIViewController {
    var authenticationInfo: AuthenticationKeychainInfo?

    var errorToast: ErrorToast?
    let errorPadding: CGFloat = 10

    init() {
        self.authenticationInfo = KeychainWrapper.authenticationInfo()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: Selector("dismiss"))
        automaticallyAdjustsScrollViewInsets = false
    }

    func displayError(text: String) {
        errorToast?.removeFromSuperview()
        errorToast = {
            let toast = ErrorToast()
            toast.textLabel.text = text
            view.addSubview(toast)
            toast.snp_makeConstraints { make in
                make.center.equalTo(self.view)
                make.left.greaterThanOrEqualTo(self.view).offset(errorPadding)
                make.right.lessThanOrEqualTo(self.view).offset(-errorPadding)
            }
            return toast
        }()
    }

    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}