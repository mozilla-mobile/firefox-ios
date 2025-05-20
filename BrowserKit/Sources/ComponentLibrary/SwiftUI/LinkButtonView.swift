// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct LinkButtonView: View {
    let viewModel: LinkInfoModel
    let action: () -> Void

    // MARK: – UX Constants
    private enum UX {
        static let verticalPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
    }

    public init(viewModel: LinkInfoModel, action: @escaping () -> Void) {
        self.viewModel = viewModel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(viewModel.title)
                .underline()
                .padding(.vertical, UX.verticalPadding)
                .padding(.horizontal, UX.horizontalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibility(identifier: viewModel.accessibilityIdentifier)
    }
}
