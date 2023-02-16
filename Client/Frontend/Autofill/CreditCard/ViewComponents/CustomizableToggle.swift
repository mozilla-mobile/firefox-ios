// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// For SwiftUI 1.0, we resort to giving Toggle a custom ToggleStyle to have certain customization
/// options on it, like colors, text size etc.
struct CustomizableToggle: ToggleStyle {
    struct Colors {
        var enabledColor: Color
        var disabledColor: Color
        var toggleButtonColor: Color
    }

    struct UX {
        var label: String
        var cornerRadius: CGFloat
        var font: Font
    }

    let colors: Colors
    let toggleUX: UX

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
                .hidden()
            HStack {
                Text(toggleUX.label)
                Spacer()
                Button(action: { configuration.isOn.toggle() }) {
                    RoundedRectangle(cornerRadius: 16, style: .circular)
                        .fill(configuration.isOn ? colors.enabledColor : colors.disabledColor)
                        .frame(width: 50, height: 30)
                        .overlay(
                            Circle()
                                .fill(colors.toggleButtonColor)
                                .shadow(radius: 1, x: 0, y: 1)
                                .padding(1.5)
                                .offset(x: configuration.isOn ? 10 : -10))
                        .animation(Animation.easeInOut(duration: 0.1))
                }
            }
            .font(toggleUX.font)
            .padding(.horizontal)
            Divider()
                .frame(height: 0.7)
                .padding(.leading, 16)
        }
        .frame(width: UIScreen.main.bounds.size.width, height: 42)
    }
}

struct CustomizableToggleUIKit: UIViewRepresentable {
    struct Colors {
        var enabledTintColor: UIColor
    }

    struct UX {
        var toggleWidth: CGFloat
        var toggleHeight: CGFloat
    }

    let colors: Colors
    let toggleUX: UX

    func makeUIView(context: Context) -> UISwitch {
        let switchButton = UISwitch(frame: CGRect(
            width: toggleUX.toggleWidth,
            height: toggleUX.toggleHeight)
        )
        switchButton.onTintColor = colors.enabledTintColor
        return switchButton
    }

    func updateUIView(_ uiView: UISwitch, context: Context) {
        // no-op
    }
}
