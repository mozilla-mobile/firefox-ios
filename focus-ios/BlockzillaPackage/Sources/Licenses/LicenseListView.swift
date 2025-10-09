// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
        let focusLicense = LicenseManager.licenseList(for: "focus-ios")
        let libraries = LicenseManager.licenseList(for: "license-list")
        self.libraries = focusLicense + libraries
    }
}

// MARK: - Preview
struct LicenseListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LicenseListView()
        }
    }
}

// MARK: - Private
private enum LicenseManager {
    static func licenseList(for resource: String) -> [Library] {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "plist") else { return [] }
        return (try? decodePropertyList(LicenseList.self, from: url).libraries) ?? []
    }

    private static func decodePropertyList<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        return try decoder.decode(type.self, from: data)
    }
}
