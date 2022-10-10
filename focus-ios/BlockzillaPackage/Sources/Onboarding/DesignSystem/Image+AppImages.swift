// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public extension Image {
    static let logo = Image("icon_logo", bundle: Bundle.module)
    static let close = Image("icon_close", bundle: Bundle.module)
    static let background = Image("icon_background", bundle: Bundle.module)
    static let jiggleModeImage = Image("jiggle_mode_image", bundle: Bundle.module)
    static let huggingFocus = Image("icon_hugging_focus", bundle: .module)
    static let stepOneImage = Image(systemName: "1.circle.fill")
    static let stepTwoImage = Image(systemName: "2.circle.fill")
    static let stepThreeImage = Image(systemName: "3.circle.fill")
}
