/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct AppFontsView: View {
    var body: some View {
        Form {
            ForEach(AppFont.allCases, id: \.self) { font in
                HStack {
                    Text(font.rawValue)
                        .font(Font(uiFont: font.font))
                }
            }
        }
    }
}

struct AppFontsView_Previews: PreviewProvider {
    static var previews: some View {
        AppFontsView()
    }
}

internal extension Font {
    init(uiFont: UIFont) {
        self = Font(uiFont as CTFont)
    }
}

internal enum AppFont: String, CaseIterable {
    case footnote12
    case footnote12Semibold
    case footnote14
    case footnote14Bold
    case footnote14Medium
    case footnote14Light
    case body15
    case body16
    case body16Medium
    case body16Bold
    case body17
    case body17Medium
    case body18
    case body18Medium
    case title20
    case title20Bold

    var font: UIFont {
        switch self {
        case .footnote12:
            return .footnote12
        case .footnote12Semibold:
            return .footnote12Semibold
        case .footnote14:
            return .footnote14
        case .footnote14Bold:
            return .footnote14Bold
        case .footnote14Medium:
            return .footnote14Medium
        case .footnote14Light:
            return .footnote14Light
        case .body15:
            return .body15
        case .body16:
            return .body16
        case .body16Medium:
            return .body16Medium
        case .body16Bold:
            return .body16Bold
        case .body17:
            return .body17
        case .body17Medium:
            return .body17Medium
        case .body18:
            return .body18
        case .body18Medium:
            return .body18Medium
        case .title20:
            return .title20
        case .title20Bold:
            return .title20Bold
        }
    }
}
