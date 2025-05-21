// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct OnboardingSegmentedControl<Action: Equatable & Hashable>: View {
    @State private var actionPrimary: Color = .clear
    @Binding var selection: Action
    let items: [OnboardingMultipleChoiceButtonModel<Action>]
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    init(
        selection: Binding<Action>,
        items: [OnboardingMultipleChoiceButtonModel<Action>],
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self._selection = selection
        self.items = items
        self.windowUUID = windowUUID
        self.themeManager = themeManager
    }

    var body: some View {
        HStack {
            ForEach(items, id: \.action) { item in
                Button {
                    withAnimation(.easeInOut) {
                        selection = item.action
                    }
                } label: {
                    VStack(spacing: UX.SegmentedControl.outerVStackSpacing) {
                        let isSelected = (item.action == selection)

                        Image(assetOrSymbol: item.imageID, bundle: .module)
                            .resizable()
                            .colorMultiply(isSelected ? actionPrimary : .white)
                            .aspectRatio(contentMode: .fit)
                            .frame(height: UX.SegmentedControl.imageHeight)

                        VStack(spacing: UX.SegmentedControl.innerVStackSpacing) {
                            Text(item.title)
                                .font(.footnote)
                                .foregroundColor(.primary)
                            Image(
                                isSelected
                                ? UX.SegmentedControl.radioButtonSelectedImage
                                : UX.SegmentedControl.radioButtonNotSelectedImage,
                                bundle: .module
                            )
                            .font(.system(size: UX.SegmentedControl.checkmarkFontSize))
                        }
                    }
                    .padding(.vertical, UX.SegmentedControl.verticalPadding)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
            guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    private func applyTheme(theme: Theme) {
        actionPrimary = Color(theme.colors.actionPrimary)
    }
}
