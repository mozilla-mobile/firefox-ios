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
        static var sectionPadding: CGFloat = 16
    }

    private var sectionBackground: Color {
        return theme.colors.layer1.color
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
        VStack {
            GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.DefaultSectionHeader.uppercased(),
                                     sectionTitleColor: theme.colors.textSecondary.color)
                .padding([.leading, .trailing, .top], UX.sectionPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionBackground)

            defaultZoomPicker
        }
    }

    var defaultZoomPicker: some View {
        HStack {
            Text(pickerText)
                .font(.body)
                .foregroundColor(theme.colors.textPrimary.color)

            Spacer()

            // Right side - picker with current value
            Menu {
                Picker(selection: $selectedZoomLevel, label: EmptyView()) {
                    ForEach(ZoomLevel.allCases, id: \.self) { item in
                        Text(item.displayName)
                            .tag(item)
                    }
                }
                .onChange(of: selectedZoomLevel) { newValue in
                    zoomManager.saveDefaultZoomLevel(defaultZoom: newValue.rawValue)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                HStack(spacing: 4) {
                    Text(selectedZoomLevel.displayName)
                        .font(.body)
                        .foregroundColor(theme.colors.textPrimary.color)

                    Image(StandardImageIdentifiers.Large.chevronDown)
                        .renderingMode(.template)
                        .font(.caption)
                        .foregroundColor(theme.colors.textPrimary.color)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, UX.sectionPadding)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
    }
}
