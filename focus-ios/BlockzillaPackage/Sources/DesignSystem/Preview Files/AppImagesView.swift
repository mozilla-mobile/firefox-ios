/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct AppImagesView: View {
    var body: some View {
        Form {
            ForEach(AppImage.allCases, id: \.self) { image in
                HStack {
                    Text(image.rawValue)
                    Spacer()
                    Image(uiImage: image.image)
                        .resizable()
                        .frame(width: 22, height: 22)
                }
            }
        }
    }
}

struct AppImagesView_Previews: PreviewProvider {
    static var previews: some View {
        AppImagesView()
    }
}

enum AppImage: String, CaseIterable {
    case trackingProtectionOff
    case trackingProtectionOn
    case connectionNotSecure
    case connectionSecure
    case defaultFavicon
    case iconClose
    case removeShortcut
    case renameShortcut
    case faceid
    case touchid

    var image: UIImage {
        switch self {
        case .trackingProtectionOff:
            return .trackingProtectionOff
        case .trackingProtectionOn:
            return .trackingProtectionOn
        case .connectionNotSecure:
            return .connectionNotSecure
        case .connectionSecure:
            return .connectionSecure
        case .defaultFavicon:
            return .defaultFavicon
        case .iconClose:
            return .iconClose
        case .removeShortcut:
            return .removeShortcut
        case .renameShortcut:
            return .renameShortcut
        case .faceid:
            return .faceid
        case .touchid:
            return .touchid
        }
    }
}
