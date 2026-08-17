// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

struct ZoomSiteListView: View {
    let theme: Theme
    @Binding var domainZoomLevels: [DomainZoomLevel]
    @State private var measuredListHeight: CGFloat = 0
    private let onDelete: (IndexSet) -> Void
    private let resetDomain: () -> Void

    private struct UX {
        static let sectionPadding: CGFloat = 16
        static let footerBottomPadding: CGFloat = 32
        static let footerTopPadding: CGFloat = 8
        static let cellHeight: CGFloat = 48
        static let listPadding: CGFloat = 5
        static let dividerHeight: CGFloat = 0.5
        static let cornerRadius: CGFloat = 24
    }

    private struct ListHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value += nextValue()
        }
    }

    @ScaledMetric(relativeTo: .body)
    private var fallbackRowHeight: CGFloat = UX.cellHeight + UX.listPadding

    var cellBackground: Color {
        return theme.colors.layer5.color
    }

    var sectionBackground: Color {
        return theme.colors.layer1.color
    }

    var footerTopPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return 0
        } else {
            return UX.footerTopPadding
        }
    }

    var listViewHeight: CGFloat {
        if measuredListHeight > 0 {
            return measuredListHeight
        }

        return CGFloat(domainZoomLevels.count) * fallbackRowHeight
    }

    init(theme: Theme,
         domainZoomLevels: Binding<[DomainZoomLevel]>,
         onDelete: @escaping (IndexSet) -> Void,
         resetDomain: @escaping () -> Void) {
        self.theme = theme
        self._domainZoomLevels = domainZoomLevels
        self.onDelete = onDelete
        self.resetDomain = resetDomain
    }

    var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 26.0, *) {
                GenericSectionView(
                    theme: theme,
                    title: .Settings.Appearance.PageZoom.SpecificSiteSectionHeader,
                    identifier: AccessibilityIdentifiers.Settings.Appearance.specificSiteSettings
                ) {
                    zoomSitesListView
                }
            } else {
                // Header
                GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.SpecificSiteSectionHeader.uppercased(),
                                         sectionTitleColor: theme.colors.textSecondary.color)
                    .padding([.leading, .trailing, .top], UX.sectionPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(sectionBackground)

                // Top divider for the list
                Divider()
                    .frame(height: UX.dividerHeight)
                    .background(theme.colors.borderPrimary.color)

                zoomSitesListView
            }

            // Footer
            Text(String.Settings.Appearance.PageZoom.SpecificSiteFooterTitle)
                .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
                .foregroundColor(theme.colors.textSecondary.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: footerTopPadding,
                                    leading: UX.sectionPadding,
                                    bottom: UX.footerBottomPadding,
                                    trailing: UX.sectionPadding))
                .background(sectionBackground)

            // Reset button
            GenericButtonCellView(theme: theme,
                                  title: String.Settings.Appearance.PageZoom.ResetButtonTitle,
                                  onTap: resetDomain)
                .modifier(ResetButtonStyle(theme: theme))
        }
    }

    private var zoomSitesListView: some View {
        List {
            ForEach(domainZoomLevels, id: \.host) { zoomItem in
                ZoomLevelCellView(domainZoomLevel: zoomItem,
                                  textColor: theme.colors.textPrimary.color)
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ListHeightPreferenceKey.self,
                                value: geometry.size.height
                            )
                    }
                }
                .listRowBackground(cellBackground)
                .listRowInsets(EdgeInsets())
                .modifier(CellStyle(theme: theme))
            }
            .onDelete(perform: onDelete)
        }
        .frame(height: listViewHeight)
        .listStyle(.plain)
        .modifier(ListStyle(theme: theme, cellBackground: cellBackground))
        .onPreferenceChange(ListHeightPreferenceKey.self) { height in
            guard height > 0 else { return }

            measuredListHeight = height
        }
    }

    private struct CellStyle: ViewModifier {
        let theme: Theme?

        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
            } else {
                content
                    .background(theme?.colors.layer5.color)
            }
        }
    }

    private struct ListStyle: ViewModifier {
        let theme: Theme?
        let cellBackground: Color

        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
                    .modifier(
                        SectionStyle(
                            theme: theme,
                            cornerRadius: UX.cornerRadius
                        )
                    )
            } else {
                content
                    .background(cellBackground)
            }
        }
    }

    private struct ResetButtonStyle: ViewModifier {
        let theme: Theme?

        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
                    .frame(maxWidth: .infinity)
                    .modifier(
                        SectionStyle(
                            theme: theme,
                            cornerRadius: UX.cornerRadius
                        )
                    )
            } else {
                content
                    .background(theme?.colors.layer5.color)
            }
        }
    }
}
