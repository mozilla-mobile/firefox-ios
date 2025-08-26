// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct SheetSizedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                content
                    .frame(
                        width: sheetWidth(for: geometry.size),
                        height: sheetHeight(for: geometry.size)
                    )

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func sheetWidth(for screenSize: CGSize) -> CGFloat {
        let calculatedWidth = screenSize.width > screenSize.height
            ? screenSize.width * UX.CardView.landscapeWidthRatio
            : screenSize.width * UX.CardView.portraitWidthRatio

        return min(UX.CardView.maxWidth, calculatedWidth)
    }

    private func sheetHeight(for screenSize: CGSize) -> CGFloat {
        return screenSize.width > screenSize.height
            ? screenSize.height * UX.CardView.landscapeHeightRatio
            : min(UX.CardView.maxHeight, screenSize.height * UX.CardView.portraitHeightRatio)
    }
}
