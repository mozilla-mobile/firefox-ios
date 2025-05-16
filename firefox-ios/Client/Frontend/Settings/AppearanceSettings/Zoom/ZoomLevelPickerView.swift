// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

struct ZoomLevelPickerView: View {
    @State private var selectedZoomLevel: ZoomLevel
    private let theme: Theme

    var textColor: Color {
        return theme.colors.textPrimary.color
    }

    var pickerText: String {
        return .Settings.Appearance.PageZoom.ZoomLevelSelectorTitle
    }

    init(theme: Theme) {
        self.theme = theme
        let currentZoom = ZoomLevel(from: ZoomLevelStore.shared.getDefaultZoom())
        _selectedZoomLevel = State(initialValue: currentZoom)
    }

    var body: some View {
        List {
            Picker(pickerText, selection: $selectedZoomLevel) {
                ForEach(ZoomLevel.allCases, id: \.self) { item in
                    Text(item.displayName)
                        .font(.body)
                        .foregroundColor(textColor)
                        .tag(item)
                }
            }
            .accentColor(textColor)
            .pickerStyle(.menu)
            .onChange(of: selectedZoomLevel) { newValue in
                print("YRD --- New selected zoom level: \(newValue)")
                ZoomLevelStore.shared.saveDefaultZoomLevel(defaultZoom: newValue.rawValue)
            }
        }
    }
}
