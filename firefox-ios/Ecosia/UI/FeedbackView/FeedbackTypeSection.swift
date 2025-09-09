// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct FeedbackTypeSection: View {
    @State private var theme = FeedbackTypeSectionTheme()
    let windowUUID: WindowUUID?
    @Binding var selectedFeedbackType: FeedbackType?
    let updateButtonState: () -> Void

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                ForEach(FeedbackType.allCases) { type in
                    Button(action: {
                        selectedFeedbackType = type
                        updateButtonState()
                    }) {
                        HStack {
                            Text(type.localizedString)
                                .font(.body)
                                .foregroundColor(theme.textPrimaryColor)

                            Spacer()

                            if selectedFeedbackType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.brandPrimaryColor)
                                    .accessibility(label: Text("Selected"))
                            }
                        }
                        .padding(.ecosia.space._m)
                        .background(theme.sectionBackgroundColor)
                    }

                    if type != FeedbackType.allCases.last {
                        Divider()
                            .padding(.leading, .ecosia.space._m)
                    }
                }
            }
            .frame(minHeight: 44 * CGFloat(FeedbackType.allCases.count))
        }
        .background(theme.sectionBackgroundColor)
        .cornerRadius(.ecosia.borderRadius._l)
        .padding(.horizontal, .ecosia.space._m)
        .ecosiaThemed(windowUUID, $theme)
    }
}
