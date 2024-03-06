// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

extension Gradient {
    static let quickAccessWidget = Gradient(colors: [Color("GradientFirst", bundle: .module), Color("GradientSecond", bundle: .module)])
}

extension Image {
    static let magnifyingGlass = Image(systemName: "magnifyingglass")
    static let logo = Image("icon_logo", bundle: Bundle.module)
}
