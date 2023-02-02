// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Storage

struct CreditCardItemRowUX {
    var titleTextColor: Color
    var subTextColor: Color
    var separatorColor: Color
}

struct CreditCardItemRow : View {
    let item: CreditCard
    let ux: CreditCardItemRowUX

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: "creditcard")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .aspectRatio(contentMode: .fit)
                    .padding(.leading, 16)
                
                VStack(spacing: 0) {
                    Text(item.ccName)
                        .font(.system(size: 17))
                        .foregroundColor(ux.titleTextColor)
                        .frame(maxWidth: .infinity,
                               alignment: .leading)

                    HStack(spacing: 0) {
                        Text(item.ccType)
                            .font(.system(size: 17))
                            .foregroundColor(ux.titleTextColor)
                        Text(item.ccNumberLast4)
                            .font(.system(size: 17))
                            .foregroundColor(ux.subTextColor)
                            .padding(.leading, 5)
                    }
                    .frame(maxWidth: .infinity,
                            alignment: .leading)
                    .padding(.top, 2)
                    .padding(.bottom, 2)

                    HStack(spacing: 0) {
                        Text("Expires")
                            .font(.system(size: 17))
                            .foregroundColor(ux.subTextColor)
                        Text("\(item.ccExpYear)")
                            .font(.system(size: 17))
                            .foregroundColor(ux.subTextColor)
                    }
                    .frame(maxWidth: .infinity,
                            alignment: .leading)
                }
                .padding(.leading, 24)
                .padding(.trailing, 0)
//                .padding(.bottom, 5)
            }
            .padding(.top, 10)
            .padding(.bottom, 10)

//            Spacer()
            Rectangle()
                .fill(ux.separatorColor)
                .frame(maxWidth: .infinity)
                .frame(height: 0.7)
                .padding(.leading, 10)
                .padding(.trailing, 10)
        }
        .frame(maxHeight: 86)

//        .frame(maxWidth: .infinity,
//                maxHeight: 86)
//        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
//            return viewDimensions[.listRowSeparatorLeading] - UIScreen.main.bounds.size.width
//        }
    }
}
