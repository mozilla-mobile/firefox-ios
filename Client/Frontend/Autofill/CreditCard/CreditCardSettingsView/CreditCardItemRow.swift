// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Storage
import Shared

struct CreditCardItemRow: View {
    let item: CreditCard
    let isAccessibilityCategory: Bool

    // Theming
    @Environment(\.themeType)
    var themeVal
    @State var titleTextColor: Color = .clear
    @State var subTextColor: Color = .clear
    @State var separatorColor: Color = .clear
    @State var backgroundColor: Color = .clear

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            AdaptiveStack(horizontalAlignment: .leading,
                          verticalAlignment: .center,
                          spacing: isAccessibilityCategory ? 5 : 24,
                          isAccessibilityCategory: isAccessibilityCategory) {
                getImage(creditCard: item)
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .aspectRatio(contentMode: .fit)

                VStack(spacing: 0) {
                    Text(item.ccName)
                        .font(.body)
                        .foregroundColor(titleTextColor)
                        .frame(maxWidth: .infinity,
                               alignment: .leading)

                    AdaptiveStack(horizontalAlignment: .leading,
                                  spacing: isAccessibilityCategory ? 0 : 5,
                                  isAccessibilityCategory: isAccessibilityCategory) {
                        Text(item.ccType)
                            .font(.body)
                            .foregroundColor(titleTextColor)
                        Text(verbatim: "••••\(item.ccNumberLast4)")
                            .font(.subheadline)
                            .foregroundColor(subTextColor)
                    }
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
                    .padding(.top, 3)
                    .padding(.bottom, 3)

                    AdaptiveStack(horizontalAlignment: .leading,
                                  spacing: isAccessibilityCategory ? 0 : 5,
                                  isAccessibilityCategory: isAccessibilityCategory) {
                        Text(String.CreditCard.DisplayCard.ExpiresLabel)
                            .font(.body)
                            .foregroundColor(subTextColor)
                        Text(verbatim: "\(item.ccExpMonth)/\(item.ccExpYear)")
                            .font(.subheadline)
                            .foregroundColor(subTextColor)
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
                .fill(separatorColor)
                .frame(maxWidth: .infinity)
                .frame(height: 0.7)
                .padding(.leading, 10)
                .padding(.trailing, 10)
        }
        .onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { val in
            applyTheme(theme: val.theme)
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

    func applyTheme(theme: Theme) {
        let color = theme.colors
        titleTextColor = Color(color.textPrimary)
        subTextColor = Color(color.textSecondary)
        separatorColor = Color(color.borderPrimary)
        backgroundColor = Color(color.layer5)
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

        CreditCardItemRow(item: creditCard,
                          isAccessibilityCategory: false)

        CreditCardItemRow(item: creditCard,
                          isAccessibilityCategory: true)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large")

        CreditCardItemRow(item: creditCard,
                          isAccessibilityCategory: false)
            .environment(\.sizeCategory, .extraSmall)
            .previewDisplayName("Small")
    }
}
