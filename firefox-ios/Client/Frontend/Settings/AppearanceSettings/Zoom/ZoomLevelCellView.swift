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
        if #available(iOS 16, *) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    domainZoomLevelText

                    Spacer()

                    textView(for: ZoomLevel(from: domainZoomLevel.zoomLevel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(UX.textPadding)

                VStack {
                    HStack {
                        Text(domainZoomLevel.host)
                            .alignmentGuide(.leading) { $0[.leading] + UX.textPadding }

                        Spacer()
                    }

                    HStack {
                        Spacer()

                        Text(ZoomLevel(from: domainZoomLevel.zoomLevel).displayName)
                            .alignmentGuide(.trailing) { $0[.trailing] + UX.textPadding }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(UX.textPadding)
            }
            .font(.body)
            .foregroundColor(textColor)
        } else {
            HStack {
                Text(domainZoomLevel.host)

                Spacer()

                textView(for: ZoomLevel(from: domainZoomLevel.zoomLevel))
            }
            .font(.body)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UX.textPadding)
        }
    }

    private var domainZoomLevelText: some View {
        Text(domainZoomLevel.host)
    }

    private func textView(
        for zoomLevel: ZoomLevel
    ) -> some View {
        Text(zoomLevel.displayName)
    }
}
