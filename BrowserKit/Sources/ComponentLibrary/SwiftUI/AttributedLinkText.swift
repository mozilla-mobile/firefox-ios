// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct AttributedLinkText<Action: RawRepresentable>: View where Action.RawValue == String {
    let textColor: UIColor
    let linkColor: UIColor
    let fullText: String
    let linkText: String
    let action: Action
    let linkAction: (Action) -> Void
    let textAlignment: TextAlignment
    let accessibilityIdentifier: String?

    public init(
        textColor: UIColor,
        linkColor: UIColor,
        fullText: String,
        linkText: String,
        action: Action,
        textAlignment: TextAlignment = .center,
        accessibilityIdentifier: String? = nil,
        linkAction: @escaping (Action) -> Void
    ) {
        self.textColor = textColor
        self.linkColor = linkColor
        self.fullText = fullText
        self.linkText = linkText
        self.action = action
        self.linkAction = linkAction
        self.textAlignment = textAlignment
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    public var body: some View {
        // Rendered as a Button so the link is a single, reliably hittable accessibility element that is
        // addressable by identifier in UI tests. The link substring keeps its underlined link styling.
        Button {
            linkAction(action)
        } label: {
            Text(attributedString)
                .fixedSize(horizontal: false, vertical: true)
                .font(.caption)
                .multilineTextAlignment(textAlignment)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fullText)
        .accessibilityAddTraits(.isLink)
        .accessibilityIdentifier(accessibilityIdentifier ?? action.rawValue)
    }

    private var attributedString: AttributedString {
        var attrString = AttributedString(fullText)
        attrString.foregroundColor = Color(uiColor: textColor)

        if let range = attrString.range(of: linkText) {
            attrString[range].underlineStyle = .single
            attrString[range].foregroundColor = Color(uiColor: linkColor)
        }

        return attrString
    }
}
