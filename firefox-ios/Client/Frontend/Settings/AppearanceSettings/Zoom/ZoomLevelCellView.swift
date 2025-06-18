// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import Storage

struct ZoomLevelCellView: View {
    private let domainZoomLevel: DomainZoomLevel
    private let textColor: Color

    private struct UX {
        static let textPadding: CGFloat = 16
    }

    init(domainZoomLevel: DomainZoomLevel, textColor: Color) {
        self.domainZoomLevel = domainZoomLevel
        self.textColor = textColor
    }

    var body: some View {
        HStack {
            Text(domainZoomLevel.host)
                .font(.body)
                .foregroundColor(textColor)

            Spacer()

            Text(ZoomLevel(from: domainZoomLevel.zoomLevel).displayName)
                .font(.body)
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UX.textPadding)
        .listRowBackground(Color.clear)
    }
}
