// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol UserScriptProvider {
    func getScript(for name: String) -> String?
}

class DefaultUserScriptProvider: UserScriptProvider {
    func getScript(for name: String) -> String? {
        guard let path = Bundle.main.path(forResource: name, ofType: "js"),
              let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
        else { return nil }

        return source
    }
}
