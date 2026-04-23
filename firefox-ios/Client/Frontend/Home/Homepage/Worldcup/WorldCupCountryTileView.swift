// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct WorldCupCountryTileView: View {
    private struct UX {
        static let flagSize = CGSize(width: 60, height: 40)
        static let flagCornerRadius: CGFloat = 4
        static let flagFontSize: CGFloat = 28
        static let codeFontSize: CGFloat = 11
        static let tileWidth: CGFloat = 79
        static let tileHeight: CGFloat = 66
        static let flagToLabelSpacing: CGFloat = 10
    }

    let country: WorldCupCountry
    let isSelected: Bool
    let theme: Theme

    var body: some View {
        VStack(spacing: UX.flagToLabelSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: UX.flagCornerRadius)
                    .fill(Color(theme.colors.layer2))
                    .frame(width: UX.flagSize.width, height: UX.flagSize.height)

                Text(country.flagEmoji)
                    .font(.system(size: UX.flagFontSize))
            }
            .overlay(
                RoundedRectangle(cornerRadius: UX.flagCornerRadius)
                    .stroke(
                        isSelected ? Color(theme.colors.actionPrimary) : Color.clear,
                        lineWidth: 2
                    )
            )

            Text(country.code)
                .font(.system(size: UX.codeFontSize, weight: .semibold))
                .foregroundColor(Color(theme.colors.textPrimary))
                .lineLimit(1)
        }
        .frame(width: UX.tileWidth, height: UX.tileHeight)
    }
}
