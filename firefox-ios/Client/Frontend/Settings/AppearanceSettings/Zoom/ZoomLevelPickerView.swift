// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct ZoomLevelPickerView: View {
    private struct UX {
        static let spacing: CGFloat = 24
    }

    var textColor: Color {
        return Color(theme.colors.textPrimary)
    }

    var pickerText: String {
        return .ZoomLevelSelectorTitle
    }

    @State private var defaultZoom = "100%"
    private let theme: Theme

    init(theme: Theme) {
        self.theme = theme
    }

    var body: some View {
        Picker(pickerText, selection: $defaultZoom) {
            ForEach(ZoomLevel.allCases, id: \.displayName) { item in
                Text(item.displayName)
                    .font(.body)
                    .foregroundColor(textColor)
            }
        }
        .background(theme.colors.layer2.color)
        .accentColor(textColor)
        .pickerStyle(.menu)
    }

    func applyTheme() {
    }
}
