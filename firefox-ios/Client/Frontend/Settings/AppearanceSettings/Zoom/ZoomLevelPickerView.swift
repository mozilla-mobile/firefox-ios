// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct ZoomLevelPickerView: View {
    @State private var selectedZoomLevel: ZoomLevel
    private let theme: Theme
    private let zoomManager: ZoomPageManager

    private struct UX {
        static var sectionPadding: CGFloat { 16 }
    }

    var backgroundColor: Color {
        return theme.colors.layer5.color
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
            ZStack {
                backgroundColor

                Picker(pickerText, selection: $selectedZoomLevel) {
                    ForEach(ZoomLevel.allCases, id: \.self) { item in
                        Text(item.displayName)
                            .font(.body)
                            .foregroundColor(theme.colors.textSecondary.color)
                            .tag(item)
                    }
                }
                .accentColor(theme.colors.textPrimary.color)
                .pickerStyle(.menu)
                .onChange(of: selectedZoomLevel) { newValue in
                    zoomManager.saveDefaultZoomLevel(defaultZoom: newValue.rawValue)
                }
                .padding([.leading, .trailing], UX.sectionPadding)
                .background(backgroundColor)
            }
        }
        header: {
            GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.DefaultSectionHeader.uppercased(),
                                     sectionTitleColor: theme.colors.textSecondary.color)
            .background(theme.colors.layer1.color)
            .padding([.leading, .trailing], UX.sectionPadding)
        }
    }
}
