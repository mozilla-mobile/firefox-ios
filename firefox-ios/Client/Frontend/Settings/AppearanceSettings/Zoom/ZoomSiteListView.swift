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
        static var sectionPadding: CGFloat { 16 }
    }

    var textColor: Color {
        return theme.colors.textPrimary.color
    }
    var cellBackground: Color {
        return theme.colors.layer2.color
    }

    var sectionTitleColor: Color {
        return theme.colors.textSecondary.color
    }

    var footerTextColor: Color {
        return theme.colors.textSecondary.color
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
                ZoomLevelCellView(domainZoomLevel: zoomItem, textColor: textColor)
            }
            .onDelete(perform: onDelete)
            .background(cellBackground)
        } header: {
            GenericSectionHeaderView(title: .Settings.Appearance.PageZoom.SpecificSiteSectionHeader.uppercased(),
                                     sectionTitleColor: sectionTitleColor)
        } footer: {
            footerView()
        }
    }

    private func footerView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String.Settings.Appearance.PageZoom.SpecificSiteFooterTitle)
                .font(.caption)
                .padding([.leading, .trailing], UX.sectionPadding)
                .foregroundColor(footerTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowInsets(EdgeInsets())
    }
}
