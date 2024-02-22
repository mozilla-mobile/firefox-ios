// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol UserDefaultsInterface {
    func set(_ value: Any?, forKey defaultName: String)
    func object(forKey defaultName: String) -> Any?

    func set(_ value: Bool, forKey defaultName: String)
    func bool(forKey defaultName: String) -> Bool

    func string(forKey defaultName: String) -> String?
    func float(forKey defaultName: String) -> Float

    func register(defaults registrationDictionary: [String: Any])
    func array(forKey defaultName: String) -> [Any]?

    func removeObject(forKey defaultName: String)
}

extension UserDefaults: UserDefaultsInterface {}
