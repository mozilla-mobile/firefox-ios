// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct ZoomLevelPickerView: View {
    @State private var defaultZoom = "100%"
    private let theme: Theme

    var textColor: Color {
        return theme.colors.textPrimary.color
    }

    var pickerText: String {
        return .Settings.Appearance.PageZoom.ZoomLevelSelectorTitle
    }

    init(theme: Theme) {
        self.theme = theme
    }

    var body: some View {
        List {
            Picker(pickerText, selection: $defaultZoom) {
                ForEach(ZoomLevel.allCases, id: \.displayName) { item in
                    Text(item.displayName)
                        .font(.body)
                        .foregroundColor(textColor)
                }
            }
            .accentColor(textColor)
            .pickerStyle(.menu)
        }
    }
}
