// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared

class CreditCardSettingsViewController: UIViewController, ThemeApplicable {
    var themeObserver: NSObjectProtocol?
    var theme: Theme

    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        view.backgroundColor = theme.colors.layer1
    }
}
