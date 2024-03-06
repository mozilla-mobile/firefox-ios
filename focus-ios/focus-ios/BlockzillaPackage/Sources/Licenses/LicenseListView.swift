// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI

public struct LicenseListView: View {
    let libraries: [Library]

    public var body: some View {
        List {
            ForEach(libraries, id: \.name) { library in
                NavigationLink {
                    ScrollView {
                        Text(library.licenseBody)
                            .padding()
                    }
                    .navigationBarTitle(library.name)
                } label: {
                    Text(library.name)
                }
            }
        }
    }
}

public extension LicenseListView {
    init() {
        let licenseListURL = Bundle.module.url(forResource: "license-list", withExtension: "plist")!
        let focusURL = Bundle.module.url(forResource: "focus-ios", withExtension: "plist")!

        let focusLicense = (try? decodePropertyList(LicenseList.self, from: focusURL).libraries) ?? []
        let libraries = (try? decodePropertyList(LicenseList.self, from: licenseListURL).libraries) ?? []
        self.libraries = focusLicense + libraries
    }
}

struct LicenseListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LicenseListView()
        }
    }
}

func decodePropertyList<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
    let data = try Data(contentsOf: url)
    let decoder = PropertyListDecoder()
    return try decoder.decode(type.self, from: data)
}
