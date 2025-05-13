// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

struct ZoomLevelCellView: View {
    private let theme: Theme
    private let domainZoomLevel: DomainZoomLevel

    private struct UX {
        static var dividerHeight: CGFloat { 0.7 }
        static var buttonPadding: CGFloat { 4 }
        static var textPadding: CGFloat { 10 }
    }

    var textColor: Color {
        return theme.colors.textPrimary.color
    }

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
                .padding([.trailing], UX.textPadding)
                .font(.body)
                .foregroundColor(textColor)
        }
    }
}
