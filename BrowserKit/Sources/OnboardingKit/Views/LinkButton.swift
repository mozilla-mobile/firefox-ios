// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct LinkButton: View {
    let viewModel: OnboardingLinkInfoModel
    let action: () -> Void

    public init(viewModel: OnboardingLinkInfoModel, action: @escaping () -> Void) {
        self.viewModel = viewModel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(viewModel.title)
                .underline()
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibility(identifier: viewModel.title)
    }
}
