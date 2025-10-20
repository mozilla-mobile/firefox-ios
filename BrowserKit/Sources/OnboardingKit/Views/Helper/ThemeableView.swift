// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

// TODO: - FXIOS-13873 Bring Themeable View inside Common
@MainActor
protocol ThemeableView: View {
    var theme: Theme { get set }
    var windowUUID: WindowUUID { get }

    func applyTheme()
}

extension View {
    func listenToThemeChanges(onChange: @escaping (WindowUUID?) -> Void) -> some View {
        return self.onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
            onChange($0.windowUUID)
        }
    }
}
