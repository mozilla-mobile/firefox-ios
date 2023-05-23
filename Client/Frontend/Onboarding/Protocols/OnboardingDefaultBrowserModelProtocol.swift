// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingDefaultBrowserModelProtocol {
    var title: String { get set }
    var instructionSteps: [String] { get set }
    var buttonTitle: String { get set }
    var a11yIdRoot: String { get set }

    init(title: String,
         instructionSteps: [String],
         buttonTitle: String,
         a11yIdRoot: String)

    func getAttributedStrings(with font: UIFont) -> [NSAttributedString]
}
