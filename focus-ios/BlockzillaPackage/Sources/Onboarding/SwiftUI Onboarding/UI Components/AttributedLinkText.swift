// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct AttributedLinkText: View {
    let fullText: String
    let linkText: String
    let url: URL
    let linkAction: (URL) -> Void
    
    @State private var attributedString: AttributedString
    @Environment(\.openURL) private var openURL
    
    init(fullText: String, linkText: String, url: URL, linkAction: @escaping (URL) -> Void) {
        self.fullText = fullText
        self.linkText = linkText
        self.url = url
        self.linkAction = linkAction
        
        var attrString = AttributedString(fullText)
        attrString.foregroundColor = Color(.secondaryLabel)
        
        if let range = attrString.range(of: linkText) {
            attrString[range].foregroundColor = .accent
            attrString[range].link = url
        }
        
        self._attributedString = State(initialValue: attrString)
    }
    
    var body: some View {
        Text(attributedString)
            .accessibilityIdentifier(AccessibilityIdentifiers.AttributedLinkText.view)
            .accessibilityAddTraits([.isStaticText, .isButton])
            .font(.caption)
            .multilineTextAlignment(.center)
            .environment(\.openURL, OpenURLAction { url in
                linkAction(url)
                return .handled
            })
    }
}
