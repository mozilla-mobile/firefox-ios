// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct OnboardingSegmentedControl<Action: Equatable & Hashable>: View {
    @Binding var selection: Action
    let items: [OnboardingMultipleChoiceButtonModel<Action>]

    var body: some View {
        HStack {
            ForEach(items, id: \.action) { item in
                Button {
                    withAnimation(.easeInOut) {
                        selection = item.action
                    }
                } label: {
                    VStack(spacing: 24) {
                        let isSelected = (item.action == selection)
                        let imageName  = isSelected
                            ? "\(item.imageID)Selected"
                            : item.imageID
                        Image(imageName, bundle: .module)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .foregroundColor(isSelected ? .accentColor : .secondary)

                        VStack(spacing: 6) {
                            Text(item.title)
                                .font(.footnote)
                                .foregroundColor(.primary)
                            // checkmark indicator
                            Image(systemName: item.action == selection
                                  ? "checkmark.circle.fill"
                                  : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(item.action == selection
                                             ? .accentColor
                                             : .secondary)
                        }

                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
