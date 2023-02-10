// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Storage

struct CreditCardItemRow: View {
    struct Colors {
        let titleTextColor: Color
        let subTextColor: Color
        let separatorColor: Color
    }

    let item: CreditCard
    let colors: Colors
    let isAccessibilityCategory: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            AdaptiveStack(horizontalAlignment: .leading,
                          verticalAlignment: .center,
                          spacing: isAccessibilityCategory ? 5 : 24,
                          isAccessibilityCategory: isAccessibilityCategory) {
                getImage(creditCard: item)
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .aspectRatio(contentMode: .fit)

                VStack(spacing: 0) {
                    Text(item.ccName)
                        .font(.body)
                        .foregroundColor(colors.titleTextColor)
                        .frame(maxWidth: .infinity,
                               alignment: .leading)

                    AdaptiveStack(horizontalAlignment: .leading,
                                  spacing: isAccessibilityCategory ? 0 : 5,
                                  isAccessibilityCategory: isAccessibilityCategory) {
                        Text(item.ccType)
                            .font(.body)
                            .foregroundColor(colors.titleTextColor)
                        Text(item.ccNumberLast4)
                            .font(.subheadline)
                            .foregroundColor(colors.subTextColor)
                    }
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
                    .padding(.top, 3)
                    .padding(.bottom, 3)

                    AdaptiveStack(horizontalAlignment: .leading,
                                  spacing: isAccessibilityCategory ? 0 : 5,
                                  isAccessibilityCategory: isAccessibilityCategory) {
                        Text("Expires")
                            .font(.body)
                            .foregroundColor(colors.subTextColor)
                        Text(String(item.ccExpYear))
                            .font(.subheadline)
                            .foregroundColor(colors.subTextColor)
                    }
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 11)
            .padding(.bottom, 11)

            Rectangle()
                .fill(colors.separatorColor)
                .frame(maxWidth: .infinity)
                .frame(height: 0.7)
                .padding(.leading, 10)
                .padding(.trailing, 10)
        }
    }

    func getImage(creditCard: CreditCard) -> Image {
        let defaultImage = Image(ImageIdentifiers.creditCardPlaceholder)

        guard let type = CreditCardType(rawValue: creditCard.ccType),
              let image = type.image else {
            return defaultImage
        }

        return Image(uiImage: image)
    }
}

struct CreditCardItemRow_Previews: PreviewProvider {
    static var previews: some View {
        let creditCard = CreditCard(guid: "1",
                                    ccName: "Allen Burges",
                                    ccNumberEnc: "1234567891234567",
                                    ccNumberLast4: "4567",
                                    ccExpMonth: 1234567,
                                    ccExpYear: 2023,
                                    ccType: "VISA",
                                    timeCreated: 1234678,
                                    timeLastUsed: nil,
                                    timeLastModified: 123123,
                                    timesUsed: 123123)
        let colors = CreditCardItemRow.Colors(titleTextColor: .gray,
                                              subTextColor: .gray,
                                              separatorColor: .gray)

        CreditCardItemRow(item: creditCard,
                          colors: colors,
                          isAccessibilityCategory: false)

        CreditCardItemRow(item: creditCard,
                          colors: colors,
                          isAccessibilityCategory: true)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large")

        CreditCardItemRow(item: creditCard,
                          colors: colors,
                          isAccessibilityCategory: false)
            .environment(\.sizeCategory, .extraSmall)
            .previewDisplayName("Small")
    }
}
