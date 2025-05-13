// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

struct ZoomLevelCellView: View {
    var textColor: Color {
        return Color(theme.colors.textPrimary)
    }

    private let theme: Theme
    let domainZoomLevel: DomainZoomLevel

    init(theme: Theme, domainZoomLevel: DomainZoomLevel) {
        self.theme = theme
        self.domainZoomLevel = domainZoomLevel
    }

    var body: some View {
        HStack {
            Text(domainZoomLevel.host)
                .font(.body)
                .foregroundColor(textColor)

            Spacer()

            Text(ZoomLevel(from: domainZoomLevel.zoomLevel).displayName)
                .padding([.trailing], 10)
                .font(.body)
                .foregroundColor(textColor)
        }
    }
}
