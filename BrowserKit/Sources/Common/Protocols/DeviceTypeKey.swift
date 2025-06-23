// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct DeviceTypeKey: EnvironmentKey {
    public static let defaultValue: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
}

public extension EnvironmentValues {
    var deviceType: UIUserInterfaceIdiom {
        get { self[DeviceTypeKey.self] }
        set { self[DeviceTypeKey.self] = newValue }
    }
}
