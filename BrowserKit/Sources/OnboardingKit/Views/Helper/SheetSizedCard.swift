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
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height

        let calculatedWidth: CGFloat
        if screenWidth > screenHeight {
            calculatedWidth = screenWidth * UX.CardView.landscapeWidthRatio
        } else {
            calculatedWidth = screenWidth * UX.CardView.portraitWidthRatio
        }

        return min(UX.CardView.maxWidth, calculatedWidth)
    }

    private func sheetHeight(for screenSize: CGSize) -> CGFloat {
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height

        if screenWidth > screenHeight {
            return screenHeight * UX.CardView.landscapeHeightRatio
        } else {
            return min(UX.CardView.maxHeight, screenHeight * UX.CardView.portraitHeightRatio)
        }
    }
}
