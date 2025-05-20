// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct ZoomLevelPickerView: View {
    @State private var selectedZoomLevel: ZoomLevel
    private let theme: Theme
    private let zoomManager: ZoomPageManager

    var textColor: Color {
        return theme.colors.textPrimary.color
    }

    var backgroundColor: Color {
        return theme.colors.layer1.color
    }

    var sectionTitleColor: Color {
        return theme.colors.textSecondary.color
    }

    var pickerText: String {
        return .Settings.Appearance.PageZoom.ZoomLevelSelectorTitle
    }

    init(theme: Theme, zoomManager: ZoomPageManager) {
        self.theme = theme
        self.zoomManager = zoomManager
        let currentZoom = ZoomLevel(from: zoomManager.defaultZoomLevel)
        _selectedZoomLevel = State(initialValue: currentZoom)
    }

    var body: some View {
        Section {
            Picker(pickerText, selection: $selectedZoomLevel) {
                ForEach(ZoomLevel.allCases, id: \.self) { item in
                    Text(item.displayName)
                        .font(.body)
                        .foregroundColor(textColor)
                        .tag(item)
                }
            }
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .accentColor(textColor)
            .pickerStyle(.menu)
            .onChange(of: selectedZoomLevel) { newValue in
                zoomManager.saveDefaultZoomLevel(defaultZoom: newValue.rawValue)
            }
        }
        header: {
            GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.DefaultSectionHeader.uppercased(),
                                     sectionTitleColor: sectionTitleColor)
        }
    }
}
