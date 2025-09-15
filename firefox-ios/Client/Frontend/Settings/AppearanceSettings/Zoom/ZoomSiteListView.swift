// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

struct ZoomSiteListView: View {
    let theme: Theme
    @Binding var domainZoomLevels: [DomainZoomLevel]
    private let onDelete: (IndexSet) -> Void
    private let resetDomain: () -> Void

    private struct UX {
        static let sectionPadding: CGFloat = 16
        static let textPadding: CGFloat = 16
        static let footerBottomPadding: CGFloat = 32
        static let footerTopPadding: CGFloat = 8
        static let listPadding: CGFloat = 5
        static let dividerHeight: CGFloat = 0.5
        static let cornerRadius: CGFloat = 24
    }

    var cellBackground: Color {
        return theme.colors.layer5.color
    }

    var sectionBackground: Color {
        return theme.colors.layer1.color
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
        Section(
            content: {
                ForEach(domainZoomLevels, id: \.host) { zoomItem in
                    ZoomLevelCellView(domainZoomLevel: zoomItem,
                                      textColor: theme.colors.textPrimary.color)
                    .modifier(CellStyle(textPadding: UX.textPadding))
                }
                .onDelete(perform: onDelete)
                .listRowInsets(.init())
            },
            header: {
                GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.SpecificSiteSectionHeader.uppercased(),
                                         sectionTitleColor: theme.colors.textSecondary.color)
                .modifier(HeaderStyle(sectionPadding: UX.sectionPadding, sectionBackground: sectionBackground))
            },
            footer: {
                VStack {
                    Text(String.Settings.Appearance.PageZoom.SpecificSiteFooterTitle)
                        .font(.caption)
                        .foregroundColor(theme.colors.textSecondary.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: UX.footerTopPadding,
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
        )
    }

    private struct ResetButtonStyle: ViewModifier {
        let theme: Theme?

        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
                    .frame(maxWidth: .infinity)
                    .modifier(SectionStyle(theme: theme, cornerRadius: UX.cornerRadius))
            } else {
                content
                    .background(theme?.colors.layer5.color)
            }
        }
    }

    private struct HeaderStyle: ViewModifier {
        let sectionPadding: CGFloat
        let sectionBackground: Color

        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
            } else {
                content
                    .padding([.leading, .trailing, .top], sectionPadding)
                    .background(sectionBackground)
            }
        }
    }

    private struct CellStyle: ViewModifier {
        let textPadding: CGFloat

        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
                    .alignmentGuide(.listRowSeparatorTrailing) {
                        $0[.listRowSeparatorTrailing] - textPadding
                    }
            } else {
                content
            }
        }
    }
}
