// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct AddressBarSelectionView: View {
    let theme: Theme?

    @State var selectedAddressBarPosition: SearchBarPosition = .bottom

    /// Callback executed when a new option is selected.
    var onSelected: ((SearchBarPosition) -> Void)?

    var backgroundColor: Color {
        return Color(theme?.colors.layer2 ?? UIColor.clear)
    }

    private struct UX {
        static let spacing: CGFloat = 36
        static let sectionPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 0.7
    }

    var body: some View {
        HStack(spacing: UX.spacing) {
            ForEach(SearchBarPosition.allCases, id: \.label) { addressBarPosition in
                GenericImageOption(
                    isSelected: selectedAddressBarPosition == addressBarPosition,
                    onSelected: {
                        selectedAddressBarPosition = addressBarPosition
                        onSelected?(selectedAddressBarPosition)
                    },
                    label: addressBarPosition.label,
                    imageName: addressBarPosition.imageName
                )
            }
        }
        .padding(.vertical, UX.sectionPadding)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
    }
}
