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

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                getImage(creditCard: item)
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .aspectRatio(contentMode: .fit)
                    .padding(.leading, 16)

                VStack(spacing: 0) {
                    Text(item.ccName)
                        .font(.system(size: 17))
                        .foregroundColor(colors.titleTextColor)
                        .frame(maxWidth: .infinity,
                               alignment: .leading)

                    HStack(spacing: 0) {
                        Text(item.ccType)
                            .font(.system(size: 17))
                            .foregroundColor(colors.titleTextColor)
                        Text(item.ccNumberLast4)
                            .font(.system(size: 17))
                            .foregroundColor(colors.subTextColor)
                            .padding(.leading, 5)
                    }
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
                    .padding(.top, 3)
                    .padding(.bottom, 3)

                    HStack(spacing: 0) {
                        Text("Expires")
                            .font(.system(size: 17))
                            .foregroundColor(colors.subTextColor)
                        Text("\(item.ccExpYear)")
                            .font(.system(size: 17))
                            .foregroundColor(colors.subTextColor)
                    }
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
                }
                .padding(.leading, 24)
                .padding(.trailing, 0)
            }
            .padding(.top, 10)
            .padding(.bottom, 10)

            Rectangle()
                .fill(colors.separatorColor)
                .frame(maxWidth: .infinity)
                .frame(height: 0.7)
                .padding(.leading, 10)
                .padding(.trailing, 10)
        }
        .frame(maxHeight: 86)
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
