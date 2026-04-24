// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct WorldCupCountryTileView: View {
    private struct UX {
        static let flagSize = CGSize(width: 60, height: 40)
        static let flagCornerRadius: CGFloat = 4
        static let nameFontSize: CGFloat = 11
        static let tileWidth: CGFloat = 79
        static let tileHeight: CGFloat = 66
        static let flagToLabelSpacing: CGFloat = 10
    }

    let country: WorldCupCountry
    let isSelected: Bool
    let theme: Theme

    var body: some View {
        VStack(spacing: UX.flagToLabelSpacing) {
            Image(country.id.lowercased())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UX.flagSize.width, height: UX.flagSize.height)
                .clipShape(RoundedRectangle(cornerRadius: UX.flagCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: UX.flagCornerRadius)
                        .stroke(
                            isSelected ? Color(theme.colors.actionPrimary) : Color.clear,
                            lineWidth: 2
                        )
                )

            Text(country.name)
                .font(.system(size: UX.nameFontSize, weight: .semibold))
                .foregroundColor(Color(theme.colors.textPrimary))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: UX.tileWidth, height: UX.tileHeight)
    }
}
