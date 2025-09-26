// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct ZoomLevelPickerView: View {
    @State private var selectedZoomLevel: ZoomLevel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let theme: Theme
    private let zoomManager: ZoomPageManager
    private let onZoomLevelChanged: (ZoomLevel) -> Void

    private struct UX {
        static let chevronImageIdentifier = "chevron.down"
        static let sectionPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let dividerHeight: CGFloat = 0.5
        static let pickerLabelSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 24
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

    init(theme: Theme, zoomManager: ZoomPageManager, onZoomLevelChanged: @escaping(ZoomLevel) -> Void) {
        self.theme = theme
        self.zoomManager = zoomManager
        self.onZoomLevelChanged = onZoomLevelChanged
        let currentZoom = ZoomLevel(from: zoomManager.defaultZoomLevel)
        _selectedZoomLevel = State(initialValue: currentZoom)
    }

    var body: some View {
        Section(
            content: {
                if #available(iOS 26.0, *) {
                    pickerContent
                        .background(
                            RoundedRectangle(cornerRadius: UX.cornerRadius, style: .continuous)
                                .fill(Color(theme.colors.layer2))
                        )
                } else {
                    VStack(spacing: .zero) {
                        Divider()
                            .frame(height: UX.dividerHeight)
                            .background(theme.colors.borderPrimary.color)
                        pickerContent
                        Divider()
                            .frame(height: UX.dividerHeight)
                            .background(theme.colors.borderPrimary.color)
                    }
                }
            },
            header: {
                if #available(iOS 26.0, *) {
                    GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.DefaultSectionHeader.uppercased(),
                                             sectionTitleColor: theme.colors.textSecondary.color)
                } else {
                    GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.DefaultSectionHeader.uppercased(),
                                             sectionTitleColor: theme.colors.textSecondary.color)
                    .padding([.leading, .trailing, .top], UX.sectionPadding)
                    .background(sectionBackground)
               }
            }
        )
    }

    @ViewBuilder
    var pickerContent: some View {
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                horizontalView
                verticalView
            }
        } else if dynamicTypeSize.isAccessibilitySize {
            verticalView
        } else {
            horizontalView
        }
    }

    var horizontalView: some View {
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
                .onChange(of: selectedZoomLevel, perform: onZoomLevelChanged)
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                HStack(spacing: UX.pickerLabelSpacing) {
                    Text(selectedZoomLevel.displayName)
                        .font(.body)
                        .foregroundColor(theme.colors.textPrimary.color)

                    Image(systemName: UX.chevronImageIdentifier)
                        .renderingMode(.template)
                        .font(.caption)
                        .foregroundColor(theme.colors.textPrimary.color)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, UX.sectionPadding)
        .padding(.vertical, UX.verticalPadding)
    }

    var verticalView: some View {
        VStack {
            HStack {
                Text(pickerText)
                    .font(.body)
                    .foregroundColor(theme.colors.textPrimary.color)

                Spacer()
            }
            .padding(.horizontal, UX.sectionPadding)
            HStack {
                Spacer()

                // Right side - picker with current value
                Menu {
                    Picker(selection: $selectedZoomLevel, label: EmptyView()) {
                        ForEach(ZoomLevel.allCases, id: \.self) { item in
                            Text(item.displayName)
                                .tag(item)
                        }
                    }
                    .onChange(of: selectedZoomLevel, perform: onZoomLevelChanged)
                    .pickerStyle(.inline)
                    .labelsHidden()
                } label: {
                    HStack(spacing: UX.pickerLabelSpacing) {
                        Text(selectedZoomLevel.displayName)
                            .font(.body)
                            .foregroundColor(theme.colors.textPrimary.color)

                        Image(systemName: UX.chevronImageIdentifier)
                            .renderingMode(.template)
                            .font(.caption)
                            .foregroundColor(theme.colors.textPrimary.color)
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding(.horizontal, UX.sectionPadding)
        }
        .padding(.vertical, UX.verticalPadding)
    }
}
