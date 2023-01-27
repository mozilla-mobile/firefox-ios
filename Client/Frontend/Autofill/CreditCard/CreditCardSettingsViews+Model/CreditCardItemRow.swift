// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Storage

struct CreditCardItemRow : View {
    let item: CreditCard

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "creditcard")
                .resizable()
                .frame(width: 40, height: 30)
                .aspectRatio(contentMode: .fit)
            VStack {
                Text(item.ccName)
                    .font(.system(size: 17))
                    .frame(maxWidth: .infinity,
                           alignment: .leading)

                HStack(spacing: 0) {
                    Text(item.ccType)
                        .font(.system(size: 17))
                    Text(item.ccNumberLast4)
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                .frame(maxWidth: .infinity,
                        alignment: .leading)
                .padding(.top, -7)

                HStack {
                    Text("Expires")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                    Text("\(item.ccExpYear)")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity,
                        alignment: .leading)
                .padding(.top, -7)
            }
            .padding(.top, 5)
            .padding(.leading, 24)
            .padding(.trailing, 0)
            .padding(.bottom, 5)
        }
        
//        .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
//            return viewDimensions[.listRowSeparatorLeading] - UIScreen.main.bounds.size.width
//        }
    }
}
