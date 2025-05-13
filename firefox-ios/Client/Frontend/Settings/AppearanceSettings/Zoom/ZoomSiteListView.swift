// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

struct ZoomSiteListView: View {
    private struct UX {
        static let spacing: CGFloat = 24
    }

    var textColor: Color {
        return Color(theme.colors.textPrimary)
    }

    let theme: Theme
    let zoomLevels: [DomainZoomLevel]

    init(theme: Theme,
         zoomStore: ZoomLevelStorage = ZoomLevelStore.shared) {
        self.theme = theme
        zoomLevels = zoomStore.loadAll()
    }

    var body: some View {
        ForEach(zoomLevels, id: \.host) { zoomItem in
            ZoomLevelCellView(theme: theme, domainZoomLevel: zoomItem)
        }
        .onDelete(perform: delete)
    }

    func delete(at index: IndexSet) {
    }
}
