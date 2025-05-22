// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

struct ZoomSiteListView: View {
    let theme: Theme
    @Binding var domainZoomLevels: [DomainZoomLevel]
    let onDelete: (IndexSet) -> Void

    private struct UX {
        static var sectionPadding: CGFloat = 16
        static var footerBottomPadding: CGFloat = 40
        static var footerTopPadding: CGFloat = 8
    }

    var cellBackground: Color {
        return theme.colors.layer5.color
    }

    var sectionBackground: Color {
        return theme.colors.layer1.color
    }

    init(theme: Theme,
         domainZoomLevels: Binding<[DomainZoomLevel]>,
         onDelete: @escaping (IndexSet) -> Void) {
        self.theme = theme
        self._domainZoomLevels = domainZoomLevels
        self.onDelete = onDelete
    }

    var body: some View {
        Section {
            ForEach(domainZoomLevels, id: \.host) { zoomItem in
                ZStack {
                    cellBackground
                    ZoomLevelCellView(domainZoomLevel: zoomItem,
                                      textColor: theme.colors.textPrimary.color)
                    .padding([.leading, .trailing], UX.sectionPadding)
                }
            }
            .onDelete(perform: onDelete)
            .background(cellBackground)

            // Footer as a final row
            footerView()
        } header: {
            GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.SpecificSiteSectionHeader.uppercased(),
                                     sectionTitleColor: theme.colors.textSecondary.color)
                .padding([.leading, .trailing], UX.sectionPadding)
        }
    }

    private func footerView() -> some View {
        ZStack {
            sectionBackground

            Text(String.Settings.Appearance.PageZoom.SpecificSiteFooterTitle)
                .font(.caption)
                .foregroundColor(theme.colors.textSecondary.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: UX.footerTopPadding,
                                    leading: UX.sectionPadding,
                                    bottom: UX.footerBottomPadding,
                                    trailing: UX.sectionPadding))
        }
        .background(sectionBackground)
    }
}
