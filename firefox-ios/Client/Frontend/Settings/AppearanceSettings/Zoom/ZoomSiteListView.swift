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

    var textColor: Color {
        return theme.colors.textPrimary.color
    }

    init(theme: Theme,
         domainZoomLevels: Binding<[DomainZoomLevel]>,
         onDelete: @escaping (IndexSet) -> Void) {
        self.theme = theme
        self._domainZoomLevels = domainZoomLevels
        self.onDelete = onDelete
    }

    var body: some View {
        ForEach(domainZoomLevels, id: \.host) { zoomItem in
            ZoomLevelCellView(theme: theme, domainZoomLevel: zoomItem)
        }
        .onDelete(perform: onDelete)
    }
}
